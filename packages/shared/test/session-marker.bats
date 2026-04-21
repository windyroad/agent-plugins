#!/usr/bin/env bats

# Unit tests for the shared session-marker helper (P095 / ADR-038).
# The helper is sourced by UserPromptSubmit hooks to gate the full
# MANDATORY instruction prose behind a once-per-session marker. First
# prompt of a session emits the full block + writes the marker;
# subsequent prompts see the marker and emit only a terse reminder.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
  HELPER="$REPO_ROOT/packages/shared/hooks/lib/session-marker.sh"

  # Unique marker namespace per test run so parallel runs don't collide.
  TEST_SID="sm-test-$$-$RANDOM"
  TEST_SYSTEM="test-sm"
}

teardown() {
  rm -f "/tmp/${TEST_SYSTEM}-announced-${TEST_SID}"
  rm -f "/tmp/${TEST_SYSTEM}-announced-alt-${TEST_SID}"
}

@test "session-marker: helper file exists and is sourceable" {
  [ -f "$HELPER" ]
  run bash -c "source '$HELPER'"
  [ "$status" -eq 0 ]
}

@test "session-marker: has_announced returns 1 when no marker exists" {
  run bash -c "source '$HELPER' && has_announced '$TEST_SYSTEM' '$TEST_SID'"
  [ "$status" -eq 1 ]
}

@test "session-marker: mark_announced creates the marker file" {
  run bash -c "source '$HELPER' && mark_announced '$TEST_SYSTEM' '$TEST_SID'"
  [ "$status" -eq 0 ]
  [ -f "/tmp/${TEST_SYSTEM}-announced-${TEST_SID}" ]
}

@test "session-marker: has_announced returns 0 after mark_announced" {
  bash -c "source '$HELPER' && mark_announced '$TEST_SYSTEM' '$TEST_SID'"
  run bash -c "source '$HELPER' && has_announced '$TEST_SYSTEM' '$TEST_SID'"
  [ "$status" -eq 0 ]
}

@test "session-marker: different SYSTEM values produce isolated markers" {
  bash -c "source '$HELPER' && mark_announced '$TEST_SYSTEM' '$TEST_SID'"
  run bash -c "source '$HELPER' && has_announced '${TEST_SYSTEM}-alt' '$TEST_SID'"
  [ "$status" -eq 1 ]
  rm -f "/tmp/${TEST_SYSTEM}-alt-announced-${TEST_SID}"
}

@test "session-marker: different SESSION_IDs produce isolated markers" {
  bash -c "source '$HELPER' && mark_announced '$TEST_SYSTEM' '$TEST_SID'"
  run bash -c "source '$HELPER' && has_announced '$TEST_SYSTEM' '${TEST_SID}-other'"
  [ "$status" -eq 1 ]
}

@test "session-marker: empty SESSION_ID falls back gracefully (has_announced returns 1)" {
  # Empty session id must not crash the hook. The gate falls back to
  # "not announced" so the first-prompt prose still emits.
  run bash -c "source '$HELPER' && has_announced '$TEST_SYSTEM' ''"
  [ "$status" -eq 1 ]
}

@test "session-marker: empty SESSION_ID does not write a marker file" {
  # mark_announced with empty SESSION_ID must be a no-op (no stray
  # /tmp/<system>-announced- file with empty suffix).
  run bash -c "source '$HELPER' && mark_announced '$TEST_SYSTEM' ''"
  [ "$status" -eq 0 ]
  [ ! -f "/tmp/${TEST_SYSTEM}-announced-" ]
}

@test "session-marker: mark_announced is idempotent (repeated calls do not error)" {
  run bash -c "source '$HELPER' && mark_announced '$TEST_SYSTEM' '$TEST_SID' && mark_announced '$TEST_SYSTEM' '$TEST_SID'"
  [ "$status" -eq 0 ]
  [ -f "/tmp/${TEST_SYSTEM}-announced-${TEST_SID}" ]
}
