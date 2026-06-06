#!/usr/bin/env bats

# Behavioural tests for ADR-009 amendment 2026-06-06: substance-aware drift +
# atomic verdict-write — JTBD gate. Closes P353 (hash-marker brittleness
# umbrella) for the review-gate.sh code path shared by JTBD / voice-tone /
# style-guide.
#
# Cases ratified 2026-06-06: see substance-aware-drift.bats in the architect
# package for the full contract. JTBD's tests cover the same four cases
# through `check_review_gate` + `store_review_hash`.

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$SCRIPT_DIR/lib/review-gate.sh"

  TEST_SESSION="bats-jtbd-substance-$$-${BATS_TEST_NUMBER}"
  SYSTEM="jtbd"
  TEST_DIR=$(mktemp -d -t substance-aware-drift-jtbd.XXXXXX)
  mkdir -p "$TEST_DIR/docs/jtbd"
  POLICY_DIR="$TEST_DIR/docs/jtbd"

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
  printf '%s' "$body" > "$POLICY_DIR/JTBD-001.proposed.md"
  touch "$MARKER"
  store_review_hash "$TEST_SESSION" "$SYSTEM" "$POLICY_DIR"
}

# ---------------------------------------------------------------------------
# Case (a) — trivial edits do NOT re-trigger
# ---------------------------------------------------------------------------

@test "jtbd substance-aware: trailing-whitespace edit does NOT re-trigger drift" {
  _install_and_mark "# JTBD-001

A job-to-be-done description.
"
  printf '%s' "# JTBD-001

A job-to-be-done description.
" > "$POLICY_DIR/JTBD-001.proposed.md"

  run check_review_gate "$TEST_SESSION" "$SYSTEM" "$POLICY_DIR"
  [ "$status" -eq 0 ]
  [ -f "$MARKER" ]
}

@test "jtbd substance-aware: CRLF→LF edit does NOT re-trigger drift" {
  _install_and_mark "# JTBD-001

Body.
"
  printf '# JTBD-001\r\n\r\nBody.\r\n' > "$POLICY_DIR/JTBD-001.proposed.md"

  run check_review_gate "$TEST_SESSION" "$SYSTEM" "$POLICY_DIR"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Case (b) — substantive edits DO re-trigger
# ---------------------------------------------------------------------------

@test "jtbd substance-aware: new-word edit DOES re-trigger drift" {
  _install_and_mark "# JTBD-001

A job-to-be-done description.
"
  printf '%s' "# JTBD-001

A different job-to-be-done description.
" > "$POLICY_DIR/JTBD-001.proposed.md"

  run check_review_gate "$TEST_SESSION" "$SYSTEM" "$POLICY_DIR"
  [ "$status" -ne 0 ]
  [ ! -f "$MARKER" ]
  [ ! -f "$HASH_FILE" ]
}

@test "jtbd substance-aware: new JTBD file DOES re-trigger drift" {
  _install_and_mark "# JTBD-001

Body.
"
  printf '%s' "# JTBD-002

New job.
" > "$POLICY_DIR/JTBD-002.proposed.md"

  run check_review_gate "$TEST_SESSION" "$SYSTEM" "$POLICY_DIR"
  [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# Case (c) — atomic write persists reliably
# ---------------------------------------------------------------------------

@test "jtbd atomic-write: store_review_hash lands marker + hash together" {
  printf '%s' "# JTBD-001

Body.
" > "$POLICY_DIR/JTBD-001.proposed.md"
  touch "$MARKER"
  run store_review_hash "$TEST_SESSION" "$SYSTEM" "$POLICY_DIR"
  [ "$status" -eq 0 ]
  [ -f "$MARKER" ]
  [ -f "$HASH_FILE" ]
  # Stored hash matches the substance hash of the policy content.
  local expected
  expected=$(_substance_hash_path "$POLICY_DIR")
  [ "$(cat "$HASH_FILE")" = "$expected" ]
}

# ---------------------------------------------------------------------------
# Case (d) — conservative boundary holds
# ---------------------------------------------------------------------------

@test "jtbd conservative: single-numeral change DOES re-trigger drift" {
  _install_and_mark "# JTBD-001

Threshold is 5 minutes.
"
  printf '%s' "# JTBD-001

Threshold is 6 minutes.
" > "$POLICY_DIR/JTBD-001.proposed.md"

  run check_review_gate "$TEST_SESSION" "$SYSTEM" "$POLICY_DIR"
  [ "$status" -ne 0 ]
}
