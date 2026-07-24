#!/usr/bin/env bats

# Scope tests for tdd-enforce-edit.sh — verifies VCS-internal .git/ plumbing is
# exempt from the TDD gate (P458). tdd's exclusion sits in a standalone `case`
# BEFORE tdd_classify_file, so a .git/ path short-circuits ahead of the RED/GREEN
# state machine even when an impl edit would otherwise be blocked.

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$SCRIPT_DIR/tdd-enforce-edit.sh"
  ORIG_DIR="$PWD"
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR"
  # No package.json test script configured → an impl edit is normally BLOCKED
  # (IDLE state, chicken-and-egg). This makes the .git/ exemption load-bearing.
  printf '{"name":"t"}' > package.json
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TEST_DIR"
}

run_hook_with_file() {
  local file_path="$1"
  local json="{\"tool_input\":{\"file_path\":\"${file_path}\"},\"session_id\":\"test-session-$$\"}"
  echo "$json" | bash "$HOOK"
}

@test "tdd: exempts VCS-internal .git/ files even when an impl edit would be blocked (P458)" {
  # A .ts under .git/ would classify as impl and BLOCK (no test script), but the
  # .git/ exclusion short-circuits ahead of classification.
  run run_hook_with_file "$PWD/.git/hooks/pre-commit.ts"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

@test "tdd: still blocks an ordinary impl .ts when no test script exists (gate engaged)" {
  # Contrast case proving the harness actually engages the gate.
  run run_hook_with_file "$PWD/src/index.ts"
  [ "$status" -eq 0 ]
  [[ "$output" == *"BLOCKED"* ]]
}
