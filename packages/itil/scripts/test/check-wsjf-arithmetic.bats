#!/usr/bin/env bats

# @problem P477 — WSJF is computed before the Open → Known Error auto-
# transition and nothing recomputes afterwards, so the persisted value
# keeps the Open 1.0 multiplier and the ticket ranks at half value. The
# wrong number is written consistently to the ticket body AND to
# docs/problems/README.md, so `reconcile-readme.sh` — which compares
# ticket-ID-to-status membership and never parses a WSJF number — exits
# 0 clean on it. This script is the arithmetic layer that does not.
#
# Contract: `check-wsjf-arithmetic.sh [<problems-dir>]` is diagnose-only
# and read-only. For each open / known-error ticket it recomputes
# `(Severity × Status Multiplier) / Effort Divisor` from the ticket's own
# `**Priority**`, status (filename suffix or per-state subdir) and
# `**Effort**` fields, and reports disagreement with the stored `**WSJF**`.
#
# Exit codes:
#   0 = every parseable ticket's stored WSJF matches its own fields
#   1 = at least one mismatch (structured report on stdout)
#   2 = parse error (problems dir missing)
#
# Status multipliers: Open 1.0, Known Error 2.0. Verification Pending and
# Parked are multiplier 0 / excluded from dev ranking per ADR-022, so
# they carry no arithmetic to reconcile and are not checked.
#
# Effort divisors: S 1, M 2, L 4, XL 8.
#
# @adr ADR-022 (Verification Pending / Parked excluded — multiplier 0)
# @adr ADR-031 (Per-state subdir layout)
# @adr ADR-038 (Progressive disclosure — ≤150-byte diff rows)
# @adr ADR-052 (Behavioural tests by default — these assert observable
#   script behaviour over synthetic fixtures, not SKILL.md prose greps)
# @jtbd JTBD-006 (Progress the Backlog While I'm Away — the AFK loop
#   picks by WSJF, so a halved value silently mis-sequences the queue)
# @jtbd JTBD-202 (Run Pre-Flight Governance Checks Before Release)

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$SCRIPTS_DIR/check-wsjf-arithmetic.sh"
  FIXTURE_DIR="$(mktemp -d)"
  mkdir -p "$FIXTURE_DIR/open" "$FIXTURE_DIR/known-error" \
           "$FIXTURE_DIR/verifying" "$FIXTURE_DIR/parked"
}

teardown() {
  rm -rf "$FIXTURE_DIR"
}

# Write a ticket into the per-state subdir layout.
# usage: mk_ticket <state> <NNN> <severity> <effort> <wsjf>
mk_ticket() {
  local state="$1" num="$2" sev="$3" effort="$4" wsjf="$5"
  local status_label
  case "$state" in
    open)        status_label="Open" ;;
    known-error) status_label="Known Error" ;;
    verifying)   status_label="Verification Pending" ;;
    parked)      status_label="Parked" ;;
  esac
  cat > "$FIXTURE_DIR/$state/${num}-fixture-ticket.md" <<EOF
# Problem ${num}: Fixture ticket

**Status**: ${status_label}
**Reported**: 2026-08-08
**Priority**: ${sev} (High) — Impact: 3 × Likelihood: 4
**Origin**: internal
**Effort**: ${effort} — fixture
**WSJF**: ${wsjf} — fixture

## Description

Fixture.
EOF
}

# ── Existence + executable ──────────────────────────────────────────────────

@test "check-wsjf-arithmetic: script exists" {
  [ -f "$SCRIPT" ]
}

@test "check-wsjf-arithmetic: script is executable" {
  [ -x "$SCRIPT" ]
}

# ── Parse error ─────────────────────────────────────────────────────────────

@test "check-wsjf-arithmetic: exits 2 when the problems dir is missing" {
  run bash "$SCRIPT" "$FIXTURE_DIR/does-not-exist"
  [ "$status" -eq 2 ]
}

# ── Clean corpus ────────────────────────────────────────────────────────────

@test "check-wsjf-arithmetic: exits 0 on an empty corpus" {
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
}

@test "check-wsjf-arithmetic: exits 0 when an Open ticket's stored WSJF is correct" {
  # (12 × 1.0) / 2 = 6
  mk_ticket open 101 12 M 6
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
}

@test "check-wsjf-arithmetic: exits 0 when a Known Error's stored WSJF is correct" {
  # (12 × 2.0) / 2 = 12
  mk_ticket known-error 102 12 M 12
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
}

@test "check-wsjf-arithmetic: tolerates 6 vs 6.0 formatting of the same value" {
  mk_ticket open 103 12 M 6.0
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
}

# ── The P477 defect ─────────────────────────────────────────────────────────
#
# This is the regression the fix exists for. A ticket transitioned Open →
# Known Error whose WSJF was computed before the transition keeps the 1.0
# multiplier, so the stored value is exactly half the correct one.

@test "check-wsjf-arithmetic: catches a Known Error carrying the stale Open multiplier" {
  # Stored (12 × 1.0) / 2 = 6; correct post-transition (12 × 2.0) / 2 = 12.
  mk_ticket known-error 104 12 M 6
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"P104"* ]]
  [[ "$output" == *"stated=6"* ]]
  [[ "$output" == *"computed=12"* ]]
}

@test "check-wsjf-arithmetic: catches the partial recompute (Effort re-rated, multiplier not)" {
  # The downstream P121 shape: Effort M → L applied, multiplier left at
  # 1.0. Stored (12 × 1.0) / 4 = 3; correct (12 × 2.0) / 4 = 6.
  mk_ticket known-error 105 12 L 3
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"computed=6"* ]]
}

@test "check-wsjf-arithmetic: passes the cancelling recompute (M to L alongside the transition)" {
  # Effort M → L doubles the divisor while Open → Known Error doubles the
  # multiplier, so a correct full recompute leaves the number unchanged.
  # That must NOT be reported — it looks like a no-op but is right.
  mk_ticket known-error 106 12 L 6
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
}

# ── Effort divisor coverage ─────────────────────────────────────────────────

@test "check-wsjf-arithmetic: applies the S/M/L/XL divisors 1/2/4/8" {
  mk_ticket open 111 8 S 8    # (8 × 1) / 1
  mk_ticket open 112 8 M 4    # (8 × 1) / 2
  mk_ticket open 113 8 L 2    # (8 × 1) / 4
  mk_ticket open 114 8 XL 1   # (8 × 1) / 8
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
}

@test "check-wsjf-arithmetic: does not read XL as L" {
  # An XL ticket scored as if L would store (8 × 1) / 4 = 2, not 1.
  mk_ticket open 115 8 XL 2
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"computed=1"* ]]
}

# ── ADR-022 exclusions ──────────────────────────────────────────────────────

@test "check-wsjf-arithmetic: ignores Verification Pending and Parked tickets" {
  # Multiplier 0 and excluded from dev ranking per ADR-022 — whatever
  # WSJF they carry is not this check's business.
  mk_ticket verifying 121 12 M 999
  mk_ticket parked 122 12 M 999
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
}

# ── Dual-tolerant layout (RFC-002 migration window) ─────────────────────────

@test "check-wsjf-arithmetic: checks the flat layout as well as per-state subdirs" {
  cat > "$FIXTURE_DIR/131-flat-fixture.known-error.md" <<'EOF'
# Problem 131: Flat-layout fixture

**Status**: Known Error
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4
**Effort**: M — fixture
**WSJF**: 6 — fixture
EOF
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"P131"* ]]
}

# ── Adopter tolerance ───────────────────────────────────────────────────────

@test "check-wsjf-arithmetic: skips tickets missing an input field instead of flagging them" {
  # A legacy ticket with no WSJF line is unrateable here, not wrong. An
  # adopter upgrading into this check must not see their whole corpus
  # reported as broken.
  cat > "$FIXTURE_DIR/open/141-legacy-fixture.md" <<'EOF'
# Problem 141: Legacy fixture

**Status**: Open
**Priority**: 12 (High)
EOF
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" != *"P141"* ]]
}

@test "check-wsjf-arithmetic: reports the skipped count on stderr, not stdout" {
  cat > "$FIXTURE_DIR/open/142-legacy-fixture.md" <<'EOF'
# Problem 142: Legacy fixture

**Status**: Open
**Priority**: 12 (High)
EOF
  run bash -c "bash '$SCRIPT' '$FIXTURE_DIR' 2>/dev/null"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ── Output shape ────────────────────────────────────────────────────────────

@test "check-wsjf-arithmetic: each report row stays within the ADR-038 150-byte budget" {
  mk_ticket known-error 151 12 M 6
  mk_ticket known-error 152 20 L 5
  run bash -c "bash '$SCRIPT' '$FIXTURE_DIR' 2>/dev/null"
  [ "$status" -eq 1 ]
  while IFS= read -r line; do
    [ "${#line}" -le 150 ]
  done <<< "$output"
}

@test "check-wsjf-arithmetic: reports rows in stable ID order" {
  mk_ticket known-error 163 12 M 6
  mk_ticket known-error 161 12 M 6
  mk_ticket known-error 162 12 M 6
  run bash -c "bash '$SCRIPT' '$FIXTURE_DIR' 2>/dev/null"
  [ "$status" -eq 1 ]
  [ "$(printf '%s\n' "$output" | grep -oE 'P16[123]' | tr '\n' ' ')" = "P161 P162 P163 " ]
}

# ── Read-only ───────────────────────────────────────────────────────────────

@test "check-wsjf-arithmetic: does not mutate the tickets it reads" {
  mk_ticket known-error 171 12 M 6
  before="$(cat "$FIXTURE_DIR/known-error/171-fixture-ticket.md")"
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 1 ]
  [ "$(cat "$FIXTURE_DIR/known-error/171-fixture-ticket.md")" = "$before" ]
}
