#!/usr/bin/env bats

# Tests for jtbd-enforce-edit.sh — verifies broadened scope with exclusions.
# All tests are functional: they execute the hook with mock JSON input
# and assert on exit status and BLOCKED output. Source-grep assertions
# were removed (P011) — they over-specified the implementation and
# false-positived on legitimate refactors.

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$SCRIPT_DIR/jtbd-enforce-edit.sh"
  ORIG_DIR="$PWD"
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR"
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TEST_DIR"
}

# Helper: run the hook with a mock JSON input for a given file path
run_hook_with_file() {
  local file_path="$1"
  local json="{\"tool_input\":{\"file_path\":\"${file_path}\"},\"session_id\":\"test-session-$$\"}"
  echo "$json" | bash "$HOOK"
}

# Helper: assert the hook exits 0 and does NOT emit BLOCKED for the given path
assert_path_allowed() {
  local file_path="$1"
  run run_hook_with_file "$file_path"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

# Helper: assert the hook BLOCKS the given path
assert_path_blocked() {
  local file_path="$1"
  run run_hook_with_file "$file_path"
  [ "$status" -eq 0 ]
  [[ "$output" == *"BLOCKED"* ]]
}

# --- Exclusion tests (functional) ---

# Claude Code passes absolute file paths in tool_input.file_path, so tests
# use $PWD-prefixed paths to match the real shape (after the P004 root check).

@test "enforce: excludes CSS files" {
  assert_path_allowed "$PWD/src/styles.css"
}

@test "enforce: excludes image files" {
  assert_path_allowed "$PWD/public/logo.png"
}

@test "enforce: excludes font files" {
  assert_path_allowed "$PWD/public/fonts/regular.woff"
}

@test "enforce: excludes lockfiles" {
  assert_path_allowed "$PWD/package-lock.json"
}

@test "enforce: excludes changeset files" {
  assert_path_allowed "$PWD/.changeset/some-change.md"
}

@test "enforce: excludes memory files" {
  assert_path_allowed "$PWD/MEMORY.md"
}

@test "enforce: excludes plan files" {
  assert_path_allowed "$PWD/.claude/plans/2026-01-01-plan.md"
}

@test "enforce: excludes risk reports" {
  assert_path_allowed "$PWD/.risk-reports/2026-01-01.md"
}

@test "enforce: excludes RISK-POLICY.md" {
  assert_path_allowed "$PWD/RISK-POLICY.md"
}

@test "enforce: does NOT exempt by UI-only extension (ADR-007/008)" {
  # ADR-007/008 broadened scope: the hook must gate UI files like any
  # other source file, not silently allow them.
  assert_path_blocked "$PWD/src/Component.tsx"
}

@test "enforce: does NOT exempt .html files (ADR-007/008)" {
  assert_path_blocked "$PWD/public/index.html"
}

@test "enforce: does NOT exempt .vue files (ADR-007/008)" {
  assert_path_blocked "$PWD/src/App.vue"
}

# --- Functional tests (execute hook with mock JSON) ---

@test "functional: exempts docs/jtbd/ files" {
  run run_hook_with_file "docs/jtbd/solo-developer/persona.md"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

@test "functional: exempts docs/jtbd/ job files" {
  run run_hook_with_file "docs/jtbd/solo-developer/JTBD-001-governance.proposed.md"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

@test "functional: exempts docs/jtbd/README.md" {
  run run_hook_with_file "docs/jtbd/README.md"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

@test "functional: docs/JOBS_TO_BE_DONE.md is NOT an exempt governance artefact (ADR-008 Option 3, P019)" {
  # Legacy single-file path is no longer a recognised governance artefact.
  # When docs/jtbd/ exists the gate should fire against edits to the
  # legacy file (it is not exempt). When docs/jtbd/ does not exist the
  # gate blocks with an update-guide suggestion (covered separately).
  mkdir -p docs/jtbd
  echo "# Index" > docs/jtbd/README.md
  run run_hook_with_file "docs/JOBS_TO_BE_DONE.md"
  [ "$status" -eq 0 ]
  [[ "$output" == *"BLOCKED"* ]]
}

@test "functional: blocks src/index.ts when no JTBD docs exist" {
  run run_hook_with_file "src/index.ts"
  [ "$status" -eq 0 ]
  [[ "$output" == *"BLOCKED"* ]]
  [[ "$output" == *"wr-jtbd:update-guide"* ]]
}

@test "functional: blocks src/index.ts when docs/jtbd exists (needs review)" {
  mkdir -p docs/jtbd
  echo "# Index" > docs/jtbd/README.md
  run run_hook_with_file "src/index.ts"
  [ "$status" -eq 0 ]
  [[ "$output" == *"BLOCKED"* ]]
  [[ "$output" == *"wr-jtbd:agent"* ]]
}
