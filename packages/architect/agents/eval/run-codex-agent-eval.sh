#!/usr/bin/env bash
# Codex promptfoo exec-provider driver for the generated wr-architect agent.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
PROMPT="${*:-}"
AGENT_NAME="wr-architect:agent"

if [[ "$PROMPT" == "[COG_A11Y]"* ]]; then
  AGENT_NAME="wr-architect-cog-a11y"
  PROMPT="${PROMPT#\[COG_A11Y\]}"
fi

if [[ -z "$PROMPT" ]]; then
  echo "run-codex-agent-eval.sh: prompt argument is required" >&2
  exit 2
fi

SOURCE_CODEX_HOME="${CODEX_HOME:-${HOME}/.codex}"
TMP_CODEX_HOME=""
TMP_PACK_DIR="$(mktemp -d)"
TMP_REPO="$(mktemp -d)"

cleanup() {
  [[ -z "$TMP_CODEX_HOME" ]] || rm -rf "$TMP_CODEX_HOME"
  rm -rf "$TMP_PACK_DIR" "$TMP_REPO"
}
trap cleanup EXIT

if [[ -n "${WR_CODEX_EVAL_CODEX_HOME:-}" ]]; then
  export CODEX_HOME="$WR_CODEX_EVAL_CODEX_HOME"
  mkdir -p "$CODEX_HOME"
else
  TMP_CODEX_HOME="$(mktemp -d)"
  chmod 700 "$TMP_CODEX_HOME"
  export CODEX_HOME="$TMP_CODEX_HOME"
  if [[ -f "${SOURCE_CODEX_HOME}/auth.json" ]]; then
    cp "${SOURCE_CODEX_HOME}/auth.json" "$CODEX_HOME/auth.json"
    chmod 600 "$CODEX_HOME/auth.json"
  fi
  if [[ "${WR_CODEX_EVAL_COPY_CONFIG:-0}" == "1" && -f "${SOURCE_CODEX_HOME}/config.toml" ]]; then
    cp "${SOURCE_CODEX_HOME}/config.toml" "$CODEX_HOME/config.toml"
    chmod 600 "$CODEX_HOME/config.toml"
  fi
fi

npm pack "$REPO_ROOT/packages/architect" --pack-destination "$TMP_PACK_DIR" >/dev/null
NPM_SPEC="$(find "$TMP_PACK_DIR" -maxdepth 1 -type f -name '*.tgz' -print -quit)"
CODEX_BINARY="${CODEX_BINARY:-$(command -v codex)}" npm exec --yes --package "$NPM_SPEC" -- windyroad-architect --runtime codex --scope user >/dev/null
test -f "$CODEX_HOME/agents/wr-architect-agent.toml"
test -f "$CODEX_HOME/agents/wr-architect-cog-a11y.toml"
cp -R "$SCRIPT_DIR/fixtures/repo/." "$TMP_REPO/"
git -C "$TMP_REPO" init --quiet

OUTPUT="$(codex exec \
  --ephemeral \
  --cd "$TMP_REPO" \
  -c 'approval_policy="never"' \
  --sandbox read-only \
  --dangerously-bypass-hook-trust \
  "Spawn the installed custom collaborator agent named ${AGENT_NAME}. Wait for it and close that same agent. Do not substitute another agent or perform the review inline. Return the collaborator's final output verbatim without adding a verdict label or summary.

${PROMPT}" </dev/null)"

[[ ! -e "$TMP_REPO/forbidden.txt" ]] || {
  echo "run-codex-agent-eval.sh: reviewer changed the read-only fixture" >&2
  exit 3
}

printf '%s\n' "$OUTPUT"
