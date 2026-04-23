#!/usr/bin/env bats
# Doc-lint guard: risk-scorer agent prompts must define a structured
# machine-readable RISK_REMEDIATIONS block with the full 5-column format.
#
# Structural assertions — Permitted Exception to the source-grep ban (ADR-005 / P011).
# These tests assert that agent specification documents conform to the
# structured-interaction contract (ADR-013) and the machine-readable format
# required by P021.
#
# Background: P021 identified that above-appetite risk-scorer output used
# free-text "Your call:" prose. The fix defined a structured RISK_REMEDIATIONS:
# block. This test guards that all three scoring modes (pipeline, wip, plan)
# define the block AND include the full 5-column format so calling skills
# can render structured option prompts with effort and risk-delta context.
#
# Cross-reference:
#   ADR-013: docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md
#   P021:    docs/problems/021-governance-skill-structured-prompts.known-error.md
#   @jtbd JTBD-001 (enforce governance without slowing down)
#   @jtbd JTBD-002 (ship with confidence — structured remediations are auditable)

setup() {
  AGENTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  PIPELINE="${AGENTS_DIR}/pipeline.md"
  WIP="${AGENTS_DIR}/wip.md"
  PLAN="${AGENTS_DIR}/plan.md"
}

# ──────────────────────────────────────────────────────────────────────────────
# pipeline.md: above-appetite structured output
# ──────────────────────────────────────────────────────────────────────────────

@test "pipeline.md defines RISK_REMEDIATIONS block" {
  # Must emit a structured block, not free-text, above appetite (ADR-013 Rule 1).
  run grep -q "RISK_REMEDIATIONS:" "$PIPELINE"
  [ "$status" -eq 0 ]
}

@test "pipeline.md RISK_REMEDIATIONS format includes effort column" {
  # 5-column format: id | description | effort (S/M/L) | risk_delta (-N) | files_touched
  # This column allows calling skills to size each remediation and present
  # a structured AskUserQuestion with effort context.
  run grep -q "effort" "$PIPELINE"
  [ "$status" -eq 0 ]
}

@test "pipeline.md RISK_REMEDIATIONS format includes risk_delta column" {
  # risk_delta lets calling skills show how much each remediation reduces score.
  run grep -q "risk_delta" "$PIPELINE"
  [ "$status" -eq 0 ]
}

@test "pipeline.md defines Below-Appetite Output Rule" {
  # Below appetite: silent pass, no advisory prose (ADR-013 Rule 5).
  run grep -q "Below-Appetite" "$PIPELINE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# wip.md: above-appetite structured output
# ──────────────────────────────────────────────────────────────────────────────

@test "wip.md defines RISK_REMEDIATIONS block" {
  run grep -q "RISK_REMEDIATIONS:" "$WIP"
  [ "$status" -eq 0 ]
}

@test "wip.md RISK_REMEDIATIONS format includes effort column" {
  run grep -q "effort" "$WIP"
  [ "$status" -eq 0 ]
}

@test "wip.md RISK_REMEDIATIONS format includes risk_delta column" {
  run grep -q "risk_delta" "$WIP"
  [ "$status" -eq 0 ]
}

@test "wip.md defines Below-Appetite Rule" {
  run grep -q "Below-Appetite" "$WIP"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# plan.md: FAIL-verdict structured output
# ──────────────────────────────────────────────────────────────────────────────

@test "plan.md defines RISK_REMEDIATIONS block" {
  run grep -q "RISK_REMEDIATIONS:" "$PLAN"
  [ "$status" -eq 0 ]
}

@test "plan.md RISK_REMEDIATIONS format includes effort column" {
  run grep -q "effort" "$PLAN"
  [ "$status" -eq 0 ]
}

@test "plan.md RISK_REMEDIATIONS format includes risk_delta column" {
  run grep -q "risk_delta" "$PLAN"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# P108: scorer writes prose descriptions; agent decides (ADR-042 Rule 2a)
# ──────────────────────────────────────────────────────────────────────────────

@test "pipeline.md RISK_REMEDIATIONS format has no action_class column" {
  # ADR-042 Rule 2a: no structured action_class column. The agent reads
  # the description and decides.
  run grep -q "action_class" "$PIPELINE"
  [ "$status" -ne 0 ]
}

@test "wip.md RISK_REMEDIATIONS format has no action_class column" {
  run grep -q "action_class" "$WIP"
  [ "$status" -ne 0 ]
}

@test "plan.md RISK_REMEDIATIONS format has no action_class column" {
  run grep -q "action_class" "$PLAN"
  [ "$status" -ne 0 ]
}
