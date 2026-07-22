#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPT_PARTS=()
for arg in "$@"; do
  [[ "$arg" = '{"id":'* ]] && break
  PROMPT_PARTS+=("$arg")
done
PROMPT="${PROMPT_PARTS[*]}"

if [[ "${WR_EVAL_RUNTIME:-claude}" = "codex" ]]; then
  CODEX_PROMPT="Follow these skill instructions exactly:\n\n$(cat "${SCRIPT_DIR}/../SKILL.md")\n\nEvaluation prompt:\n$PROMPT"
  CODEX_PROMPT="$(python3 -c 'import sys; print(sys.stdin.read().translate(str.maketrans({"§":"section ","—":"--","→":"->","≤":"<=","≥":">="})), end="")' <<< "$CODEX_PROMPT")"
  exec codex exec --ephemeral -c 'approval_policy="never"' --sandbox read-only - <<< "$CODEX_PROMPT"
fi

exec claude -p --append-system-prompt "$(cat "${SCRIPT_DIR}/../SKILL.md")" "$PROMPT"
