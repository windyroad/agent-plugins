#!/usr/bin/env bats

# Tests for architect-gate.sh (TTL, drift, marker)

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$SCRIPT_DIR/lib/architect-gate.sh"
  TEST_SESSION="test-$$-$BATS_TEST_NUMBER"
}

teardown() {
  rm -f "/tmp/architect-reviewed-${TEST_SESSION}"
  rm -f "/tmp/architect-reviewed-${TEST_SESSION}.hash"
}

@test "gate denies when no marker exists" {
  run check_architect_gate "$TEST_SESSION"
  [ "$status" -ne 0 ]
}

@test "gate allows when marker exists and is fresh" {
  touch "/tmp/architect-reviewed-${TEST_SESSION}"
  run check_architect_gate "$TEST_SESSION"
  [ "$status" -eq 0 ]
}

@test "gate denies when marker is expired" {
  touch "/tmp/architect-reviewed-${TEST_SESSION}"
  # Set TTL to 0 to force expiry
  ARCHITECT_TTL=0 run check_architect_gate "$TEST_SESSION"
  [ "$status" -ne 0 ]
}
