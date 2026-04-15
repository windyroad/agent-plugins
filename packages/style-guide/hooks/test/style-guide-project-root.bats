#!/usr/bin/env bats

# P004: style-guide-enforce-edit.sh project-root check.

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$SCRIPT_DIR/style-guide-enforce-edit.sh"
}

run_hook_with_file() {
  local file_path="$1"
  local json="{\"tool_input\":{\"file_path\":\"${file_path}\"},\"session_id\":\"test-$$\"}"
  echo "$json" | bash "$HOOK"
}

@test "style-guide project-root: absolute .css outside project exits 0" {
  run run_hook_with_file "/Users/other/project/src/style.css"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}
