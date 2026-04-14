#!/usr/bin/env bats

# Tests for JTBD mark-reviewed hook — verifies hash path supports both formats

@test "mark-reviewed supports docs/jtbd directory path" {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  grep -q '"docs/jtbd"' "$SCRIPT_DIR/jtbd-mark-reviewed.sh"
}

@test "mark-reviewed supports docs/JOBS_TO_BE_DONE.md fallback" {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  grep -q 'docs/JOBS_TO_BE_DONE.md' "$SCRIPT_DIR/jtbd-mark-reviewed.sh"
}

@test "enforce-edit and mark-reviewed both support docs/jtbd" {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  grep -q '"docs/jtbd"' "$SCRIPT_DIR/jtbd-enforce-edit.sh"
  grep -q '"docs/jtbd"' "$SCRIPT_DIR/jtbd-mark-reviewed.sh"
}
