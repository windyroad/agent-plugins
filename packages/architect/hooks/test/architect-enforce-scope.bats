#!/usr/bin/env bats

# Tests for architect-enforce-edit.sh — verifies peer-plugin policy files are
# exempt from the architect gate (P009). Each plugin governs its own policy
# docs via its own enforce hook; the architect should not re-gate them.
#
# All tests are functional (P011): they execute the hook with mock JSON
# input and assert on exit status + BLOCKED output. Source-grep assertions
# were removed because they over-specified the implementation and gave
# false confidence (a literal string can appear in source without the
# matching case branch actually short-circuiting).

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$SCRIPT_DIR/architect-enforce-edit.sh"
  ORIG_DIR="$PWD"
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR"
  # Engage the gate: architect-enforce only runs when docs/decisions/ exists.
  mkdir -p docs/decisions
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TEST_DIR"
}

# Helper: run the hook with a mock JSON input for a given file path.
# Claude Code passes absolute file_path values, so tests use $PWD-prefixed
# paths to match real shape (after the P004 root check).
run_hook_with_file() {
  local file_path="$1"
  local json="{\"tool_input\":{\"file_path\":\"${file_path}\"},\"session_id\":\"test-session-$$\"}"
  echo "$json" | bash "$HOOK"
}

assert_path_allowed() {
  local file_path="$1"
  run run_hook_with_file "$file_path"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

@test "architect: exempts JTBD policy file (P009)" {
  assert_path_allowed "$PWD/docs/JOBS_TO_BE_DONE.md"
}

@test "architect: exempts JTBD directory file (P009)" {
  assert_path_allowed "$PWD/docs/jtbd/solo-developer/persona.md"
}

@test "architect: exempts PRODUCT_DISCOVERY.md (P009)" {
  assert_path_allowed "$PWD/docs/PRODUCT_DISCOVERY.md"
}

@test "architect: exempts voice-tone policy file (P009)" {
  assert_path_allowed "$PWD/docs/VOICE-AND-TONE.md"
}

@test "architect: exempts style-guide policy file (P009)" {
  assert_path_allowed "$PWD/docs/STYLE-GUIDE.md"
}
