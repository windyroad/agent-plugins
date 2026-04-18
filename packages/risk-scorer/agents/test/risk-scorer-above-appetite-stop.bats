#!/usr/bin/env bats
# Doc-lint guard: risk-scorer agent prompts must contain an explicit
# STOP / do-not-proceed directive in their Above-Appetite sections.
#
# Structural assertions — Permitted Exception to the source-grep ban (ADR-005 / P011).
# These tests assert that the pipeline, wip, and plan scorer prompts forbid
# "Proceed", "Continue", or "You may ship" nudges when cumulative risk
# exceeds appetite.
#
# Background: P037 identified that scorer reports could include "Proceed
# with release" or similar nudge language even when residual risk exceeded
# appetite. The hook gate then correctly blocked the action, but only after
# the agent wasted tool calls and tokens acting on the nudge. The scorer
# is not the primary decision-maker, but its verbal verdict must match the
# structured score — ambiguous "proceed" language undermines this.
#
# The Below-Appetite Output Rule (ADR-013 Rule 5) already requires silent
# policy-authorised release when all scores are within appetite. This guard
# enforces the inverse: an explicit STOP directive above appetite.
#
# Cross-reference:
#   P037:    docs/problems/037-risk-scorer-proceeds-above-appetite.open.md
#   ADR-013: docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md
#   @jtbd JTBD-001 (enforce governance without slowing down)
#   @jtbd JTBD-002 (ship with confidence — verbal verdict must match structured score)
#   @jtbd JTBD-202 (pre-flight governance — structured output is the only sanctioned channel)

setup() {
  AGENTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  PIPELINE="${AGENTS_DIR}/pipeline.md"
  WIP="${AGENTS_DIR}/wip.md"
  PLAN="${AGENTS_DIR}/plan.md"
}

# ──────────────────────────────────────────────────────────────────────────────
# pipeline.md: Above-Appetite STOP directive
# ──────────────────────────────────────────────────────────────────────────────

@test "pipeline.md Above-Appetite section contains explicit STOP directive" {
  # Must contain the word STOP (or BLOCKED) as the verdict above appetite.
  run grep -qE "STOP|BLOCKED" "$PIPELINE"
  [ "$status" -eq 0 ]
}

@test "pipeline.md Above-Appetite section forbids Proceed nudges" {
  # Must explicitly forbid emitting "Proceed" / "Continue" nudges
  # when risk exceeds appetite.
  run grep -qE "[Dd]o NOT emit.*Proceed|forbid.*Proceed|not emit.*Continue|must not.*proceed" "$PIPELINE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# wip.md: Above-Appetite STOP directive
# ──────────────────────────────────────────────────────────────────────────────

@test "wip.md Above-Appetite section contains explicit STOP directive" {
  # PAUSE is the wip-mode verdict equivalent of STOP.
  run grep -qE "STOP|BLOCKED|PAUSE" "$WIP"
  [ "$status" -eq 0 ]
}

@test "wip.md Above-Appetite section forbids Proceed nudges" {
  run grep -qE "[Dd]o NOT emit.*Proceed|forbid.*Proceed|not emit.*Continue|must not.*proceed" "$WIP"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# plan.md: FAIL directive (plan-mode equivalent of STOP)
# ──────────────────────────────────────────────────────────────────────────────

@test "plan.md FAIL section contains explicit STOP directive" {
  # FAIL is the plan-mode verdict; reinforces STOP language.
  run grep -qE "STOP|BLOCKED|FAIL" "$PLAN"
  [ "$status" -eq 0 ]
}

@test "plan.md FAIL section forbids Proceed nudges" {
  run grep -qE "[Dd]o NOT emit.*Proceed|forbid.*Proceed|not emit.*Continue|must not.*proceed" "$PLAN"
  [ "$status" -eq 0 ]
}
