#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../../.." && pwd)"
PROMPT="${*:-}"

[[ -n "$PROMPT" ]] || { echo "run-codex-skill-eval.sh: prompt argument is required" >&2; exit 2; }

SOURCE_CODEX_HOME="${CODEX_HOME:-${HOME}/.codex}"
TMP_CODEX_HOME="$(mktemp -d)"
TMP_PACK_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_CODEX_HOME" "$TMP_PACK_DIR"' EXIT

export CODEX_HOME="$TMP_CODEX_HOME"
if [[ -f "${SOURCE_CODEX_HOME}/auth.json" ]]; then
  cp "${SOURCE_CODEX_HOME}/auth.json" "$CODEX_HOME/auth.json"
  chmod 600 "$CODEX_HOME/auth.json"
fi

npm pack "$REPO_ROOT/packages/architect" --pack-destination "$TMP_PACK_DIR" >/dev/null
NPM_SPEC="$(find "$TMP_PACK_DIR" -maxdepth 1 -type f -name '*.tgz' -print -quit)"
CODEX_BINARY="${CODEX_BINARY:-$(command -v codex)}" npm exec --yes --package "$NPM_SPEC" -- windyroad-architect --runtime codex --scope user >/dev/null

codex exec --ephemeral --cd "$REPO_ROOT" --sandbox read-only -c 'approval_policy="never"' \
  "Invoke the installed wr-architect review-decisions skill for this validation prompt. Answer what the workflow must do without mutating files. Do not grade the scenario or prefix the answer with PASS or FAIL.

${PROMPT}" </dev/null
