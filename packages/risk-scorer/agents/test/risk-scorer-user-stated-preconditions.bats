#!/usr/bin/env bats
# Doc-lint guard: risk-scorer agent prompts must define a User-Stated
# Preconditions Check as a sub-rule of Control Discovery.
#
# Structural assertions — Permitted Exception to the source-grep ban (ADR-005 / P011).
# These tests assert that the pipeline, wip, and plan scorer prompts
# instruct the scorer to detect user-stated conditional-delivery warnings
# and surface unmet preconditions as Risk items.
#
# Background: P041 identified that the risk scorer evaluated technical
# risk of a diff in isolation and missed explicit user-stated warnings
# that a change was conditional on a paired capability. Downstream this
# caused a breaking change to ship to production despite a twice-stated
# user warning. This guard prevents regression of the fix: every scoring
# agent must have a User-Stated Preconditions Check.
#
# Cross-reference:
#   P041:    docs/problems/041-risk-scorer-misses-user-stated-dependencies.known-error.md
#   ADR-013: structured user interaction for governance decisions
#   @jtbd JTBD-002 (ship with confidence — user-stated preconditions are honoured)
#   @jtbd JTBD-202 (pre-flight governance checks surface explicit warnings)

setup() {
  AGENTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  PIPELINE="${AGENTS_DIR}/pipeline.md"
  WIP="${AGENTS_DIR}/wip.md"
  PLAN="${AGENTS_DIR}/plan.md"
}

# ──────────────────────────────────────────────────────────────────────────────
# pipeline.md: user-stated precondition check
# ──────────────────────────────────────────────────────────────────────────────

@test "pipeline.md defines User-Stated Preconditions Check section" {
  run grep -q "User-Stated Preconditions" "$PIPELINE"
  [ "$status" -eq 0 ]
}

@test "pipeline.md precondition check surfaces unmet preconditions as Risk items" {
  # Unmet preconditions must flow through the existing Risk item structure,
  # which feeds RISK_REMEDIATIONS above appetite (>= 5).
  run grep -qE "precondition.*Risk item|Risk item.*precondition" "$PIPELINE"
  [ "$status" -eq 0 ]
}

@test "pipeline.md precondition check credits zero reduction when paired capability is unmet" {
  # Aligns with existing Control Discovery rule: if a control cannot be named,
  # or a stated precondition is unmet, the control provides 0 reduction.
  run grep -qE "zero reduction|0 reduction" "$PIPELINE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# wip.md: user-stated precondition check
# ──────────────────────────────────────────────────────────────────────────────

@test "wip.md defines User-Stated Preconditions Check section" {
  run grep -q "User-Stated Preconditions" "$WIP"
  [ "$status" -eq 0 ]
}

@test "wip.md precondition check surfaces unmet preconditions as Risk items" {
  run grep -qE "precondition.*Risk item|Risk item.*precondition" "$WIP"
  [ "$status" -eq 0 ]
}

@test "wip.md precondition check credits zero reduction when paired capability is unmet" {
  run grep -qE "zero reduction|0 reduction" "$WIP"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# plan.md: user-stated precondition check
# ──────────────────────────────────────────────────────────────────────────────

@test "plan.md defines User-Stated Preconditions Check section" {
  run grep -q "User-Stated Preconditions" "$PLAN"
  [ "$status" -eq 0 ]
}

@test "plan.md precondition check surfaces unmet preconditions as Risk items" {
  run grep -qE "precondition.*Risk item|Risk item.*precondition" "$PLAN"
  [ "$status" -eq 0 ]
}

@test "plan.md precondition check credits zero reduction when paired capability is unmet" {
  run grep -qE "zero reduction|0 reduction" "$PLAN"
  [ "$status" -eq 0 ]
}
