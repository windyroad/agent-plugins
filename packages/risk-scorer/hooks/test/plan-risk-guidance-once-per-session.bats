#!/usr/bin/env bats

# P096 Phase 2: plan-risk-guidance.sh applies once-per-session gating
# (ADR-038 progressive disclosure pattern) so the advisory body emits
# in full only on the first EnterPlanMode of a session. Subsequent
# EnterPlanMode events within the same session emit a terse reminder
# (≤150 bytes payload after the systemMessage prefix).
#
# Reuses the shared session-marker.sh helper synced from
# packages/shared/hooks/lib/session-marker.sh.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  HOOK="$REPO_ROOT/packages/risk-scorer/hooks/plan-risk-guidance.sh"

  WORKDIR="$(mktemp -d)"
  # Minimal RISK-POLICY.md so the appetite extraction has something to read.
  cat > "$WORKDIR/RISK-POLICY.md" <<'POLICY'
# Risk Policy
Threshold: 4
POLICY

  SID="plan-risk-guidance-test-$$-$RANDOM"
}

teardown() {
  rm -f "/tmp/risk-scorer-plan-guidance-announced-${SID}"
  rm -f "/tmp/risk-scorer-plan-guidance-announced-${SID}-alt"
  rm -rf "$WORKDIR"
}

run_hook() {
  local sid="$1"
  (cd "$WORKDIR" && \
    echo "{\"session_id\":\"$sid\",\"tool_name\":\"EnterPlanMode\"}" | \
    bash "$HOOK")
}

@test "plan-risk-guidance: first invocation emits the full RELEASE RISK GUIDANCE body" {
  run run_hook "$SID"
  [ "$status" -eq 0 ]
  [[ "$output" == *"RELEASE RISK GUIDANCE FOR PLANNING"* ]]
  [[ "$output" == *"Release risk:"* ]]
  [[ "$output" == *"Appetite threshold"* ]]
  [[ "$output" == *"release strategy"* ]] || [[ "$output" == *"release queue first"* ]]
}

@test "plan-risk-guidance: first invocation writes the announcement marker" {
  run_hook "$SID" >/dev/null
  [ -f "/tmp/risk-scorer-plan-guidance-announced-${SID}" ]
}

@test "plan-risk-guidance: second invocation in the same session emits a terse reminder" {
  run_hook "$SID" >/dev/null
  run run_hook "$SID"
  [ "$status" -eq 0 ]
  # Terse reminder MUST carry imperative signal word + gate name + cross-ref.
  [[ "$output" == *"MANDATORY"* ]] || [[ "$output" == *"REQUIRED"* ]] || [[ "$output" == *"NON-OPTIONAL"* ]]
  [[ "$output" == *"release-risk gate"* ]] || [[ "$output" == *"risk"* ]]
  # Must NOT re-emit the full prose (release-strategy listing, projected-risk paragraph).
  [[ "$output" != *"RELEASE RISK GUIDANCE FOR PLANNING"* ]]
}

@test "plan-risk-guidance: second invocation reminder payload is ≤300 bytes" {
  run_hook "$SID" >/dev/null
  run run_hook "$SID"
  # Total response is JSON wrapper + systemMessage; reminder body must be
  # short enough that the full response fits well under the ADR-038 budget.
  [ "${#output}" -lt 600 ]
}

@test "plan-risk-guidance: different session_id re-emits the full body" {
  run_hook "$SID" >/dev/null
  local SID2="${SID}-alt"
  run run_hook "$SID2"
  [[ "$output" == *"RELEASE RISK GUIDANCE FOR PLANNING"* ]]
  rm -f "/tmp/risk-scorer-plan-guidance-announced-${SID2}"
}

@test "plan-risk-guidance: empty session_id emits the full body and writes no marker" {
  run run_hook ""
  [[ "$output" == *"RELEASE RISK GUIDANCE FOR PLANNING"* ]]
  # Empty SESSION_ID fallback per shared session-marker contract.
  [ ! -f "/tmp/risk-scorer-plan-guidance-announced-" ]
}

@test "plan-risk-guidance: emits valid JSON with permissionDecision allow on both first and subsequent invocations" {
  run run_hook "$SID"
  [[ "$output" == *'"permissionDecision": "allow"'* ]]
  [[ "$output" == *'"hookEventName": "PreToolUse"'* ]]

  run run_hook "$SID"
  [[ "$output" == *'"permissionDecision": "allow"'* ]]
  [[ "$output" == *'"hookEventName": "PreToolUse"'* ]]
}
