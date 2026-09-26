#!/usr/bin/env bash
# Pack each ordinary reviewer, install it into an isolated Codex home, and
# prove a completed native subagent review opens the parent session's edit gate.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
SOURCE_CODEX_HOME="${CODEX_HOME:-${HOME}/.codex}"
CODEX_BIN="${CODEX_BINARY:-$(command -v codex)}"
TMP_ROOT="$(mktemp -d)"

cleanup() { rm -rf "$TMP_ROOT"; }
trap cleanup EXIT

smoke_reviewer() {
  local package="$1" binary="$2" plugin="$3" agent="$4" verdict="$5"
  local marker_prefix="$6" policy_path="$7" target_path="$8" hook_path="$9"
  local home="$TMP_ROOT/$package/home" pack="$TMP_ROOT/$package/pack"
  local fixture="$TMP_ROOT/$package/fixture" extracted="$TMP_ROOT/$package/extracted"
  local tarball version output session marker payload gate_output

  mkdir -p "$home" "$pack" "$fixture/$(dirname "$policy_path")" \
    "$fixture/$(dirname "$target_path")" "$extracted"
  chmod 700 "$home"
  if [[ -f "$SOURCE_CODEX_HOME/auth.json" ]]; then
    cp "$SOURCE_CODEX_HOME/auth.json" "$home/auth.json"
    chmod 600 "$home/auth.json"
  fi

  version="$(jq -r .version "$REPO_ROOT/packages/$package/package.json")"
  npm pack "$REPO_ROOT/packages/$package" --pack-destination "$pack" >/dev/null
  tarball="$(find "$pack" -maxdepth 1 -type f -name '*.tgz' -print -quit)"
  tar -xzf "$tarball" -C "$extracted"
  PATH="$(dirname "$CODEX_BIN"):$PATH" CODEX_HOME="$home" CODEX_BINARY="$CODEX_BIN" \
    npm exec --yes --package "$tarball" -- "$binary" --runtime codex --scope user >/dev/null

  CODEX_HOME="$home" "$CODEX_BIN" plugin list |
    grep -F "$plugin" | grep -F "installed, enabled" | grep -F "$version" >/dev/null
  test -f "$home/agents/${agent//:/-}.toml"

  case "$package" in
    architect) printf '# Decisions\n\nNo decisions recorded.\n' > "$fixture/$policy_path" ;;
    jtbd) printf '# Jobs\n\nDevelopers need safe, reliable delivery checks.\n' > "$fixture/$policy_path" ;;
    style-guide) printf '# Style guide\n\nUse CSS custom properties for colours.\n' > "$fixture/$policy_path" ;;
    voice-tone) printf '# Voice and tone\n\nUse direct, plain English.\n' > "$fixture/$policy_path" ;;
  esac
  printf 'baseline\n' > "$fixture/$target_path"
  git -C "$fixture" init -q
  git -C "$fixture" add .
  git -C "$fixture" -c user.name=test -c user.email=test@example.com commit -qm initial

  output="$(CODEX_HOME="$home" TMPDIR="$TMP_ROOT/$package/tmp" "$CODEX_BIN" exec --json \
    --cd "$fixture" -c 'approval_policy="never"' --sandbox read-only \
    --dangerously-bypass-hook-trust \
    "Spawn the exact custom agent ${agent} with fork_turns=\"none\" to review this PRE-EDIT proposal: make a harmless change to ${target_path} that follows ${policy_path}. Wait for that reviewer to finish, then invoke interrupt_agent exactly once with that completed target. Return the reviewer's verdict verbatim. Do not perform the review yourself and do not inspect transcripts.")"
  session="$(printf '%s\n' "$output" | jq -r 'select(.type=="thread.started") | .thread_id' | head -1)"
  [[ -n "$session" ]]
  printf '%s\n' "$output" | jq -er --arg verdict "$verdict" \
    'select(.type=="item.completed" and .item.type=="agent_message") | .item.text | select(contains($verdict))' >/dev/null

  marker="/tmp/${marker_prefix}-${session}"
  test -f "$marker"
  test -f "$marker.hash"

  payload="$(jq -cn --arg session "$session" --arg path "$fixture/$target_path" \
    '{session_id:$session,tool_name:"Edit",tool_input:{file_path:$path}}')"
  gate_output="$(cd "$fixture" && CLAUDE_PROJECT_DIR="$fixture" \
    bash -c 'printf "%s" "$1" | bash "$2"' _ "$payload" "$extracted/package/$hook_path")"
  [[ -z "$gate_output" ]]
  printf 'PASS: %s@%s background completion opened the parent edit gate.\n' "$plugin" "$version"
}

mkdir -p "$TMP_ROOT/architect/tmp" "$TMP_ROOT/jtbd/tmp" \
  "$TMP_ROOT/style-guide/tmp" "$TMP_ROOT/voice-tone/tmp"

smoke_reviewer architect windyroad-architect \
  'wr-architect@windyroad-architect-local' 'wr-architect:agent' \
  'Architecture Review: PASS' architect-reviewed \
  'docs/decisions/README.md' 'src/example.ts' 'hooks/architect-enforce-edit.sh'

smoke_reviewer jtbd windyroad-jtbd \
  'wr-jtbd@windyroad-jtbd-local' 'wr-jtbd:agent' \
  'JTBD Review: PASS' jtbd-reviewed \
  'docs/jtbd/README.md' 'src/example.ts' 'hooks/jtbd-enforce-edit.sh'

smoke_reviewer style-guide windyroad-style-guide \
  'wr-style-guide@windyroad-style-guide-local' 'wr-style-guide:agent' \
  'Style Guide Review: PASS' style-guide-reviewed \
  'docs/STYLE-GUIDE.md' 'src/example.css' 'hooks/style-guide-enforce-edit.sh'

smoke_reviewer voice-tone windyroad-voice-tone \
  'wr-voice-tone@windyroad-voice-tone-local' 'wr-voice-tone:agent' \
  'Voice & Tone Review: PASS' voice-tone-reviewed \
  'docs/VOICE-AND-TONE.md' 'src/example.tsx' 'hooks/voice-tone-enforce-edit.sh'
