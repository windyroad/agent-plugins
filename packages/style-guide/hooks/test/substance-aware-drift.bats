#!/usr/bin/env bats

# Behavioural tests for ADR-009 amendment 2026-06-06: substance-aware drift +
# atomic verdict-write — style-guide gate. Sibling-coverage to architect /
# jtbd / voice-tone bats files of the same name.

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$SCRIPT_DIR/lib/review-gate.sh"

  TEST_SESSION="bats-sg-substance-$$-${BATS_TEST_NUMBER}"
  SYSTEM="style-guide"
  TEST_DIR=$(mktemp -d -t substance-aware-drift-sg.XXXXXX)
  POLICY_FILE="$TEST_DIR/STYLE-GUIDE.md"

  MARKER="/tmp/${SYSTEM}-reviewed-${TEST_SESSION}"
  HASH_FILE="${MARKER}.hash"
  rm -f "$MARKER" "$HASH_FILE"
}

teardown() {
  rm -f "$MARKER" "$HASH_FILE"
  rm -rf "$TEST_DIR"
}

_install_and_mark() {
  local body="$1"
  printf '%s' "$body" > "$POLICY_FILE"
  touch "$MARKER"
  store_review_hash "$TEST_SESSION" "$SYSTEM" "$POLICY_FILE"
}

@test "style-guide substance-aware: trailing-whitespace edit does NOT re-trigger" {
  _install_and_mark "# Style Guide

Use 2-space indentation.
"
  printf '%s' "# Style Guide

Use 2-space indentation.
" > "$POLICY_FILE"

  run check_review_gate "$TEST_SESSION" "$SYSTEM" "$POLICY_FILE"
  [ "$status" -eq 0 ]
}

@test "style-guide substance-aware: new-rule edit DOES re-trigger" {
  _install_and_mark "# Style Guide

Use 2-space indentation.
"
  printf '%s' "# Style Guide

Use 2-space indentation.
Always trailing-comma.
" > "$POLICY_FILE"

  run check_review_gate "$TEST_SESSION" "$SYSTEM" "$POLICY_FILE"
  [ "$status" -ne 0 ]
}

@test "style-guide atomic-write: store_review_hash lands marker + hash together" {
  printf '%s' "# Style Guide

Body.
" > "$POLICY_FILE"
  touch "$MARKER"
  run store_review_hash "$TEST_SESSION" "$SYSTEM" "$POLICY_FILE"
  [ "$status" -eq 0 ]
  [ -f "$MARKER" ]
  [ -f "$HASH_FILE" ]
}

@test "style-guide conservative: single-numeral change DOES re-trigger" {
  _install_and_mark "# Style Guide

Use 2-space indentation.
"
  printf '%s' "# Style Guide

Use 4-space indentation.
" > "$POLICY_FILE"

  run check_review_gate "$TEST_SESSION" "$SYSTEM" "$POLICY_FILE"
  [ "$status" -ne 0 ]
}
