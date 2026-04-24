#!/usr/bin/env bats

# P085: itil-assistant-output-gate.sh UserPromptSubmit hook must detect
# when the user's incoming prompt pins a direction / confirms a prior
# ask / issues an act-verb, and inject a once-per-session MANDATORY
# reminder instructing the assistant to act without asking — or use
# AskUserQuestion for genuine ambiguity — and NEVER prose-ask.
#
# Per ADR-038: full block emits once per session; subsequent prompts
# emit a terse reminder (<250 bytes) that keeps the MANDATORY signal,
# the gate name, and the AskUserQuestion affordance.
#
# Per feedback_behavioural_tests.md (P081): these are behavioural
# assertions — they simulate the hook's payload on stdin and assert
# on what the hook emits, not on the source text of the hook file.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  HOOK="$REPO_ROOT/packages/itil/hooks/itil-assistant-output-gate.sh"
  SID="itil-gate-test-$$-$RANDOM"
}

teardown() {
  rm -f "/tmp/itil-assistant-gate-announced-${SID}"
  rm -f "/tmp/itil-assistant-gate-announced-${SID}-alt"
}

run_hook() {
  local sid="$1"
  local prompt="$2"
  echo "{\"session_id\":\"$sid\",\"prompt\":$(printf '%s' "$prompt" | jq -Rs .)}" | bash "$HOOK"
}

@test "gate: emits full MANDATORY block on first direction-pin prompt" {
  run run_hook "$SID" "yes, update P084 and verify the subagent tools thing"
  [ "$status" -eq 0 ]
  [ "${#output}" -gt 400 ]
  [[ "$output" == *"MANDATORY"* ]]
  [[ "$output" == *"AskUserQuestion"* ]]
  [[ "$output" == *"obvious"* ]] || [[ "$output" == *"act"* ]]
}

@test "gate: writes the announcement marker on first emission" {
  run run_hook "$SID" "go ahead and do it"
  [ "$status" -eq 0 ]
  [ -f "/tmp/itil-assistant-gate-announced-${SID}" ]
}

@test "gate: second direction-pin prompt in same session emits terse reminder only" {
  run_hook "$SID" "yes, please proceed" >/dev/null
  # Second prompt also pins direction (required for the gate to fire).
  run run_hook "$SID" "yes, go ahead"
  [ "$status" -eq 0 ]
  [ "${#output}" -lt 250 ]
  [[ "$output" == *"AskUserQuestion"* ]]
  # Full block is NOT re-emitted
  [[ "$output" != *"Canonical prose-ask phrasings"* ]]
}

@test "gate: terse reminder preserves MANDATORY / REQUIRED signal word" {
  run_hook "$SID" "yes" >/dev/null
  run run_hook "$SID" "act on this"
  [ "$status" -eq 0 ]
  [[ "$output" == *"MANDATORY"* ]] || [[ "$output" == *"REQUIRED"* ]] || [[ "$output" == *"NON-OPTIONAL"* ]]
}

@test "gate: different session_id re-emits the full block" {
  run_hook "$SID" "yes" >/dev/null
  local SID2="${SID}-alt"
  run run_hook "$SID2" "yes"
  [ "$status" -eq 0 ]
  [ "${#output}" -gt 400 ]
  rm -f "/tmp/itil-assistant-gate-announced-${SID2}"
}

@test "gate: empty session_id emits the full block and writes no marker" {
  run run_hook "" "yes, go"
  [ "$status" -eq 0 ]
  [ "${#output}" -gt 400 ]
  [ ! -f "/tmp/itil-assistant-gate-announced-" ]
}

@test "gate: non-direction-pinning prompt does not emit a block" {
  # A conversational prompt with no direction/act-verb/yes signal
  # should not burn the session-marker budget.
  run run_hook "$SID" "what does ADR-013 say about ambiguous decisions?"
  [ "$status" -eq 0 ]
  # May emit a short neutral note OR nothing, but must not emit the
  # full MANDATORY block on a non-direction prompt.
  [[ "$output" != *"MANDATORY: act"* ]] || [ "${#output}" -lt 250 ]
  # Must not have written the announcement marker either.
  [ ! -f "/tmp/itil-assistant-gate-announced-${SID}" ]
}

@test "gate: direction-pin via 'act now' verb triggers the block" {
  run run_hook "$SID" "act now and close the ticket"
  [ "$status" -eq 0 ]
  [ "${#output}" -gt 400 ]
  [[ "$output" == *"MANDATORY"* ]]
}

@test "gate: direction-pin via 'just do it' triggers the block" {
  run run_hook "$SID" "just do it"
  [ "$status" -eq 0 ]
  [ "${#output}" -gt 400 ]
  [[ "$output" == *"MANDATORY"* ]]
}

@test "gate: terse reminder references AskUserQuestion" {
  run_hook "$SID" "yes" >/dev/null
  run run_hook "$SID" "proceed"
  [ "$status" -eq 0 ]
  [[ "$output" == *"AskUserQuestion"* ]]
}
