#!/usr/bin/env bats

# P095 / ADR-038: architect-detect.sh UserPromptSubmit hook must emit
# the full MANDATORY instruction block only on the first prompt of a
# session (identified by session_id on stdin). Subsequent prompts in
# the same session emit only a terse reminder. New sessions or empty
# session_ids fall back to the full block.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  HOOK="$REPO_ROOT/packages/architect/hooks/architect-detect.sh"

  # Stub project working dir so the hook's docs/decisions/ detection fires.
  WORKDIR="$(mktemp -d)"
  mkdir -p "$WORKDIR/docs/decisions"
  : > "$WORKDIR/docs/decisions/.keep"

  SID="arch-detect-test-$$-$RANDOM"
}

teardown() {
  rm -f "/tmp/architect-announced-${SID}"
  rm -f "/tmp/architect-announced-${SID}-alt"
  rm -rf "$WORKDIR"
}

# Helper: invoke the hook with a given session_id from stdin, while cd'd
# into WORKDIR so the `docs/decisions` detection picks up the stub.
run_hook() {
  local sid="$1"
  (cd "$WORKDIR" && echo "{\"session_id\":\"$sid\"}" | bash "$HOOK")
}

@test "architect-detect: first invocation emits the full MANDATORY block" {
  run run_hook "$SID"
  [ "$status" -eq 0 ]
  [ "${#output}" -gt 500 ]
  [[ "$output" == *"MANDATORY ARCHITECTURE CHECK"* ]]
  [[ "$output" == *"wr-architect:agent"* ]]
  [[ "$output" == *"SCOPE:"* ]]
}

@test "architect-detect: first invocation writes the announcement marker" {
  run run_hook "$SID"
  [ "$status" -eq 0 ]
  [ -f "/tmp/architect-announced-${SID}" ]
}

@test "architect-detect: second invocation emits only a terse reminder" {
  run_hook "$SID" >/dev/null
  run run_hook "$SID"
  [ "$status" -eq 0 ]
  # Terse reminder is < 250 bytes; full block is > 500 bytes.
  [ "${#output}" -lt 250 ]
  # Terse reminder names the gate AND the delegation affordance.
  [[ "$output" == *"architecture"* ]] || [[ "$output" == *"ARCHITECTURE"* ]]
  [[ "$output" == *"wr-architect:agent"* ]]
  # Full SCOPE block is NOT re-emitted.
  [[ "$output" != *"Does NOT apply to"* ]]
}

@test "architect-detect: terse reminder preserves the MANDATORY signal word" {
  run_hook "$SID" >/dev/null
  run run_hook "$SID"
  [ "$status" -eq 0 ]
  # Per JTBD-lead condition: terse reminder must keep an imperative
  # marker (MANDATORY / REQUIRED / NON-OPTIONAL) so the enforcement
  # signal does not soften after turn 1.
  [[ "$output" == *"MANDATORY"* ]] || [[ "$output" == *"REQUIRED"* ]] || [[ "$output" == *"NON-OPTIONAL"* ]]
}

@test "architect-detect: terse reminder names the trigger artifact" {
  run_hook "$SID" >/dev/null
  run run_hook "$SID"
  [ "$status" -eq 0 ]
  # Per JTBD-lead condition: reason for the gate must stay visible
  # on subsequent turns.
  [[ "$output" == *"docs/decisions"* ]]
}

@test "architect-detect: different session_id re-emits the full block" {
  run_hook "$SID" >/dev/null
  local SID2="${SID}-alt"
  run run_hook "$SID2"
  [ "$status" -eq 0 ]
  [ "${#output}" -gt 500 ]
  [[ "$output" == *"MANDATORY ARCHITECTURE CHECK"* ]]
  rm -f "/tmp/architect-announced-${SID2}"
}

@test "architect-detect: empty session_id emits the full block and writes no marker" {
  run run_hook ""
  [ "$status" -eq 0 ]
  [ "${#output}" -gt 500 ]
  [[ "$output" == *"MANDATORY ARCHITECTURE CHECK"* ]]
  [ ! -f "/tmp/architect-announced-" ]
}

@test "architect-detect: absent docs/decisions/ emits the no-decisions NOTE (unchanged by this ADR)" {
  local NO_DECISIONS="$(mktemp -d)"
  run bash -c "cd '$NO_DECISIONS' && echo '{\"session_id\":\"$SID\"}' | bash '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"no docs/decisions/ directory"* ]]
  [[ "$output" != *"MANDATORY ARCHITECTURE CHECK"* ]]
  rm -rf "$NO_DECISIONS"
}
