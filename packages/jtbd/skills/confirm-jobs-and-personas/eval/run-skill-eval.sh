#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_MD="$SCRIPT_DIR/../SKILL.md"

[[ -f "$SKILL_MD" ]] || {
  echo "run-skill-eval.sh: SKILL.md not found at $SKILL_MD" >&2
  exit 2
}

exec claude -p --append-system-prompt "$(cat "$SKILL_MD")" "$@"
