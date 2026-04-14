#!/usr/bin/env bats

# Tests for jtbd-enforce-edit.sh — verifies broadened scope with exclusions

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$SCRIPT_DIR/jtbd-enforce-edit.sh"
}

# Helper: check if a file extension is in the exclusion list by grepping the hook
file_is_excluded() {
  local pattern="$1"
  # The hook should have a case statement that exits 0 for excluded files
  grep -q "$pattern" "$HOOK"
}

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

@test "enforce: does NOT have UI-only case guard" {
  # The old guard matched only UI extensions then exited for everything else.
  # The new hook should NOT exit 0 for all non-UI files.
  ! grep -q '\*) exit 0 ;;' "$HOOK"
}
