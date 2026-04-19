#!/usr/bin/env bats

# Tests for jtbd-eval.sh — verifies JTBD suggestion fires for any project.
# Canonical layout is docs/jtbd/ only (ADR-008 Option 3 chosen 2026-04-20).
# Legacy docs/JOBS_TO_BE_DONE.md is NOT consulted at runtime (P019).

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

@test "eval: suggests update-guide when docs/jtbd/ missing (no UI files)" {
  # No UI files, no docs — should still suggest
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"wr-jtbd:update-guide"* ]]
}

@test "eval: suggests update-guide when docs/jtbd/ missing (with UI files)" {
  mkdir -p src
  touch src/App.tsx
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"wr-jtbd:update-guide"* ]]
}

@test "eval: injects enforcement when docs/jtbd/README.md exists" {
  mkdir -p docs/jtbd
  echo "# Index" > docs/jtbd/README.md
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"MANDATORY JTBD CHECK"* ]]
}

@test "eval: does NOT consult legacy docs/JOBS_TO_BE_DONE.md (ADR-008 Option 3, P019)" {
  # Legacy single-file layout — gate must NOT inject the enforcement
  # instruction; instead it should suggest update-guide so the project
  # migrates into the directory layout.
  mkdir -p docs
  echo "# Jobs" > docs/JOBS_TO_BE_DONE.md
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" != *"MANDATORY JTBD CHECK"* ]]
  [[ "$output" == *"wr-jtbd:update-guide"* ]]
}

@test "eval: uses docs/jtbd/ when both layouts coexist (ADR-008 Option 3)" {
  mkdir -p docs/jtbd
  echo "# Index" > docs/jtbd/README.md
  echo "# Jobs" > docs/JOBS_TO_BE_DONE.md
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"docs/jtbd"* ]]
  [[ "$output" == *"MANDATORY JTBD CHECK"* ]]
}

@test "eval: does not reference UI-only scoping in output" {
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" != *"UI files"* ]]
}
