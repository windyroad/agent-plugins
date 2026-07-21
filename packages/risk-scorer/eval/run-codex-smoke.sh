#!/usr/bin/env bash
# Install published wr-risk-scorer for Codex in an isolated CODEX_HOME and run
# two smoke prompts through codex exec.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
SOURCE_CODEX_HOME="${CODEX_HOME:-${HOME}/.codex}"
TMP_CODEX_HOME=""

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
  trap 'rm -rf "$TMP_CODEX_HOME"' EXIT
fi

NPM_SPEC="${WR_RISK_SCORER_NPM_SPEC:-@windyroad/risk-scorer@latest}"
npm exec --yes --package "$NPM_SPEC" -- windyroad-risk-scorer --runtime codex >/dev/null

run_codex() {
  codex exec \
    --ephemeral \
    --cd "$REPO_ROOT" \
    -c 'approval_policy="never"' \
    --sandbox read-only \
    --dangerously-bypass-hook-trust \
    "$1"
}

run_codex "Invoke the installed wr-risk-scorer assess-release skill for an explicit smoke check of the current repository state. Do not modify files."

run_codex "Invoke the installed wr-risk-scorer assess-external-comms skill for this draft.

Surface: changeset-author
Destination: npm public registry
Draft: Collapse risk-scorer hooks through a dispatcher and add Codex runtime packaging."
