#!/bin/bash
# Style Guide - PostToolUse hook for Agent tool
# Creates a session marker when style-guide-lead has been consulted with PASS verdict.
# This marker unlocks the style-guide-enforce-edit.sh PreToolUse block.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/review-gate.sh"

_parse_input

[ "$(_get_tool_name)" = "Agent" ] || exit 0
SUBAGENT=$(_get_subagent_type)
SESSION_ID=$(_get_session_id)

if [ -z "$SESSION_ID" ]; then
  exit 0
fi

case "$SUBAGENT" in
  *style-guide-lead*|*wr-style-guide*)
    HEADING=$(printf '%s\n' "$(_get_tool_output)" \
      | sed -nE 's/^[[:space:]]*>?[[:space:]]*\*\*(Style Guide Review: (PASS|VIOLATIONS FOUND|GUIDE UPDATE NEEDED))\*\*.*/\1/p' \
      | head -n 1)

    case "$HEADING" in
      "Style Guide Review: PASS")
        touch "/tmp/style-guide-reviewed-${SESSION_ID}"
        store_review_hash "$SESSION_ID" "style-guide" "docs/STYLE-GUIDE.md"
        touch "/tmp/style-guide-plan-reviewed-${SESSION_ID}"
        ;;
      *)
        # Fail closed: issues and unparseable output do not unlock edits.
        ;;
    esac
    ;;
esac

exit 0
