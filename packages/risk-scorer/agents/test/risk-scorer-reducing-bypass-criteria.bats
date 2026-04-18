#!/usr/bin/env bats
# Doc-lint guard: risk-scorer agent prompts must scope the
# `RISK_BYPASS: reducing` label to commits that actually reduce risk.
#
# Structural assertions — Permitted Exception to the source-grep ban (ADR-005 / P011).
#
# Background: P043 analysed 329 risk reports across 6 projects and found
# `RISK_BYPASS: reducing` applied to 97.9% of commits in this repo and
# 79.6% across consumer projects. The scorer treated changeset metadata,
# ADR checkbox ticks, docs-only edits, and genuinely risk-reducing fixes
# all the same way. When nearly every commit is "reducing", the label
# provides no discriminating signal.
#
# The tightened criteria require the commit to:
#   1. Close a problem ticket, OR
#   2. Explicitly remediate a previously-flagged risk, OR
#   3. Remove a documented risk
# Ordinary docs-only or test-only commits that don't meet one of these
# conditions are risk-neutral — no bypass label.
#
# Cross-reference:
#   P043:    docs/problems/043-risk-bypass-reducing-lost-discriminating-power.open.md
#   ADR-013: docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md
#   @jtbd JTBD-001 (enforce governance — bypass must reflect real risk reduction)
#   @jtbd JTBD-202 (pre-flight governance — bypass label must be auditable)

setup() {
  AGENTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  PIPELINE="${AGENTS_DIR}/pipeline.md"
}

# NOTE: wip.md is intentionally excluded from these assertions — wip-mode emits
# RISK_VERDICT: CONTINUE/PAUSE, not RISK_BYPASS labels. Bypass criteria apply
# only to the pipeline (commit/push/release) scorer.

# ──────────────────────────────────────────────────────────────────────────────
# pipeline.md: tightened reducing criteria
# ──────────────────────────────────────────────────────────────────────────────

@test "pipeline.md reducing bypass requires closing a ticket" {
  # Must reference ticket closure as a valid trigger for reducing bypass.
  run grep -qE "[Cc]lose[sd]?.*ticket|[Cc]loses P[0-9]|problem.*close" "$PIPELINE"
  [ "$status" -eq 0 ]
}

@test "pipeline.md reducing bypass requires remediating a flagged risk" {
  run grep -qE "remediate.*risk|remediates.*risk|flagged risk" "$PIPELINE"
  [ "$status" -eq 0 ]
}

@test "pipeline.md reducing bypass excludes docs-only neutral commits" {
  # Ordinary docs/test commits without ticket closure must NOT earn the bypass.
  run grep -qE "docs-only.*neutral|test-only.*neutral|ordinary.*neutral|neutral.*no bypass" "$PIPELINE"
  [ "$status" -eq 0 ]
}

@test "pipeline.md requires audit reason for reducing bypass" {
  # Audit trail: cite which ticket closed, which risk remediated, etc.
  run grep -qE "RISK_BYPASS_REASON|cite.*ticket|reason.*bypass|bypass.*reason" "$PIPELINE"
  [ "$status" -eq 0 ]
}

