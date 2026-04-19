#!/bin/bash
# JTBD - PostToolUse hook for Agent tool
# Creates session markers when jtbd-lead has been consulted with PASS verdict.
# Canonical layout is docs/jtbd/ only (ADR-008, Option 3 chosen 2026-04-20).
# Legacy docs/JOBS_TO_BE_DONE.md is NOT consulted at runtime.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/review-gate.sh"

INPUT=$(cat)

SUBAGENT=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // empty') || true
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty') || true

if [ -z "$SESSION_ID" ]; then
  exit 0
fi

# Canonical JTBD path — directory only (ADR-008 Option 3). If the
# directory doesn't exist the marker is not stored; the gate will
# surface a "run update-guide" recommendation on the next edit.
if [ ! -d "docs/jtbd" ]; then
  exit 0
fi
JTBD_PATH="docs/jtbd"

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
