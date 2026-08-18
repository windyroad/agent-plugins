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

# P215 / RFC-021 — ARCHITECT_GATE_REASON behaviour. The gate must expose a
# differentiated reason per failure mode (no marker / TTL expired / drift
# detected) so the downstream deny message carries a clear recovery directive.
# Mirrors sibling REVIEW_GATE_REASON pattern in jtbd/voice-tone/style-guide
# review-gate.sh.

@test "ARCHITECT_GATE_REASON names re-delegate directive when no marker" {
  ARCHITECT_GATE_REASON=""
  check_architect_gate "$TEST_SESSION" || true
  [[ "$ARCHITECT_GATE_REASON" == *"wr-architect:agent"* ]]
  [[ "$ARCHITECT_GATE_REASON" == *"Agent tool"* ]]
}

# P400 — the no-marker reason must also document the SendMessage-resume
# recovery path: a verdict upgrade after ISSUES FOUND is a FRESH Agent spawn
# (a SendMessage resume does NOT fire the marker hook), or the manual marker
# assertion. Without this directive the deny message is a dead-end for the
# most common recovery flow.
@test "ARCHITECT_GATE_REASON documents resumed-agent recovery when no marker" {
  ARCHITECT_GATE_REASON=""
  check_architect_gate "$TEST_SESSION" || true
  [[ "$ARCHITECT_GATE_REASON" == *"resuming the prior agent does not fire"* ]]
  [[ "$ARCHITECT_GATE_REASON" == *"fresh wr-architect:agent spawn"* ]]
  [[ "$ARCHITECT_GATE_REASON" == *"touch /tmp/architect-reviewed-"* ]]
  [[ "$ARCHITECT_GATE_REASON" == *"rm -f /tmp/architect-reviewed-"* ]]
}

@test "ARCHITECT_GATE_REASON names re-delegate directive when TTL expired" {
  touch "/tmp/architect-reviewed-${TEST_SESSION}"
  ARCHITECT_GATE_REASON=""
  ARCHITECT_TTL=0 check_architect_gate "$TEST_SESSION" || true
  [[ "$ARCHITECT_GATE_REASON" == *"expired"* ]]
  [[ "$ARCHITECT_GATE_REASON" == *"wr-architect:agent"* ]]
  [[ "$ARCHITECT_GATE_REASON" == *"refresh the marker"* ]]
}

@test "ARCHITECT_GATE_REASON names drift directive when stored hash differs" {
  # Set up project root with a docs/decisions directory and a stored hash that
  # differs from the current substance hash to force the drift branch.
  TEST_PROJECT_DIR=$(mktemp -d)
  mkdir -p "$TEST_PROJECT_DIR/docs/decisions"
  echo "# ADR-001 current content" > "$TEST_PROJECT_DIR/docs/decisions/001-x.md"
  touch "/tmp/architect-reviewed-${TEST_SESSION}"
  echo "stale-hash-that-will-not-match" > "/tmp/architect-reviewed-${TEST_SESSION}.hash"
  ARCHITECT_GATE_REASON=""
  CLAUDE_PROJECT_DIR="$TEST_PROJECT_DIR" check_architect_gate "$TEST_SESSION" || true
  rm -rf "$TEST_PROJECT_DIR"
  [[ "$ARCHITECT_GATE_REASON" == *"drift"* ]] || [[ "$ARCHITECT_GATE_REASON" == *"changed"* ]]
  [[ "$ARCHITECT_GATE_REASON" == *"wr-architect:agent"* ]]
  [[ "$ARCHITECT_GATE_REASON" == *"refresh the marker"* ]]
}

@test "architect-enforce-edit deny output includes ARCHITECT_GATE_REASON directive" {
  HOOK="$SCRIPT_DIR/architect-enforce-edit.sh"
  ORIG_DIR="$PWD"
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR"
  mkdir -p docs/decisions
  echo "# adr stub" > docs/decisions/001-x.md
  json="{\"tool_input\":{\"file_path\":\"$PWD/src/x.ts\"},\"session_id\":\"deny-test-$$\"}"
  run bash -c "echo '$json' | bash '$HOOK'"
  cd "$ORIG_DIR"
  rm -rf "$TEST_DIR"
  [[ "$output" == *"BLOCKED"* ]]
  [[ "$output" == *"wr-architect:agent"* ]]
  # No marker exists for this fresh session — deny reason must explicitly
  # name the re-delegate directive (not vague "review required").
  [[ "$output" == *"No architect review marker"* ]] || [[ "$output" == *"marker"* ]]
}
