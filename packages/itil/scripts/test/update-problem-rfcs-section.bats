#!/usr/bin/env bats

# @problem P170 — Slice 3 second half (B5.T8): the auto-maintained
# `## RFCs` section refresh contract on problem ticket bodies. Library
# helper called inline by /wr-itil:capture-rfc Step 6 and
# /wr-itil:manage-rfc Step 7+9 so the cross-tier reverse-trace stays
# current at every commit per ADR-014 single-commit grain.
#
# Behavioural per ADR-052: assert on file output state (idempotent
# table; lazy empty discipline; placement) — not on script source
# content (no structural greps per P081).
#
# Contract (per architect Q3 verdict):
#   - Section position: between `## Related` and `## Fix Released`
#     (or at EOF if neither sentinel present).
#   - Table format: `| RFC | Status | Title |` with separator row.
#   - Sort: RFC ID asc.
#   - Lazy empty: zero traced RFCs → section absent (no header,
#     no `_None._` prose).
#   - Idempotent: re-run over current state is a no-op (cmp -s holds).
#
# @adr ADR-060 (Phase 1 item 10 + Confirmation criterion 3)
# @adr ADR-052 (behavioural bats default)
# @adr ADR-022 (`## Fix Released` is the trailing closure section)
# @jtbd JTBD-008 (Decompose a Fix Into Coordinated Changes — reverse
#   trace surface)
# @jtbd JTBD-101 (atomic-fix-adopter friction guard — lazy empty)

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HELPER="$SCRIPTS_DIR/update-problem-rfcs-section.sh"
  RFCS_DIR="$(mktemp -d)"
  PROBLEMS_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$RFCS_DIR" "$PROBLEMS_DIR"
}

write_rfc() {
  local id="$1" slug="$2" status="$3"
  local problems="${4:-[P168]}"
  cat > "$RFCS_DIR/RFC-${id}-${slug}.${status}.md" <<EOF
---
status: ${status}
rfc-id: ${slug}
reported: 2026-05-05
decision-makers: [test]
problems: ${problems}
---

# RFC-${id}: ${slug}

stub
EOF
}

write_problem() {
  local num="$1" slug="$2" trailing="${3:-}"
  local file="$PROBLEMS_DIR/${num}-${slug}.open.md"
  cat > "$file" <<EOF
# Problem ${num}: ${slug}

**Status**: Open

## Description

stub

## Related

stub
EOF
  if [ -n "$trailing" ]; then
    printf '\n%s\n' "$trailing" >> "$file"
  fi
  echo "$file"
}

# ── Existence + executable ──────────────────────────────────────────────────

@test "helper exists" {
  [ -f "$HELPER" ]
}

@test "helper is executable" {
  [ -x "$HELPER" ]
}

# ── Lazy-empty discipline (JTBD-101 friction guard) ─────────────────────────

@test "no RFCs trace → section absent (lazy empty)" {
  pf=$(write_problem "168" "p168")
  bash "$HELPER" "$pf" "$RFCS_DIR"
  ! grep -q '^## RFCs' "$pf"
}

@test "no RFCs trace and section exists → section removed" {
  # A pre-existing stale section gets cleaned out when zero RFCs claim.
  pf=$(write_problem "168" "p168" $'## RFCs\n\n| RFC | Status | Title |\n|-----|--------|-------|\n| RFC-001 | accepted | foo |')
  bash "$HELPER" "$pf" "$RFCS_DIR"
  ! grep -q '^## RFCs' "$pf"
}

# ── Single-RFC trace ────────────────────────────────────────────────────────

@test "one RFC traces P → section appears with one row" {
  write_rfc "001" "foo" "accepted"
  pf=$(write_problem "168" "p168")
  bash "$HELPER" "$pf" "$RFCS_DIR"
  grep -q '^## RFCs' "$pf"
  grep -q '| RFC-001 | accepted | foo |' "$pf"
}

@test "table includes header + separator + data row" {
  write_rfc "001" "foo" "accepted"
  pf=$(write_problem "168" "p168")
  bash "$HELPER" "$pf" "$RFCS_DIR"
  grep -q '| RFC | Status | Title |' "$pf"
  grep -q '|-----|--------|-------|' "$pf"
  grep -q '| RFC-001 | accepted | foo |' "$pf"
}

# ── Multi-RFC trace + sort order ─────────────────────────────────────────────

@test "multiple RFCs trace P → all rows present, sorted by RFC ID asc" {
  write_rfc "002" "second" "proposed"
  write_rfc "001" "first" "accepted"
  pf=$(write_problem "168" "p168")
  bash "$HELPER" "$pf" "$RFCS_DIR"
  # Both rows present.
  grep -q '| RFC-001 | accepted | first |' "$pf"
  grep -q '| RFC-002 | proposed | second |' "$pf"
  # RFC-001 appears before RFC-002.
  rfc_001_line=$(grep -n '| RFC-001 |' "$pf" | head -1 | cut -d: -f1)
  rfc_002_line=$(grep -n '| RFC-002 |' "$pf" | head -1 | cut -d: -f1)
  [ "$rfc_001_line" -lt "$rfc_002_line" ]
}

# ── Idempotency ─────────────────────────────────────────────────────────────

@test "re-running with no claim change is a no-op (idempotent)" {
  write_rfc "001" "foo" "accepted"
  pf=$(write_problem "168" "p168")
  bash "$HELPER" "$pf" "$RFCS_DIR"
  hash1=$(shasum "$pf" | cut -d' ' -f1)
  bash "$HELPER" "$pf" "$RFCS_DIR"
  hash2=$(shasum "$pf" | cut -d' ' -f1)
  [ "$hash1" = "$hash2" ]
}

# ── Status update on existing row ────────────────────────────────────────────

@test "RFC status changes (proposed → accepted) → table row reflects new status" {
  write_rfc "001" "foo" "proposed"
  pf=$(write_problem "168" "p168")
  bash "$HELPER" "$pf" "$RFCS_DIR"
  grep -q '| RFC-001 | proposed | foo |' "$pf"
  # Now transition the RFC to accepted (simulate by renaming on disk).
  mv "$RFCS_DIR/RFC-001-foo.proposed.md" "$RFCS_DIR/RFC-001-foo.accepted.md"
  bash "$HELPER" "$pf" "$RFCS_DIR"
  grep -q '| RFC-001 | accepted | foo |' "$pf"
  # Old status should no longer be present for that RFC row.
  ! grep -q '| RFC-001 | proposed |' "$pf"
}

# ── Re-trace add/remove ─────────────────────────────────────────────────────

@test "RFC newly added trace → row appended" {
  write_rfc "001" "foo" "accepted"
  pf=$(write_problem "168" "p168")
  bash "$HELPER" "$pf" "$RFCS_DIR"
  grep -q '| RFC-001 |' "$pf"

  # Add a second RFC traced to P168.
  write_rfc "002" "bar" "proposed"
  bash "$HELPER" "$pf" "$RFCS_DIR"
  grep -q '| RFC-001 |' "$pf"
  grep -q '| RFC-002 |' "$pf"
}

@test "RFC trace removed (frontmatter no longer claims P) → row drops" {
  write_rfc "001" "foo" "accepted" "[P168]"
  write_rfc "002" "bar" "proposed" "[P168]"
  pf=$(write_problem "168" "p168")
  bash "$HELPER" "$pf" "$RFCS_DIR"
  grep -q '| RFC-001 |' "$pf"
  grep -q '| RFC-002 |' "$pf"

  # Re-trace RFC-002 to P169 only.
  rm -f "$RFCS_DIR/RFC-002-bar.proposed.md"
  write_rfc "002" "bar" "proposed" "[P169]"
  bash "$HELPER" "$pf" "$RFCS_DIR"
  grep -q '| RFC-001 |' "$pf"
  ! grep -q '| RFC-002 |' "$pf"
}

# ── Section placement ───────────────────────────────────────────────────────

@test "## RFCs section sits before ## Fix Released when present" {
  write_rfc "001" "foo" "verifying"
  pf=$(write_problem "168" "p168" $'## Fix Released\n\nReleased trailer prose.')
  bash "$HELPER" "$pf" "$RFCS_DIR"
  rfcs_line=$(grep -n '^## RFCs' "$pf" | head -1 | cut -d: -f1)
  fix_released_line=$(grep -n '^## Fix Released' "$pf" | head -1 | cut -d: -f1)
  [ "$rfcs_line" -lt "$fix_released_line" ]
}

@test "## RFCs section appears at EOF when no ## Fix Released section" {
  write_rfc "001" "foo" "accepted"
  pf=$(write_problem "168" "p168")
  bash "$HELPER" "$pf" "$RFCS_DIR"
  # ## RFCs is the last `## ` heading in the file.
  last_section=$(grep -E '^## ' "$pf" | tail -1)
  [[ "$last_section" == "## RFCs" ]]
}

# ── Multi-problem RFC composition ────────────────────────────────────────────

@test "RFC tracing two problems updates both ## RFCs sections" {
  write_rfc "001" "foo" "accepted" "[P168, P169]"
  pf168=$(write_problem "168" "p168")
  pf169=$(write_problem "169" "p169")
  bash "$HELPER" "$pf168" "$RFCS_DIR"
  bash "$HELPER" "$pf169" "$RFCS_DIR"
  grep -q '| RFC-001 |' "$pf168"
  grep -q '| RFC-001 |' "$pf169"
}

# ── ## Related preservation ─────────────────────────────────────────────────

@test "existing ## Related section is preserved when ## RFCs is added" {
  write_rfc "001" "foo" "accepted"
  pf=$(write_problem "168" "p168")
  bash "$HELPER" "$pf" "$RFCS_DIR"
  grep -q '^## Related' "$pf"
  grep -q '^## RFCs' "$pf"
  related_line=$(grep -n '^## Related' "$pf" | head -1 | cut -d: -f1)
  rfcs_line=$(grep -n '^## RFCs' "$pf" | head -1 | cut -d: -f1)
  # ## Related comes before ## RFCs.
  [ "$related_line" -lt "$rfcs_line" ]
}
