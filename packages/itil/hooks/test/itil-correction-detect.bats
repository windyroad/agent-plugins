#!/usr/bin/env bats

# P078: itil-correction-detect.sh UserPromptSubmit hook must detect
# strong-signal correction patterns in the incoming user prompt
# (FFS / DO NOT / direct contradiction / exasperation markers /
# meta-correction "you always|you never|you keep") and inject a
# MANDATORY systemMessage instructing the assistant to OFFER
# /wr-itil:capture-problem (with /wr-itil:manage-problem fallback)
# BEFORE addressing the operational request.
#
# Per ADR-038: full block emits once per session; subsequent prompts
# emit a terse reminder (<250 bytes) preserving the MANDATORY signal,
# the gate name, and the capture-problem affordance.
#
# Per feedback_behavioural_tests.md (P081): these are behavioural
# assertions — they simulate the hook payload on stdin and assert on
# what the hook emits, not on the source text of the hook file.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  HOOK="$REPO_ROOT/packages/itil/hooks/itil-correction-detect.sh"
  SID="itil-correction-test-$$-$RANDOM"
}

teardown() {
  rm -f "/tmp/itil-correction-detect-announced-${SID}"
  rm -f "/tmp/itil-correction-detect-announced-${SID}-alt"
}

run_hook() {
  local sid="$1"
  local prompt="$2"
  echo "{\"session_id\":\"$sid\",\"prompt\":$(printf '%s' "$prompt" | jq -Rs .)}" | bash "$HOOK"
}

@test "correction-detect: 'FFS' triggers full MANDATORY block on first emission" {
  run run_hook "$SID" "FFS, you didn't run the test"
  [ "$status" -eq 0 ]
  [ "${#output}" -gt 300 ]
  [[ "$output" == *"MANDATORY"* ]]
  [[ "$output" == *"capture-problem"* ]] || [[ "$output" == *"manage-problem"* ]]
}

@test "correction-detect: writes the announcement marker on first emission" {
  run run_hook "$SID" "FFS stop framing it that way"
  [ "$status" -eq 0 ]
  [ -f "/tmp/itil-correction-detect-announced-${SID}" ]
}

@test "correction-detect: all-caps imperative 'DO NOT' triggers the block" {
  run run_hook "$SID" "DO NOT TELL ME the cache is stale when you haven't installed it"
  [ "$status" -eq 0 ]
  [ "${#output}" -gt 300 ]
  [[ "$output" == *"MANDATORY"* ]]
}

@test "correction-detect: meta-correction 'you always' triggers the block" {
  run run_hook "$SID" "you always do this — frame your own failures as external"
  [ "$status" -eq 0 ]
  [ "${#output}" -gt 300 ]
  [[ "$output" == *"MANDATORY"* ]]
}

@test "correction-detect: direct contradiction 'that's wrong' triggers the block" {
  run run_hook "$SID" "no, that's wrong — the cache wasn't refreshed because you didn't install"
  [ "$status" -eq 0 ]
  [ "${#output}" -gt 300 ]
  [[ "$output" == *"MANDATORY"* ]]
}

@test "correction-detect: exasperation '!!!' triggers the block" {
  run run_hook "$SID" "stop framing your own failure as external!!!"
  [ "$status" -eq 0 ]
  [ "${#output}" -gt 300 ]
  [[ "$output" == *"MANDATORY"* ]]
}

@test "correction-detect: 'you're not listening' triggers the block" {
  run run_hook "$SID" "you're not listening — install first then check the cache"
  [ "$status" -eq 0 ]
  [ "${#output}" -gt 300 ]
  [[ "$output" == *"MANDATORY"* ]]
}

@test "correction-detect: second correction prompt in same session emits terse reminder only" {
  run_hook "$SID" "FFS that's not right" >/dev/null
  run run_hook "$SID" "DO NOT do that again"
  [ "$status" -eq 0 ]
  [ "${#output}" -lt 250 ]
  [[ "$output" == *"capture-problem"* ]] || [[ "$output" == *"manage-problem"* ]]
  [[ "$output" != *"NON-OPTIONAL RULES"* ]]
}

@test "correction-detect: terse reminder preserves MANDATORY / REQUIRED signal word" {
  run_hook "$SID" "FFS" >/dev/null
  run run_hook "$SID" "you keep doing this"
  [ "$status" -eq 0 ]
  [[ "$output" == *"MANDATORY"* ]] || [[ "$output" == *"REQUIRED"* ]] || [[ "$output" == *"NON-OPTIONAL"* ]]
}

@test "correction-detect: emitted block names capture-problem and manage-problem fallback" {
  run run_hook "$SID" "FFS!"
  [ "$status" -eq 0 ]
  [[ "$output" == *"capture-problem"* ]]
  [[ "$output" == *"manage-problem"* ]]
}

@test "correction-detect: different session_id re-emits the full block" {
  run_hook "$SID" "FFS" >/dev/null
  local SID2="${SID}-alt"
  run run_hook "$SID2" "FFS"
  [ "$status" -eq 0 ]
  [ "${#output}" -gt 300 ]
  rm -f "/tmp/itil-correction-detect-announced-${SID2}"
}

@test "correction-detect: empty session_id emits the full block and writes no marker" {
  run run_hook "" "FFS, that's wrong"
  [ "$status" -eq 0 ]
  [ "${#output}" -gt 300 ]
  [ ! -f "/tmp/itil-correction-detect-announced-" ]
}

@test "correction-detect: plain conversational prompt does not emit a block" {
  run run_hook "$SID" "what does ADR-013 say about ambiguous decisions?"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  [ ! -f "/tmp/itil-correction-detect-announced-${SID}" ]
}

@test "correction-detect: direction-pin 'yes' alone does not trigger" {
  run run_hook "$SID" "yes, go ahead and update the ticket"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  [ ! -f "/tmp/itil-correction-detect-announced-${SID}" ]
}
