#!/usr/bin/env bats

# Tests for jtbd-enforce-edit.sh — verifies broadened scope with exclusions
# Mix of grep-based pattern tests and functional execution tests.

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

# Helper: check if a pattern is in the exclusion list by grepping the hook
file_is_excluded() {
  local pattern="$1"
  grep -q "$pattern" "$HOOK"
}

# Helper: run the hook with a mock JSON input for a given file path
run_hook_with_file() {
  local file_path="$1"
  local json="{\"tool_input\":{\"file_path\":\"${file_path}\"},\"session_id\":\"test-session-$$\"}"
  echo "$json" | bash "$HOOK"
}

# --- Pattern-based exclusion tests (grep) ---

@test "enforce: excludes CSS files" {
  file_is_excluded '\.css'
}

@test "enforce: excludes image files" {
  file_is_excluded '\.png'
}

@test "enforce: excludes font files" {
  file_is_excluded '\.woff'
}

@test "enforce: excludes lockfiles" {
  file_is_excluded 'package-lock.json'
}

@test "enforce: excludes changeset files" {
  file_is_excluded '\.changeset'
}

@test "enforce: excludes memory files" {
  file_is_excluded 'MEMORY.md'
}

@test "enforce: excludes plan files" {
  file_is_excluded '\.claude/plans'
}

@test "enforce: excludes risk reports" {
  file_is_excluded '\.risk-reports'
}

@test "enforce: excludes RISK-POLICY.md" {
  file_is_excluded 'RISK-POLICY.md'
}

@test "enforce: does NOT have UI-only extension filter (ADR-007/008)" {
  # ADR-007/008 removed web-UI-only scoping. The hook must not filter
  # by UI file extension. NOTE: `*) exit 0 ;;` is a legitimate pattern
  # for the project-root check (P004) — see jtbd-project-root.bats.
  ! grep -qE '\.html\||tsx\|jsx\|html\|vue\|svelte' "$HOOK"
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

@test "functional: exempts docs/JOBS_TO_BE_DONE.md (backward compat)" {
  run run_hook_with_file "docs/JOBS_TO_BE_DONE.md"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
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
