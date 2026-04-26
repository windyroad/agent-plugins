#!/bin/bash
# PreToolUse hook: Fires on EnterPlanMode to inject release risk context.
# Provides preemptive guidance so the plan author knows the unreleased queue
# state and release risk before writing the plan.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/gate-helpers.sh"
source "$SCRIPT_DIR/lib/session-marker.sh"
_enable_err_trap

_parse_input

SESSION_ID=$(_get_session_id)

# --- Gather pipeline state summary ---
UNRELEASED_SUMMARY=""
if [ -x "$SCRIPT_DIR/lib/pipeline-state.sh" ]; then
  UNRELEASED_SUMMARY=$("$SCRIPT_DIR/lib/pipeline-state.sh" --unreleased 2>/dev/null | head -20 || echo "Unable to determine unreleased changes.")
fi

# --- Check for existing release risk score ---
RELEASE_SCORE="not yet scored"
RDIR=$(_risk_dir "$SESSION_ID")
RELEASE_SCORE_FILE="${RDIR}/release"
if [ -n "$SESSION_ID" ] && [ -f "$RELEASE_SCORE_FILE" ]; then
  SCORE_VAL=$(cat "$RELEASE_SCORE_FILE" 2>/dev/null || echo "")
  if [[ "$SCORE_VAL" =~ ^[0-9]+$ ]]; then
    RELEASE_SCORE="${SCORE_VAL}/25"
  fi
fi

# --- Read appetite from RISK-POLICY.md ---
APPETITE="5"
if [ -f "RISK-POLICY.md" ]; then
  EXTRACTED=$(grep -oP 'Threshold:\s*\K[0-9]+' RISK-POLICY.md 2>/dev/null | head -1 || echo "")
  if [ -n "$EXTRACTED" ]; then
    APPETITE="$EXTRACTED"
  fi
fi

# --- P096 Phase 2 — once-per-session gating (ADR-038 progressive disclosure) ---
# First EnterPlanMode of a session emits the full advisory body; subsequent
# entries within the same session emit a terse reminder (≤150 bytes per the
# ADR-038 budget). Pipeline state and appetite are unchanged across plan-mode
# entries within one session, so re-emitting full prose is repetition.
if has_announced "risk-scorer-plan-guidance" "$SESSION_ID"; then
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "systemMessage": "MANDATORY release-risk gate active (RISK-POLICY.md present). Release risk: ${RELEASE_SCORE}; appetite: ${APPETITE}. ExitPlanMode will FAIL plans projected above appetite. See first-EnterPlanMode emission for full guidance."
  }
}
EOF
  exit 0
fi

# --- First emission: full advisory (compressed per audit recommendation) ---
mark_announced "risk-scorer-plan-guidance" "$SESSION_ID"
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "systemMessage": "RELEASE RISK GUIDANCE FOR PLANNING:\nUnreleased queue:\n${UNRELEASED_SUMMARY}\n\nRelease risk: ${RELEASE_SCORE}. Appetite threshold: ${APPETITE} (Medium).\n\nIf projected release risk would exceed appetite, the plan MUST include a release strategy (release queue first, split into smaller batches, or risk-reducing steps). See RISK-POLICY.md for option details. ExitPlanMode runs the risk-scorer and FAILS plans above appetite without a strategy."
  }
}
EOF
exit 0
