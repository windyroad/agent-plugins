#!/usr/bin/env bats

# P004: jtbd-enforce-edit.sh project-root check.

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$SCRIPT_DIR/jtbd-enforce-edit.sh"
}

run_hook_with_file() {
  local file_path="$1"
  local json="{\"tool_input\":{\"file_path\":\"${file_path}\"},\"session_id\":\"test-$$\"}"
  echo "$json" | bash "$HOOK"
}

@test "jtbd project-root: absolute path outside project exits 0" {
  run run_hook_with_file "/Users/other/somewhere/file.json"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

@test "jtbd project-root: home-dir config path exits 0" {
  run run_hook_with_file "/Users/somebody/.claude/channels/discord/access.json"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}
