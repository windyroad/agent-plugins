#!/usr/bin/env bash
# Pack and install wr-voice-tone for Codex, then verify the final user-visible response.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
SOURCE_CODEX_HOME="${CODEX_HOME:-${HOME}/.codex}"
CODEX_BIN="${CODEX_BINARY:-}"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

if [[ -z "$CODEX_BIN" ]]; then
  if [[ -x /Applications/ChatGPT.app/Contents/Resources/codex ]]; then
    CODEX_BIN=/Applications/ChatGPT.app/Contents/Resources/codex
  else
    CODEX_BIN="$(command -v codex)"
  fi
fi

export CODEX_HOME="$TMP_ROOT/home"
mkdir -p "$CODEX_HOME" "$TMP_ROOT/pack" "$TMP_ROOT/project/docs"
chmod 700 "$CODEX_HOME"
if [[ -f "$SOURCE_CODEX_HOME/auth.json" ]]; then
  cp "$SOURCE_CODEX_HOME/auth.json" "$CODEX_HOME/auth.json"
  chmod 600 "$CODEX_HOME/auth.json"
fi

npm pack "$REPO_ROOT/packages/voice-tone" --pack-destination "$TMP_ROOT/pack" >/dev/null
NPM_SPEC="$(find "$TMP_ROOT/pack" -maxdepth 1 -type f -name '*.tgz' -print -quit)"
CODEX_BINARY="$CODEX_BIN" npm exec --yes --package "$NPM_SPEC" -- windyroad-voice-tone --runtime codex --scope user >/dev/null

git -C "$TMP_ROOT/project" init -q
printf '%s\n' 'End every assistant response with this exact text: VOICE_GUIDE_APPLIED' > "$TMP_ROOT/project/docs/ASSISTANT-VOICE-AND-TONE.md"
printf '%s\n' 'Answer directly. Do not edit files or run commands.' > "$TMP_ROOT/project/AGENTS.md"

"$CODEX_BIN" exec \
  --ephemeral \
  --cd "$TMP_ROOT/project" \
  -c 'approval_policy="never"' \
  --sandbox read-only \
  --dangerously-bypass-hook-trust \
  --output-last-message "$TMP_ROOT/final.txt" \
  'In one sentence, say that the build passed.' >/dev/null

[[ -s "$TMP_ROOT/final.txt" ]]
grep -Fq 'VOICE_GUIDE_APPLIED' "$TMP_ROOT/final.txt"
printf 'PASS: packed Codex final response is non-empty and applies the assistant guide.\n'
