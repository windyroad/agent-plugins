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

# P191 Phase 2: the architect gate must resolve docs/decisions from the
# project root (CLAUDE_PROJECT_DIR), NOT the hook's actual runtime CWD. Claude
# Code can launch the hook with a working directory that differs from the
# session/project dir; a relative `[ ! -d "docs/decisions" ]` then
# false-negatives and the gate FAILS OPEN (exit 0) — silently DEACTIVATING the
# architect gate so edits bypass review. This is a governance hole, strictly
# more severe than the JTBD gate's fail-closed nuisance (P191 Phase 1).
@test "project-root: gate stays ACTIVE via CLAUDE_PROJECT_DIR when hook CWD differs (P191 Phase 2)" {
  local proj other json
  proj="$(mktemp -d)"
  other="$(mktemp -d)"        # a CWD that does NOT contain docs/decisions
  mkdir -p "$proj/docs/decisions"
  echo "# ADR" > "$proj/docs/decisions/001-test.proposed.md"
  json="{\"tool_input\":{\"file_path\":\"${proj}/src/index.ts\"},\"session_id\":\"test-session-$$\"}"
  # Fire from `other` (wrong CWD) with CLAUDE_PROJECT_DIR set to the real
  # project. Pre-fix this silently exited 0 (gate inactive, edit allowed);
  # post-fix the gate is ACTIVE and denies for the missing review marker.
  run env CLAUDE_PROJECT_DIR="$proj" bash -c "cd '$other' && printf '%s' '$json' | bash '$HOOK'"
  rm -rf "$proj" "$other"
  [[ "$output" == *"BLOCKED"* ]]
  [[ "$output" == *"without architecture review"* ]]
}

# P191 Phase 2 regression guard: when docs/decisions genuinely does not exist
# under the project root, the gate correctly stays INACTIVE (fail-open exit 0).
# The fix narrows the false-negative; it must not start gating projects that
# have no architecture decisions.
@test "project-root: genuinely-absent docs/decisions stays inactive (fail-open preserved, P191 Phase 2)" {
  local proj json
  proj="$(mktemp -d)"         # no docs/decisions created
  json="{\"tool_input\":{\"file_path\":\"${proj}/src/index.ts\"},\"session_id\":\"test-session-$$\"}"
  run env CLAUDE_PROJECT_DIR="$proj" bash -c "printf '%s' '$json' | bash '$HOOK'"
  rm -rf "$proj"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}
