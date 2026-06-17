#!/usr/bin/env bats
#
# packages/retrospective/scripts/test/check-autocreate-rfc-scope.bats
#
# Behavioural tests for `check-autocreate-rfc-scope.sh` — the ADR-073
# auto-create-RFC reassessment advisory (RFC-005 B9). The detector scans
# docs/rfcs/*.proposed.md for skeleton (capture-rfc placeholder-scope) RFCs
# whose `problems:` trace a fix-shipped problem — the "auto-created RFC
# under-scoped" signal ADR-073's Reassessment Criteria names. run-retro
# Step 2b surfaces the candidates so a human can assess whether auto-created
# RFCs are systematically under-scoped.
#
# Tests are behavioural per ADR-005 / ADR-052 / P081 — they exercise the
# script end-to-end against fixture docs/rfcs + docs/problems trees and
# assert on stdout / exit-code shape. No structural greps of the script
# source. Mirrors the sibling `check-readme-jtbd-currency.bats`.
#
# @problem P314 (rework the fix-time RFC-trace gate — RFC-005 B9 wires the
#               ADR-073 reassessment criterion into run-retro Step 2b)
# @problem P081 (Structural-content tests are wasteful — behavioural preferred)
# @adr ADR-073 (fix-time gate auto-creates a missing RFC; Reassessment
#               Criteria: revisit if auto-created RFCs systematically under-scoped)
# @adr ADR-013 Rule 6 (non-interactive fail-safe — advisory script never blocks)
# @adr ADR-040 (declarative-first / advisory-then-escalate precedent)
# @adr ADR-005 / ADR-052 (behavioural tests via bats)

SCRIPT="${BATS_TEST_DIRNAME}/../check-autocreate-rfc-scope.sh"

# The capture-rfc skeleton placeholder string (em-dash is U+2014, matching
# capture-rfc/SKILL.md and the live RFC-026 skeleton).
PLACEHOLDER='(deferred — populate at /wr-itil:manage-rfc accepted transition)'

setup() {
  TEST_DIR="$(mktemp -d)"
  RFCS_DIR="$TEST_DIR/rfcs"
  PROBLEMS_DIR="$TEST_DIR/problems"
  mkdir -p "$RFCS_DIR" "$PROBLEMS_DIR"
}

teardown() {
  rm -rf "$TEST_DIR"
}

# Write a proposed RFC. $1 = filename, $2 = problems-csv (e.g. "P361"),
# $3 = scope-body (use $PLACEHOLDER for a skeleton).
make_rfc() {
  local fname="$1" probs="$2" scope="$3"
  cat > "$RFCS_DIR/$fname" <<EOF
---
status: proposed
human-oversight: unconfirmed
problems: [$probs]
---

# $fname

## Scope

$scope

## Tasks

- [ ] $PLACEHOLDER
EOF
}

# Write a problem ticket under a lifecycle subdir. $1 = subdir, $2 = num,
# $3 = body.
make_problem() {
  local sub="$1" num="$2" body="$3"
  mkdir -p "$PROBLEMS_DIR/$sub"
  cat > "$PROBLEMS_DIR/$sub/$num-stub.md" <<EOF
# P$num stub ticket

$body
EOF
}

# ── Pre-checks ──────────────────────────────────────────────────────────────

@test "script file exists and is executable" {
  [ -f "$SCRIPT" ]
  [ -x "$SCRIPT" ]
}

@test "missing rfcs dir exits 2 with error message on stderr" {
  run bash "$SCRIPT" "$TEST_DIR/does-not-exist" "$PROBLEMS_DIR"
  [ "$status" -eq 2 ]
  [[ "$output" == *"rfcs dir not found"* ]]
}

@test "empty rfcs dir exits 0 with a zeroed TOTAL summary" {
  run bash "$SCRIPT" "$RFCS_DIR" "$PROBLEMS_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"TOTAL proposed_skeletons=0 under_scoped=0"* ]]
}

# ── Regression anchor: the P361/RFC-026 gate-on-next-touch shape ─────────────
# A known-error-located problem whose fix is recorded as a populated
# `## Fix Strategy` (NO `## Fix Released` heading), traced by a
# placeholder-scope RFC. The original (pre-review) predicate missed this.

@test "known-error problem with populated Fix Strategy (no Fix Released) is under-scoped" {
  make_problem "known-error" "361" "## Fix Strategy

Implemented in \`packages/itil/scripts/derive-release-vehicle.sh\`. Full 15-test suite green; de-facto-released exit-0 branch added."
  make_rfc "RFC-026-stub.proposed.md" "P361" "$PLACEHOLDER"

  run bash "$SCRIPT" "$RFCS_DIR" "$PROBLEMS_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"AUTOCREATE-RFC under-scoped rfc=RFC-026"* ]]
  [[ "$output" == *"problems=P361"* ]]
  [[ "$output" == *"shipped=P361:fix-strategy"* ]]
  [[ "$output" == *"TOTAL proposed_skeletons=1 under_scoped=1"* ]]
}

# ── verifying/ lifecycle-directory basis (the P215/RFC-021 shape) ───────────

@test "skeleton RFC tracing a verifying/ problem is under-scoped (directory basis)" {
  make_problem "verifying" "215" "## Fix Strategy

Recovery directive added to the architect gate."
  make_rfc "RFC-021-stub.proposed.md" "P215" "$PLACEHOLDER"

  run bash "$SCRIPT" "$RFCS_DIR" "$PROBLEMS_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"AUTOCREATE-RFC under-scoped rfc=RFC-021"* ]]
  [[ "$output" == *"shipped=P215:verifying"* ]]
  [[ "$output" == *"TOTAL proposed_skeletons=1 under_scoped=1"* ]]
}

# ── Fix Released heading basis ──────────────────────────────────────────────

@test "skeleton RFC tracing a problem with a Fix Released heading is under-scoped" {
  make_problem "known-error" "500" "## Fix Released

Shipped in @windyroad/itil@1.2.3."
  make_rfc "RFC-050-stub.proposed.md" "P500" "$PLACEHOLDER"

  run bash "$SCRIPT" "$RFCS_DIR" "$PROBLEMS_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"AUTOCREATE-RFC under-scoped rfc=RFC-050"* ]]
  [[ "$output" == *"shipped=P500:fix-released"* ]]
}

# ── Non-candidate: skeleton RFC tracing an open, no-fix problem ──────────────
# A legitimately-still-skeleton RFC — the fix has not been scoped yet, so the
# RFC SHOULD still be a skeleton. Counted in proposed_skeletons, NOT under_scoped.

@test "skeleton RFC tracing an open problem with no fix is NOT under-scoped" {
  make_problem "open" "304" "## Symptoms

Duplicate-and-sync is fragile. No fix proposed yet."
  make_rfc "RFC-023-stub.proposed.md" "P304" "$PLACEHOLDER"

  run bash "$SCRIPT" "$RFCS_DIR" "$PROBLEMS_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" != *"rfc=RFC-023"* ]]
  [[ "$output" == *"TOTAL proposed_skeletons=1 under_scoped=0"* ]]
}

# ── Robustness: a bare/empty Fix Strategy heading is NOT populated ──────────
# (architect note — distinguish a populated section from a stub heading.)

@test "skeleton RFC tracing a problem with an EMPTY Fix Strategy heading is NOT under-scoped" {
  make_problem "known-error" "600" "## Fix Strategy

## Root Cause Analysis

Some analysis."
  make_rfc "RFC-060-stub.proposed.md" "P600" "$PLACEHOLDER"

  run bash "$SCRIPT" "$RFCS_DIR" "$PROBLEMS_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" != *"rfc=RFC-060"* ]]
  [[ "$output" == *"TOTAL proposed_skeletons=1 under_scoped=0"* ]]
}

# ── Non-candidate: a fleshed-out (non-skeleton) RFC is never counted ─────────

@test "non-skeleton RFC (Scope fleshed out) tracing a shipped problem is NOT counted" {
  make_problem "closed" "700" "## Fix Strategy

Done and shipped."
  make_rfc "RFC-070-stub.proposed.md" "P700" "This RFC has a real scope paragraph describing the change."

  run bash "$SCRIPT" "$RFCS_DIR" "$PROBLEMS_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" != *"rfc=RFC-070"* ]]
  [[ "$output" == *"TOTAL proposed_skeletons=0 under_scoped=0"* ]]
}

# ── closed/ lifecycle-directory basis ───────────────────────────────────────

@test "skeleton RFC tracing a closed/ problem is under-scoped (directory basis)" {
  make_problem "closed" "800" "## Fix Strategy

Resolved and verified."
  make_rfc "RFC-080-stub.proposed.md" "P800" "$PLACEHOLDER"

  run bash "$SCRIPT" "$RFCS_DIR" "$PROBLEMS_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"AUTOCREATE-RFC under-scoped rfc=RFC-080"* ]]
  [[ "$output" == *"shipped=P800:closed"* ]]
}

# ── Multi-RFC aggregation + TOTAL summary ───────────────────────────────────

@test "multi-RFC aggregation: one candidate line per under-scoped skeleton + TOTAL" {
  # under-scoped (known-error + Fix Strategy)
  make_problem "known-error" "361" "## Fix Strategy

Shipped."
  make_rfc "RFC-026-stub.proposed.md" "P361" "$PLACEHOLDER"
  # under-scoped (verifying)
  make_problem "verifying" "215" "## Fix Strategy

Shipped."
  make_rfc "RFC-021-stub.proposed.md" "P215" "$PLACEHOLDER"
  # legitimately-skeleton (open, no fix)
  make_problem "open" "304" "## Symptoms

No fix yet."
  make_rfc "RFC-023-stub.proposed.md" "P304" "$PLACEHOLDER"

  run bash "$SCRIPT" "$RFCS_DIR" "$PROBLEMS_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"rfc=RFC-026"* ]]
  [[ "$output" == *"rfc=RFC-021"* ]]
  [[ "$output" != *"rfc=RFC-023"* ]]
  [[ "$output" == *"TOTAL proposed_skeletons=3 under_scoped=2"* ]]
}

# ── Multi-problem trace: any one shipped problem makes the RFC under-scoped ──

@test "skeleton RFC tracing multiple problems is under-scoped if ANY is fix-shipped" {
  make_problem "open" "900" "## Symptoms

No fix."
  make_problem "verifying" "901" "## Fix Strategy

Shipped."
  make_rfc "RFC-090-stub.proposed.md" "P900, P901" "$PLACEHOLDER"

  run bash "$SCRIPT" "$RFCS_DIR" "$PROBLEMS_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"AUTOCREATE-RFC under-scoped rfc=RFC-090"* ]]
  [[ "$output" == *"problems=P900,P901"* ]]
  [[ "$output" == *"shipped=P901:verifying"* ]]
}
