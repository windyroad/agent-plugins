#!/bin/bash
# JTBD - PostToolUse hook for Agent tool
# Creates session markers when jtbd-lead has been consulted with PASS verdict.
# Supports both docs/jtbd/ directory (preferred) and docs/JOBS_TO_BE_DONE.md (legacy).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/review-gate.sh"

INPUT=$(cat)

SUBAGENT=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // empty') || true
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty') || true

if [ -z "$SESSION_ID" ]; then
  exit 0
fi

# Determine JTBD path — prefer directory, fall back to single file
JTBD_PATH="docs/JOBS_TO_BE_DONE.md"
if [ -d "docs/jtbd" ]; then
  JTBD_PATH="docs/jtbd"
fi

case "$SUBAGENT" in
  *jtbd-lead*|*wr-jtbd*)
    # Check for edit review verdict
    VERDICT_FILE="/tmp/jtbd-verdict"
    VERDICT=""
    if [ -f "$VERDICT_FILE" ]; then
      VERDICT=$(cat "$VERDICT_FILE")
      rm -f "$VERDICT_FILE"
    fi

    case "$VERDICT" in
      PASS)
        touch "/tmp/jtbd-reviewed-${SESSION_ID}"
        store_review_hash "$SESSION_ID" "jtbd" "$JTBD_PATH"
        ;;
      FAIL)
        # Do NOT create marker — review found issues
        ;;
      *)
        # No verdict file — backward compat, allow with marker
        touch "/tmp/jtbd-reviewed-${SESSION_ID}"
        store_review_hash "$SESSION_ID" "jtbd" "$JTBD_PATH"
        ;;
    esac

    # Plan review: agent completion = reviewed.
    touch "/tmp/jtbd-plan-reviewed-${SESSION_ID}"
    ;;
esac

exit 0
