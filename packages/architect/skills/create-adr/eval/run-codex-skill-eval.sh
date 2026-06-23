#!/usr/bin/env bash
# Codex promptfoo exec-provider driver for the create-adr SKILL eval.
# Installs the repo-local Codex marketplace into an isolated CODEX_HOME, then
# exercises the installed wr-architect plugin through `codex exec`.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../../.." && pwd)"
MARKETPLACE_DIR="$REPO_ROOT"
PROMPT="${*:-}"

if [[ -z "$PROMPT" ]]; then
  echo "run-codex-skill-eval.sh: prompt argument is required" >&2
  exit 2
fi

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

codex plugin marketplace add "$MARKETPLACE_DIR" >/dev/null
codex plugin add wr-architect@windyroad-local >/dev/null

exec codex exec \
  --ephemeral \
  --cd "$REPO_ROOT" \
  -c 'approval_policy="never"' \
  --sandbox read-only \
  --dangerously-bypass-hook-trust \
  "Invoke the installed wr-architect create-adr skill for this validation prompt. Use the plugin-provided skill instructions, not ad hoc ADR drafting rules.

${PROMPT}"
