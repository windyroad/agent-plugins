#!/bin/bash
# Shared gate logic for risk scoring enforcement hooks.
# Sourced by risk-score-commit-gate.sh, git-push-gate.sh, risk-score-plan-enforce.sh.
# Provides: check_risk_gate, risk_gate_deny

# Source shared portable helpers (_mtime, _hashcmd)
_RISK_GATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_RISK_GATE_DIR/gate-helpers.sh"

# Check risk gate for a given action. Returns 0 if allowed, 1 if denied.
# Sets RISK_GATE_REASON on failure with human-readable message.
# Usage: check_risk_gate "$SESSION_ID" "commit"
check_risk_gate() {
  local SESSION_ID="$1"
  local ACTION="$2"
  local RDIR
  RDIR=$(_risk_dir "$SESSION_ID")
  local SCORE_FILE="${RDIR}/${ACTION}"
  local HASH_FILE="${RDIR}/state-hash"
  local TTL_SECONDS="${RISK_TTL:-3600}"

  # 1. Score file must exist (fail-closed)
  if [ ! -f "$SCORE_FILE" ]; then
    RISK_GATE_REASON="No ${ACTION} risk score found. Delegate to wr-risk-scorer:pipeline (subagent_type: 'wr-risk-scorer:pipeline') to assess cumulative pipeline risk."
    return 1
  fi

  # 2. TTL check — score file mtime must be within TTL
  local NOW=$(date +%s)
  local SCORE_TIME=$(_mtime "$SCORE_FILE")
  local AGE=$(( NOW - SCORE_TIME ))
  if [ "$AGE" -ge "$TTL_SECONDS" ]; then
    RISK_GATE_REASON="Risk score expired (${AGE}s old, TTL ${TTL_SECONDS}s). Delegate to wr-risk-scorer:pipeline (subagent_type: 'wr-risk-scorer:pipeline') to rescore."
    return 1
  fi

  # 3. Drift detection — pipeline state hash must match
  # The hash is computed from git diff HEAD --stat at prompt submit time.
  # If you staged files AFTER the prompt, the hash will differ.
  # Fix: stage everything BEFORE submitting the prompt, then commit in the response.
  if [ -f "$HASH_FILE" ]; then
    local STORED_HASH=$(cat "$HASH_FILE")
    local CURRENT_HASH
    CURRENT_HASH=$("$_RISK_GATE_DIR/pipeline-state.sh" --hash-inputs 2>/dev/null | _hashcmd | cut -d' ' -f1)
    if [ "$STORED_HASH" != "$CURRENT_HASH" ]; then
      RISK_GATE_REASON="Pipeline state drift: working tree changed since the last ${ACTION} risk assessment. Delegate to wr-risk-scorer:pipeline (subagent_type: 'wr-risk-scorer:pipeline') to rescore against the current state."
      return 1
    fi
  fi
  # No hash file = backward compat, skip drift check

  # 4. Read and validate score
  local SCORE=$(cat "$SCORE_FILE" 2>/dev/null || echo "")
  if ! echo "$SCORE" | grep -qE '^[0-9]+(\.[0-9]+)?$'; then
    RISK_GATE_REASON="Risk score file contains an invalid value. Re-run the risk-scorer agent."
    return 1
  fi

  # 5. Threshold check
  local DENIED=$(python3 -c "
score = float('$SCORE')
print('yes' if score >= 5 else 'no')
" 2>/dev/null || echo "no")

  if [ "$DENIED" = "yes" ]; then
    RISK_GATE_REASON="${ACTION} risk score ${SCORE}/25 (Medium or above). To proceed: (1) split the ${ACTION}, (2) add risk-reducing measures, or (3) for a LIVE INCIDENT, delegate to wr-risk-scorer:pipeline (subagent_type: 'wr-risk-scorer:pipeline') with incident context for an incident bypass."
    return 1
  fi

  return 0
}

# Emit fail-closed deny JSON for PreToolUse hooks.
risk_gate_deny() {
  local REASON="$1"
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "$REASON"
  }
}
EOF
}
