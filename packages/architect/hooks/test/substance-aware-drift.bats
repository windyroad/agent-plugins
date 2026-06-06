#!/usr/bin/env bats

# Behavioural tests for ADR-009 amendment 2026-06-06: substance-aware drift +
# atomic verdict-write. Closes P353 (hash-marker brittleness umbrella) +
# P303 (architect-gate multi-ADR deadlock drift-relock facet).
#
# Cases ratified by the user 2026-06-06:
#   (a) Trivial edit (whitespace, CRLF, trailing newline) does NOT re-trigger.
#   (b) Substantive edit (new content, changed line) DOES re-trigger.
#   (c) Atomic write — marker + hash file land together on PASS, with the
#       marker's mtime current and the hash file's content equal to the
#       substance hash of the policy content.
#   (d) Conservative fallback — semantic edits beyond the documented
#       whitespace normalisation (e.g. single-numeral change) ARE treated as
#       substantive (re-review fires).

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$SCRIPT_DIR/lib/gate-helpers.sh"
  source "$SCRIPT_DIR/lib/architect-gate.sh"

  TEST_SESSION="bats-arch-substance-$$-${BATS_TEST_NUMBER}"
  TEST_DIR=$(mktemp -d -t substance-aware-drift.XXXXXX)
  mkdir -p "$TEST_DIR/docs/decisions"
  CLAUDE_PROJECT_DIR="$TEST_DIR"
  export CLAUDE_PROJECT_DIR

  MARKER="/tmp/architect-reviewed-${TEST_SESSION}"
  HASH_FILE="${MARKER}.hash"
  rm -f "$MARKER" "$HASH_FILE"
}

teardown() {
  rm -f "$MARKER" "$HASH_FILE"
  rm -rf "$TEST_DIR"
}

# Helper: install ADR content, then store the substance hash + marker as the
# architect-mark-reviewed.sh PASS path would.
_install_and_mark() {
  local body="$1"
  printf '%s' "$body" > "$TEST_DIR/docs/decisions/123-test.proposed.md"
  local hash
  hash=$(_substance_hash_path "$TEST_DIR/docs/decisions")
  _atomic_mark_with_hash "$MARKER" "$hash"
}

# ---------------------------------------------------------------------------
# Case (a) — trivial whitespace / line-ending edits do NOT re-trigger
# ---------------------------------------------------------------------------

@test "substance-aware: trailing-whitespace edit does NOT re-trigger drift" {
  _install_and_mark "# ADR-123

A line of policy content.
"
  # Add trailing spaces to the same line.
  printf '%s' "# ADR-123

A line of policy content.
" > "$TEST_DIR/docs/decisions/123-test.proposed.md"

  run check_architect_gate "$TEST_SESSION"
  [ "$status" -eq 0 ]
  [ -f "$MARKER" ]
  [ -f "$HASH_FILE" ]
}

@test "substance-aware: CRLF→LF edit does NOT re-trigger drift" {
  _install_and_mark "# ADR-123

A line of policy content.
"
  # Convert the same content to CRLF line endings.
  printf '# ADR-123\r\n\r\nA line of policy content.\r\n' \
    > "$TEST_DIR/docs/decisions/123-test.proposed.md"

  run check_architect_gate "$TEST_SESSION"
  [ "$status" -eq 0 ]
  [ -f "$MARKER" ]
}

@test "substance-aware: extra trailing newlines do NOT re-trigger drift" {
  _install_and_mark "# ADR-123

A line of policy content.
"
  # Add multiple trailing newlines.
  printf '%s' "# ADR-123

A line of policy content.



" > "$TEST_DIR/docs/decisions/123-test.proposed.md"

  run check_architect_gate "$TEST_SESSION"
  [ "$status" -eq 0 ]
  [ -f "$MARKER" ]
}

# ---------------------------------------------------------------------------
# Case (b) — substantive content edits DO re-trigger
# ---------------------------------------------------------------------------

@test "substance-aware: new-word edit DOES re-trigger drift" {
  _install_and_mark "# ADR-123

A line of policy content.
"
  # Real content change.
  printf '%s' "# ADR-123

A different line of policy content.
" > "$TEST_DIR/docs/decisions/123-test.proposed.md"

  run check_architect_gate "$TEST_SESSION"
  [ "$status" -ne 0 ]
  [ ! -f "$MARKER" ]
  [ ! -f "$HASH_FILE" ]
}

@test "substance-aware: added-paragraph edit DOES re-trigger drift" {
  _install_and_mark "# ADR-123

A line of policy content.
"
  printf '%s' "# ADR-123

A line of policy content.

A whole new paragraph of substantive change.
" > "$TEST_DIR/docs/decisions/123-test.proposed.md"

  run check_architect_gate "$TEST_SESSION"
  [ "$status" -ne 0 ]
  [ ! -f "$MARKER" ]
}

@test "substance-aware: new file in docs/decisions DOES re-trigger drift" {
  _install_and_mark "# ADR-123

Content.
"
  # Adding a NEW ADR file is a substantive change.
  printf '%s' "# ADR-124

New ADR content.
" > "$TEST_DIR/docs/decisions/124-new.proposed.md"

  run check_architect_gate "$TEST_SESSION"
  [ "$status" -ne 0 ]
  [ ! -f "$MARKER" ]
}

# ---------------------------------------------------------------------------
# Case (c) — atomic write persists the PASS marker reliably
# ---------------------------------------------------------------------------

@test "atomic-write: PASS write lands marker + hash together" {
  printf '%s' "# ADR-123

Policy content.
" > "$TEST_DIR/docs/decisions/123-test.proposed.md"
  local hash
  hash=$(_substance_hash_path "$TEST_DIR/docs/decisions")

  run _atomic_mark_with_hash "$MARKER" "$hash"
  [ "$status" -eq 0 ]
  [ -f "$MARKER" ]
  [ -f "$HASH_FILE" ]
  # The stored hash equals the substance hash of the policy content.
  [ "$(cat "$HASH_FILE")" = "$hash" ]
}

@test "atomic-write: failed hash-write leaves neither file (no half-state)" {
  # Point the marker into a non-existent directory to force mv failure.
  local bad_marker="/tmp/does-not-exist-bats-$$/architect-reviewed-${TEST_SESSION}"
  run _atomic_mark_with_hash "$bad_marker" "deadbeef"
  [ "$status" -ne 0 ]
  [ ! -f "$bad_marker" ]
  [ ! -f "${bad_marker}.hash" ]
}

@test "atomic-write: PASS write enables a subsequent gate check to allow" {
  printf '%s' "# ADR-123

Policy content.
" > "$TEST_DIR/docs/decisions/123-test.proposed.md"
  local hash
  hash=$(_substance_hash_path "$TEST_DIR/docs/decisions")
  _atomic_mark_with_hash "$MARKER" "$hash"

  run check_architect_gate "$TEST_SESSION"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Case (d) — conservative boundary: semantic edits beyond whitespace
# normalisation ARE treated as substantive
# ---------------------------------------------------------------------------

@test "conservative: single-numeral change DOES re-trigger drift" {
  _install_and_mark "# ADR-123

Threshold is 5 minutes.
"
  # A single-numeral change is semantic — conservative boundary re-reviews.
  printf '%s' "# ADR-123

Threshold is 6 minutes.
" > "$TEST_DIR/docs/decisions/123-test.proposed.md"

  run check_architect_gate "$TEST_SESSION"
  [ "$status" -ne 0 ]
  [ ! -f "$MARKER" ]
}

@test "conservative: frontmatter-key change DOES re-trigger drift" {
  _install_and_mark "---
status: proposed
date: 2026-06-06
---

# ADR-123

Body.
"
  # Frontmatter date bump — conservative boundary re-reviews.
  printf '%s' "---
status: proposed
date: 2026-06-07
---

# ADR-123

Body.
" > "$TEST_DIR/docs/decisions/123-test.proposed.md"

  run check_architect_gate "$TEST_SESSION"
  [ "$status" -ne 0 ]
  [ ! -f "$MARKER" ]
}
