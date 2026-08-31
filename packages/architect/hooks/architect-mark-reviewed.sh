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
    # (`**Architecture Review: PASS**` / `## Architecture Review: PASS`, and
    # their ISSUES FOUND / NEEDS DIRECTION equivalents).
    # Tolerates optional `> ` blockquote prefix + leading whitespace.
    # Anchored matches prevent P181 narrative false positives. Exactly one
    # canonical verdict on the first nonblank line is required so examples
    # and conflicting output fail closed.
    AGENT_OUTPUT=$(_get_tool_output)
    _architect_verdicts() {
      sed -nE \
        -e 's/^[[:space:]]*>?[[:space:]]*\*\*Architecture Review: (PASS|ISSUES FOUND|NEEDS DIRECTION)\*\*[[:space:]]*$/\1/p' \
        -e 's/^[[:space:]]*>?[[:space:]]*##[[:space:]]+Architecture Review: (PASS|ISSUES FOUND|NEEDS DIRECTION)[[:space:]]*$/\1/p'
    }
    VERDICT=$(printf '%s\n' "$AGENT_OUTPUT" | _architect_verdicts)
    FIRST_VERDICT=$(printf '%s\n' "$AGENT_OUTPUT" | awk 'NF { print; exit }' | _architect_verdicts)
    [ "$FIRST_VERDICT" = "$VERDICT" ] || VERDICT=""
    [ "$VERDICT" = "ISSUES FOUND" ] && VERDICT="FAIL"

    # Substance-aware drift hash + atomic verdict-write (ADR-009 amendment
    # 2026-06-06). The marker + hash file are written as an atomic pair via
    # `_atomic_mark_with_hash` so a PASS never silently fails to persist
    # (closes the "marker doesn't land after PASS" failure mode P353
    # measured as ~12 subagent invocations + 3 BYPASS_RISK_GATE=1 uses
    # per 3-filing session).
    MARKER="/tmp/architect-reviewed-${SESSION_ID}"
    case "$VERDICT" in
      PASS)
        if [ -d "$PROJECT_DIR/docs/decisions" ]; then
          HASH=$(_substance_hash_path "$PROJECT_DIR/docs/decisions")
        else
          HASH="none"
        fi
        if ! _atomic_mark_with_hash "$MARKER" "$HASH"; then
          echo "WARN: architect-mark-reviewed atomic marker-write failed for ${MARKER}" >&2
        fi
        ;;
      FAIL|"")
        # Fail closed: issues and unparseable output do not unlock edits.
        ;;
    esac

    [ "$VERDICT" = "PASS" ] && touch "/tmp/architect-plan-reviewed-${SESSION_ID}"
    ;;
esac

exit 0
