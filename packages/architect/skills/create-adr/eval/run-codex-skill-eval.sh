#!/usr/bin/env bash
# Codex promptfoo exec-provider driver for the create-adr SKILL eval.
# Installs the repo-local Codex marketplace into an isolated CODEX_HOME, then
# exercises the installed wr-architect plugin through `codex exec`.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../../.." && pwd)"
PROMPT="${*:-}"

if [[ -z "$PROMPT" ]]; then
  echo "run-codex-skill-eval.sh: prompt argument is required" >&2
  exit 2
fi

SOURCE_CODEX_HOME="${CODEX_HOME:-${HOME}/.codex}"
TMP_CODEX_HOME=""
TMP_PACK_DIR="$(mktemp -d)"

cleanup() {
  [[ -z "$TMP_CODEX_HOME" ]] || rm -rf "$TMP_CODEX_HOME"
  rm -rf "$TMP_PACK_DIR"
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

codex exec \
  --ephemeral \
  --cd "$REPO_ROOT" \
  -c 'approval_policy="never"' \
  --sandbox read-only \
  --dangerously-bypass-hook-trust \
  "Invoke the installed wr-architect create-adr skill for this validation prompt. Use the plugin-provided skill instructions, not ad hoc ADR drafting rules.

${PROMPT}" </dev/null
