#!/bin/bash
# Architecture - PostToolUse hook for Agent tool
# Creates a session marker when architect has been consulted.
# Parses verdict from agent output text (session-safe, no temp files).
# This marker unlocks the architect-enforce-edit.sh PreToolUse block.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/gate-helpers.sh"

# P191 Phase 2: anchor docs/decisions on the project root, not the hook's
# runtime CWD (see architect-enforce-edit.sh). A false-negative here never
# stores the marker hash, desynchronising the enforce gate's drift check.
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"

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
    # Parse verdict from agent output text (no temp file needed).
    # Anchored to the canonical heading shape from
    # packages/architect/agents/agent.md "How to Report"
    # (`**Architecture Review: PASS**` / `**Architecture Review: ISSUES FOUND**`).
    # Tolerates optional `> ` blockquote prefix + leading whitespace.
    # Anchored match (not substring) prevents P181 false-positive FAIL when
    # body prose narratively references the ISSUES FOUND verdict.
    AGENT_OUTPUT=$(_get_tool_output)
    VERDICT=""
    if echo "$AGENT_OUTPUT" | grep -qE '^[[:space:]]*>?[[:space:]]*\*\*Architecture Review: PASS\*\*'; then
      VERDICT="PASS"
    elif echo "$AGENT_OUTPUT" | grep -qE '^[[:space:]]*>?[[:space:]]*\*\*Architecture Review: ISSUES FOUND\*\*'; then
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
      if [ -d "$PROJECT_DIR/docs/decisions" ]; then
        HASH=$(find "$PROJECT_DIR/docs/decisions" -name '*.md' -not -name 'README.md' -print0 | sort -z | xargs -0 cat 2>/dev/null | _hashcmd | cut -d' ' -f1)
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
