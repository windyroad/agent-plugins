#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../../.." && pwd)"
SKILLS=(
  "${SCRIPT_DIR}/../SKILL.md"
  "${SCRIPT_DIR}/../../list-stories/SKILL.md"
  "${SCRIPT_DIR}/../../list-story-maps/SKILL.md"
)

SYSTEM_PROMPT=""
for skill in "${SKILLS[@]}"; do
  SYSTEM_PROMPT+=$'\n\n---\n\n'
  SYSTEM_PROMPT+="$(cat "$skill")"
done

if [[ "${WR_EVAL_RUNTIME:-claude}" == "codex" ]]; then
  exec codex exec --ephemeral --ignore-user-config --cd "$REPO_ROOT" \
    -c 'approval_policy="never"' --sandbox read-only \
    "Read these skill contracts and answer the validation prompt from them:
${SKILLS[*]}

${1:-}" </dev/null
fi

exec claude -p --append-system-prompt "$SYSTEM_PROMPT" "${1:-}"
