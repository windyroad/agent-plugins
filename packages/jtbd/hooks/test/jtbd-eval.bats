#!/usr/bin/env bats

# Tests for jtbd-eval.sh — verifies JTBD suggestion fires for any project

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$SCRIPT_DIR/jtbd-eval.sh"
  ORIG_DIR="$PWD"
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR"
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TEST_DIR"
}

@test "eval: suggests update-guide when JOBS_TO_BE_DONE.md missing (no UI files)" {
  # No UI files, no docs — should still suggest
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"wr-jtbd:update-guide"* ]]
}

@test "eval: suggests update-guide when JOBS_TO_BE_DONE.md missing (with UI files)" {
  mkdir -p src
  touch src/App.tsx
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"wr-jtbd:update-guide"* ]]
}

@test "eval: injects enforcement instruction when JOBS_TO_BE_DONE.md exists" {
  mkdir -p docs
  echo "# Jobs" > docs/JOBS_TO_BE_DONE.md
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"MANDATORY JTBD CHECK"* ]]
}

@test "eval: does not reference UI-only scoping in output" {
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  # Should not contain the old UI-only messaging
  [[ "$output" != *"UI files"* ]]
}
