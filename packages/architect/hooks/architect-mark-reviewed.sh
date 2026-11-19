#!/bin/bash
# Architecture - PostToolUse hook for Agent tool
# Creates a session marker when architect has been consulted.
# Parses verdict from agent output text (session-safe, no temp files).
# This marker unlocks the architect-enforce-edit.sh PreToolUse block.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/gate-helpers.sh"
source "$SCRIPT_DIR/lib/architect-verdict.sh"

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
    # The shared consumer requires one unquoted authoritative heading. Its
    # bounded alias and quote/history rules are identical on both runtimes.
    AGENT_OUTPUT=$(_get_tool_output)
    VERDICT=$(printf '%s\n' "$AGENT_OUTPUT" | architect_verdict)

    # A recognizable verdict and an attributable complete report are separate.
    # Failure here is advisory, never an action denial or architectural FAIL.
    REPORT_RESULT=$(printf '%s' "$_HOOK_INPUT" | python3 "$SCRIPT_DIR/lib/architect-report.py" --hook)
    RECEIPT_ELIGIBLE=$(printf '%s' "$REPORT_RESULT" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("receipt_eligible") is True)' 2>/dev/null)
    printf '%s' "$REPORT_RESULT" | python3 -c '
import json,sys
try: result=json.load(sys.stdin)
except (ValueError, TypeError): result={}
if result.get("completeness") != "complete":
    detail=result.get("diagnostic", "report evaluator unavailable")
    print(json.dumps({"systemMessage": "Architect report completeness: " + str(detail) + ". Mechanical evidence remains advisory; no PASS receipt was created. Substantive review obligations and known findings still apply."}))
'
    if [ "$VERDICT" = "PASS" ] && [ "$RECEIPT_ELIGIBLE" != "True" ]; then
      exit 0
    fi

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
        # Do not mint a PASS receipt for findings or unknown output.
        # Existing advisory handling never waives substantive review duties.
        ;;
    esac

    [ "$VERDICT" = "PASS" ] && touch "/tmp/architect-plan-reviewed-${SESSION_ID}"
    ;;
esac

exit 0
