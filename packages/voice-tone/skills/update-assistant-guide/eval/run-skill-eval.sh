#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPT_PARTS=()
for arg in "$@"; do
  [[ "$arg" = '{"id":'* ]] && break
  PROMPT_PARTS+=("$arg")
done
PROMPT="${PROMPT_PARTS[*]}"
EVAL_DIR="$(mktemp -d)"
trap 'rm -rf -- "$EVAL_DIR"' EXIT
cd "$EVAL_DIR"

if [[ "${WR_EVAL_RUNTIME:-claude}" = "codex" ]]; then
  printf 'Follow these skill instructions exactly:\n\n%s\n\nEvaluation prompt:\n%s\n' \
    "$(cat "${SCRIPT_DIR}/../SKILL.md")" "$PROMPT" \
    | "${CODEX_BINARY:-codex}" exec --ephemeral -c 'approval_policy="never"' --sandbox read-only -
  exit
fi

claude -p --append-system-prompt "$(cat "${SCRIPT_DIR}/../SKILL.md")" "$PROMPT"
