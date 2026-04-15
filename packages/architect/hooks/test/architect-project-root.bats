#!/usr/bin/env bats

# Tests for architect-enforce-edit.sh project-root check (P004).
# Verifies that absolute paths outside $PWD are exempted.

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$SCRIPT_DIR/architect-enforce-edit.sh"
  ORIG_DIR="$PWD"
}

teardown() {
  cd "$ORIG_DIR"
}

run_hook_with_file() {
  local file_path="$1"
  local json="{\"tool_input\":{\"file_path\":\"${file_path}\"},\"session_id\":\"test-session-$$\"}"
  echo "$json" | bash "$HOOK"
}

@test "project-root: absolute path outside project exits 0" {
  run run_hook_with_file "/Users/other/somewhere/file.json"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

@test "project-root: home-dir config path exits 0" {
  run run_hook_with_file "/Users/somebody/.claude/channels/discord/access.json"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

@test "project-root: absolute path inside \$PWD is still gated" {
  # Use a temp dir as PWD with docs/decisions to trigger the gate
  TEST_DIR=$(mktemp -d)
  mkdir -p "$TEST_DIR/docs/decisions"
  echo "# ADR" > "$TEST_DIR/docs/decisions/001-test.proposed.md"
  cd "$TEST_DIR"
  run run_hook_with_file "$TEST_DIR/src/index.ts"
  [ "$status" -eq 0 ]
  [[ "$output" == *"BLOCKED"* ]]
  rm -rf "$TEST_DIR"
}
