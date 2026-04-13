#!/usr/bin/env bats

# Tests for JTBD mark-reviewed hook — verifies hash path matches enforce hook

@test "mark-reviewed uses docs/JOBS_TO_BE_DONE.md path" {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  grep -q 'docs/JOBS_TO_BE_DONE.md' "$SCRIPT_DIR/jtbd-mark-reviewed.sh"
}

@test "mark-reviewed does NOT use docs/jtbd path" {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  ! grep -q '"docs/jtbd"' "$SCRIPT_DIR/jtbd-mark-reviewed.sh"
}

@test "enforce-edit and mark-reviewed use same policy path" {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  ENFORCE_PATH=$(grep -o 'docs/JOBS_TO_BE_DONE.md' "$SCRIPT_DIR/jtbd-enforce-edit.sh" | head -1)
  MARK_PATH=$(grep -o 'docs/JOBS_TO_BE_DONE.md' "$SCRIPT_DIR/jtbd-mark-reviewed.sh" | head -1)
  [ "$ENFORCE_PATH" = "$MARK_PATH" ]
}
