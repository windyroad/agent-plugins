#!/bin/bash
# Architecture - PostToolUse hook for Agent tool
# Creates a session marker when architect has been consulted.
# Parses verdict from agent output text (session-safe, no temp files).
# This marker unlocks the architect-enforce-edit.sh PreToolUse block.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/gate-helpers.sh"

_parse_input

TOOL_NAME=$(_get_tool_name)
[ "$TOOL_NAME" = "Agent" ] || exit 0

SUBAGENT=$(_get_subagent_type)
SESSION_ID=$(_get_session_id)

if [ -z "$SESSION_ID" ]; then
  exit 0
fi

case "$SUBAGENT" in
  *architect*)
    # Parse verdict from agent output text (no temp file needed)
    AGENT_OUTPUT=$(_get_tool_output)
    VERDICT=""
    if echo "$AGENT_OUTPUT" | grep -q "Architecture Review: PASS"; then
      VERDICT="PASS"
    elif echo "$AGENT_OUTPUT" | grep -q "ISSUES FOUND"; then
      VERDICT="FAIL"
    fi

    case "$VERDICT" in
      PASS)
        touch "/tmp/architect-reviewed-${SESSION_ID}"
        ;;
      FAIL)
        # Do NOT create marker — review found issues
        ;;
      *)
        # Could not parse verdict — allow with marker to avoid lockout
        touch "/tmp/architect-reviewed-${SESSION_ID}"
        ;;
    esac

    # Store decision hash for drift detection
    if [ -f "/tmp/architect-reviewed-${SESSION_ID}" ]; then
      if [ -d "docs/decisions" ]; then
        HASH=$(find docs/decisions -name '*.md' -not -name 'README.md' -print0 | sort -z | xargs -0 cat 2>/dev/null | _hashcmd | cut -d' ' -f1)
      else
        HASH="none"
      fi
      echo "$HASH" > "/tmp/architect-reviewed-${SESSION_ID}.hash"
    fi

    # Plan review marker
    touch "/tmp/architect-plan-reviewed-${SESSION_ID}"
    ;;
esac

exit 0
