#!/usr/bin/env bats

# P004: tdd-enforce-edit.sh project-root check.

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$SCRIPT_DIR/tdd-enforce-edit.sh"
}

run_hook_with_file() {
  local file_path="$1"
  local json="{\"tool_input\":{\"file_path\":\"${file_path}\"},\"session_id\":\"test-$$\"}"
  echo "$json" | bash "$HOOK"
}

@test "tdd project-root: absolute .ts outside project exits 0" {
  run run_hook_with_file "/Users/other/project/src/foo.ts"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}
