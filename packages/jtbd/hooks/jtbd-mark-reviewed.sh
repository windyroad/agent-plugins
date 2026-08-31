#!/bin/bash
# JTBD - PostToolUse hook for Agent tool
# Creates session markers when jtbd-lead has been consulted with PASS verdict.
# Canonical layout is docs/jtbd/ only (ADR-008, Option 3 chosen 2026-04-20).
# Legacy docs/JOBS_TO_BE_DONE.md is NOT consulted at runtime.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/review-gate.sh"

# P191: anchor the docs/jtbd detection on the project root, not the hook's
# runtime CWD (see jtbd-enforce-edit.sh for the full rationale). If this
# marker-write side false-negatives on docs/jtbd it never stores the marker,
# and the enforce gate then denies the next edit for lack of a marker.
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"

INPUT=$(cat)

SUBAGENT=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // empty') || true
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty') || true
REVIEW_PROMPT=$(echo "$INPUT" | jq -r '.tool_input.prompt // empty') || true
_HOOK_INPUT="$INPUT"
AGENT_OUTPUT=$(_get_tool_output)
PROMPT_FIRST=$(printf '%s\n' "$REVIEW_PROMPT" | awk 'NF { sub(/^[[:space:]]+/, ""); print; exit }')
OUTPUT_FIRST=$(printf '%s\n' "$AGENT_OUTPUT" | awk 'NF { sub(/^[[:space:]]+/, ""); print; exit }')

if [ -z "$SESSION_ID" ]; then
  exit 0
fi

# Canonical JTBD path — directory only (ADR-008 Option 3). If the
# directory doesn't exist the marker is not stored; the gate will
# surface a "run update-guide" recommendation on the next edit.
if [ ! -d "$PROJECT_DIR/docs/jtbd" ]; then
  exit 0
fi
JTBD_PATH="$PROJECT_DIR/docs/jtbd"

case "$SUBAGENT" in
  *jtbd-lead*|*wr-jtbd*)
    # Recommendation mode is bound to this Agent completion, not shared
    # /tmp state. It never authorises a later file edit or plan.
    if printf '%s\n' "$PROMPT_FIRST" | grep -qE '^RECOMMENDATION REVIEW' || \
       printf '%s\n' "$OUTPUT_FIRST" | grep -qE '^>?[[:space:]]*(\*\*)?JTBD Recommendation Review:'; then
      exit 0
    fi

    # Edit reviews require the current inline heading and the subordinate
    # file verdict to agree. Shared /tmp state alone never authorises work.
    HEADING=$(printf '%s\n' "$OUTPUT_FIRST" \
      | sed -nE 's/^[[:space:]]*>?[[:space:]]*\*\*(JTBD Review: (PASS|ISSUES FOUND|JOB UPDATE NEEDED|PERSONA UPDATE NEEDED))\*\*[[:space:]]*$/\1/p' \
      | head -n 1)
    case "$HEADING" in
      "JTBD Review: PASS") INLINE_VERDICT="PASS" ;;
      "JTBD Review: ISSUES FOUND"|"JTBD Review: JOB UPDATE NEEDED"|"JTBD Review: PERSONA UPDATE NEEDED") INLINE_VERDICT="FAIL" ;;
      *) INLINE_VERDICT="" ;;
    esac

    VERDICT_FILE="/tmp/jtbd-verdict"
    VERDICT=""
    if [ -f "$VERDICT_FILE" ]; then
      VERDICT=$(cat "$VERDICT_FILE")
      rm -f "$VERDICT_FILE"
    fi

    case "${INLINE_VERDICT}:${VERDICT}" in
      PASS:PASS)
        touch "/tmp/jtbd-reviewed-${SESSION_ID}"
        store_review_hash "$SESSION_ID" "jtbd" "$JTBD_PATH"
        touch "/tmp/jtbd-plan-reviewed-${SESSION_ID}"
        ;;
      *)
        # Fail closed: issues, missing verdicts, and unparseable verdicts do
        # not authorise edits or plans, nor do mismatched verdict channels.
        ;;
    esac
    ;;
esac

exit 0
