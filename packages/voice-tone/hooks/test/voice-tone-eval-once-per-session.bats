#!/usr/bin/env bats

# P095 / ADR-038: voice-tone-eval.sh UserPromptSubmit hook must emit
# the full MANDATORY block only on the first prompt of a session;
# subsequent prompts emit a terse reminder.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  HOOK="$REPO_ROOT/packages/voice-tone/hooks/voice-tone-eval.sh"

  WORKDIR="$(mktemp -d)"
  mkdir -p "$WORKDIR/docs"
  : > "$WORKDIR/docs/VOICE-AND-TONE.md"

  SID="vt-eval-test-$$-$RANDOM"
}

teardown() {
  rm -f "/tmp/voice-tone-announced-${SID}"
  rm -f "/tmp/voice-tone-announced-${SID}-alt"
  rm -rf "$WORKDIR"
}

run_hook() {
  local sid="$1"
  (cd "$WORKDIR" && echo "{\"session_id\":\"$sid\"}" | bash "$HOOK")
}

@test "voice-tone-eval: first invocation emits the full MANDATORY block" {
  run run_hook "$SID"
  [ "$status" -eq 0 ]
  [ "${#output}" -gt 400 ]
  [[ "$output" == *"MANDATORY VOICE & TONE CHECK"* ]]
  [[ "$output" == *"wr-voice-tone:agent"* ]]
}

@test "voice-tone-eval: first invocation writes the announcement marker" {
  run run_hook "$SID"
  [ -f "/tmp/voice-tone-announced-${SID}" ]
}

@test "voice-tone-eval: second invocation emits only a terse reminder" {
  run_hook "$SID" >/dev/null
  run run_hook "$SID"
  [ "${#output}" -lt 250 ]
  [[ "$output" == *"voice-and-tone"* ]] || [[ "$output" == *"VOICE"* ]] || [[ "$output" == *"voice"* ]]
  [[ "$output" == *"wr-voice-tone:agent"* ]]
  [[ "$output" != *"REQUIRED ACTIONS:"* ]]
}

@test "voice-tone-eval: terse reminder preserves the MANDATORY signal word" {
  run_hook "$SID" >/dev/null
  run run_hook "$SID"
  [[ "$output" == *"MANDATORY"* ]] || [[ "$output" == *"REQUIRED"* ]] || [[ "$output" == *"NON-OPTIONAL"* ]]
}

@test "voice-tone-eval: terse reminder names the trigger artifact" {
  run_hook "$SID" >/dev/null
  run run_hook "$SID"
  [[ "$output" == *"VOICE-AND-TONE.md"* ]]
}

@test "voice-tone-eval: different session_id re-emits the full block" {
  run_hook "$SID" >/dev/null
  local SID2="${SID}-alt"
  run run_hook "$SID2"
  [ "${#output}" -gt 400 ]
  [[ "$output" == *"MANDATORY VOICE & TONE CHECK"* ]]
  rm -f "/tmp/voice-tone-announced-${SID2}"
}

@test "voice-tone-eval: empty session_id emits the full block and writes no marker" {
  run run_hook ""
  [ "${#output}" -gt 400 ]
  [[ "$output" == *"MANDATORY VOICE & TONE CHECK"* ]]
  [ ! -f "/tmp/voice-tone-announced-" ]
}
