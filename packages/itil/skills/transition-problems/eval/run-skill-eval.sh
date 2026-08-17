#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_MD="${SCRIPT_DIR}/../SKILL.md"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../../.." && pwd)"

if [[ "${WR_EVAL_RUNTIME:-claude}" == "codex" ]]; then
  exec codex exec --ephemeral --ignore-user-config --cd "$REPO_ROOT" \
    -c 'approval_policy="never"' --sandbox read-only \
    "Read ${SKILL_MD} and answer the validation prompt using that skill contract.

${1:-}" </dev/null
fi

exec claude -p --append-system-prompt "$(cat "$SKILL_MD")" "${1:-}"
