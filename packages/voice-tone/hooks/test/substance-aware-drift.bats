#!/usr/bin/env bats

# Behavioural tests for ADR-009 amendment 2026-06-06: substance-aware drift +
# atomic verdict-write — voice-tone gate. Sibling-coverage to architect /
# jtbd / style-guide bats files of the same name.

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$SCRIPT_DIR/lib/review-gate.sh"

  TEST_SESSION="bats-vt-substance-$$-${BATS_TEST_NUMBER}"
  SYSTEM="voice-tone"
  TEST_DIR=$(mktemp -d -t substance-aware-drift-vt.XXXXXX)
  POLICY_FILE="$TEST_DIR/VOICE-AND-TONE.md"

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

@test "voice-tone substance-aware: trailing-whitespace edit does NOT re-trigger" {
  _install_and_mark "# Voice and Tone

Plain. Direct. Concise.
"
  printf '%s' "# Voice and Tone

Plain. Direct. Concise.
" > "$POLICY_FILE"

  run check_review_gate "$TEST_SESSION" "$SYSTEM" "$POLICY_FILE"
  [ "$status" -eq 0 ]
}

@test "voice-tone substance-aware: new-content edit DOES re-trigger" {
  _install_and_mark "# Voice and Tone

Plain. Direct. Concise.
"
  printf '%s' "# Voice and Tone

Plain. Direct. Concise. Friendly.
" > "$POLICY_FILE"

  run check_review_gate "$TEST_SESSION" "$SYSTEM" "$POLICY_FILE"
  [ "$status" -ne 0 ]
  [ ! -f "$MARKER" ]
}

@test "voice-tone atomic-write: store_review_hash lands marker + hash together" {
  printf '%s' "# Voice and Tone

Body.
" > "$POLICY_FILE"
  touch "$MARKER"
  run store_review_hash "$TEST_SESSION" "$SYSTEM" "$POLICY_FILE"
  [ "$status" -eq 0 ]
  [ -f "$MARKER" ]
  [ -f "$HASH_FILE" ]
}

@test "voice-tone conservative: single-numeral change DOES re-trigger" {
  _install_and_mark "# Voice and Tone

Sentences should be at most 20 words.
"
  printf '%s' "# Voice and Tone

Sentences should be at most 25 words.
" > "$POLICY_FILE"

  run check_review_gate "$TEST_SESSION" "$SYSTEM" "$POLICY_FILE"
  [ "$status" -ne 0 ]
}
