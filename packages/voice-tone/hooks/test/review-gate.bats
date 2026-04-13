#!/usr/bin/env bats

# Tests for review-gate.sh (shared by voice-tone, style-guide, jtbd)

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$SCRIPT_DIR/lib/review-gate.sh"
  TEST_SESSION="test-$$-$BATS_TEST_NUMBER"
  TMPDIR_ORIG=$(mktemp -d)
}

teardown() {
  rm -f "/tmp/voice-tone-reviewed-${TEST_SESSION}"
  rm -f "/tmp/voice-tone-reviewed-${TEST_SESSION}.hash"
  rm -rf "$TMPDIR_ORIG"
}

@test "gate denies when no marker exists" {
  run check_review_gate "$TEST_SESSION" "voice-tone" "docs/VOICE-AND-TONE.md"
  [ "$status" -ne 0 ]
}

@test "gate allows when marker exists and is fresh" {
  touch "/tmp/voice-tone-reviewed-${TEST_SESSION}"
  run check_review_gate "$TEST_SESSION" "voice-tone" "docs/VOICE-AND-TONE.md"
  [ "$status" -eq 0 ]
}

@test "gate denies when marker is expired" {
  touch "/tmp/voice-tone-reviewed-${TEST_SESSION}"
  REVIEW_TTL=0 run check_review_gate "$TEST_SESSION" "voice-tone" "docs/VOICE-AND-TONE.md"
  [ "$status" -ne 0 ]
}

@test "store_review_hash creates hash file" {
  store_review_hash "$TEST_SESSION" "voice-tone" "docs/VOICE-AND-TONE.md"
  [ -f "/tmp/voice-tone-reviewed-${TEST_SESSION}.hash" ]
}

@test "_mtime returns a number" {
  touch "/tmp/voice-tone-reviewed-${TEST_SESSION}"
  result=$(_mtime "/tmp/voice-tone-reviewed-${TEST_SESSION}")
  [[ "$result" =~ ^[0-9]+$ ]]
}

@test "_hashcmd produces output" {
  result=$(echo "test" | _hashcmd)
  [ -n "$result" ]
}
