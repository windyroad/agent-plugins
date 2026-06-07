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

# P215 / RFC-021 — REVIEW_GATE_REASON must carry an explicit recovery
# directive naming the subagent_type and Agent tool, parallel to the
# architect-gate ARCHITECT_GATE_REASON shape.

@test "REVIEW_GATE_REASON names re-delegate directive when no marker" {
  REVIEW_GATE_REASON=""
  check_review_gate "$TEST_SESSION" "voice-tone" "docs/VOICE-AND-TONE.md" || true
  [[ "$REVIEW_GATE_REASON" == *"wr-voice-tone:agent"* ]]
  [[ "$REVIEW_GATE_REASON" == *"Agent tool"* ]]
}

@test "REVIEW_GATE_REASON names refresh-the-marker directive when TTL expired" {
  touch "/tmp/voice-tone-reviewed-${TEST_SESSION}"
  REVIEW_GATE_REASON=""
  REVIEW_TTL=0 check_review_gate "$TEST_SESSION" "voice-tone" "docs/VOICE-AND-TONE.md" || true
  [[ "$REVIEW_GATE_REASON" == *"expired"* ]]
  [[ "$REVIEW_GATE_REASON" == *"wr-voice-tone:agent"* ]]
  [[ "$REVIEW_GATE_REASON" == *"refresh the marker"* ]]
}

@test "REVIEW_GATE_REASON names drift directive when policy hash differs" {
  POLICY_FILE="$TMPDIR_ORIG/VOICE-AND-TONE.md"
  echo "# policy v1" > "$POLICY_FILE"
  touch "/tmp/voice-tone-reviewed-${TEST_SESSION}"
  echo "stale-hash" > "/tmp/voice-tone-reviewed-${TEST_SESSION}.hash"
  REVIEW_GATE_REASON=""
  check_review_gate "$TEST_SESSION" "voice-tone" "$POLICY_FILE" || true
  [[ "$REVIEW_GATE_REASON" == *"changed"* ]] || [[ "$REVIEW_GATE_REASON" == *"drift"* ]]
  [[ "$REVIEW_GATE_REASON" == *"wr-voice-tone:agent"* ]]
  [[ "$REVIEW_GATE_REASON" == *"refresh the marker"* ]]
}
