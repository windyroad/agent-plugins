#!/bin/bash
# PostToolUse hook: soft nudge for accumulated WIP.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/gate-helpers.sh"
_enable_err_trap

_parse_input

TOOL_NAME=$(_get_tool_name)
SESSION_ID=$(_get_session_id)
[ -n "$SESSION_ID" ] || exit 0

case "$TOOL_NAME" in
  Edit|Write) ;;
  *) exit 0 ;;
esac

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
[ -n "$ROOT" ] || exit 0
cd "$ROOT"

STATUS_COUNT=$(git status --short --untracked-files=all 2>/dev/null | wc -l | tr -d ' ')
SHORTSTAT=$(git diff HEAD --shortstat 2>/dev/null || true)
INSERTIONS=$(printf '%s' "$SHORTSTAT" | sed -n 's/.* \([0-9][0-9]*\) insertion.*/\1/p')
DELETIONS=$(printf '%s' "$SHORTSTAT" | sed -n 's/.* \([0-9][0-9]*\) deletion.*/\1/p')
INSERTIONS=${INSERTIONS:-0}
DELETIONS=${DELETIONS:-0}
TOTAL_LINES=$((INSERTIONS + DELETIONS))

# ponytail: fixed early nudge threshold; make project-configurable only after real false positives.
if [ "$STATUS_COUNT" -lt 3 ] && [ "$TOTAL_LINES" -lt 80 ]; then
  exit 0
fi

RDIR=$(_risk_dir "$SESSION_ID")
KEY="${STATUS_COUNT}:${INSERTIONS}:${DELETIONS}"
KEY_FILE="${RDIR}/wip-nudge-key"
if [ -f "$KEY_FILE" ] && [ "$(cat "$KEY_FILE" 2>/dev/null || true)" = "$KEY" ]; then
  exit 0
fi
printf '%s\n' "$KEY" > "$KEY_FILE"

python3 - "$STATUS_COUNT" "$INSERTIONS" "$DELETIONS" <<'PY'
import json
import sys

files, insertions, deletions = sys.argv[1:4]
print(json.dumps({
    "systemMessage": (
        f"Batching risk rising: {files} changed files, +{insertions}/-{deletions} since HEAD. "
        "Keep risk low by committing a coherent slice now; push and release small batches instead of accumulating them."
    )
}))
PY

exit 0
