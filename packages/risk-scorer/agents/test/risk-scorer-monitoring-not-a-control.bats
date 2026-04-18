#!/usr/bin/env bats
# Doc-lint guard: risk-scorer agent prompts must explicitly state that
# monitoring, alerting, and other post-release detection activities are
# NOT controls and MUST NOT be credited against residual risk.
#
# Structural assertions — Permitted Exception to the source-grep ban (ADR-005 / P011).
#
# Background: P038 identified that scorer reports were crediting
# "monitor for elevated errors", "be ready to rollback", and similar
# post-release detection activities as controls that reduced residual
# risk. These activities help detect failures after they occur — they
# are incident response, not release-gate risk reduction. Crediting
# them creates false confidence in risky releases.
#
# A genuine control exercises the failure scenario BEFORE the change
# ships (tests, CI gates, feature flags, preview verification, architect
# review). Monitoring shortens detection time; it does not prevent the
# failure from reaching users.
#
# Cross-reference:
#   P038:    docs/problems/038-risk-scorer-suggests-monitoring-as-control.open.md
#   ADR-013: docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md
#   @jtbd JTBD-001 (enforce governance — control list must reflect actual prevention)
#   @jtbd JTBD-002 (ship with confidence — no false-confidence releases)
#   @jtbd JTBD-202 (pre-flight governance — scorer must distinguish prevention from detection)

setup() {
  AGENTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  PIPELINE="${AGENTS_DIR}/pipeline.md"
  WIP="${AGENTS_DIR}/wip.md"
  PLAN="${AGENTS_DIR}/plan.md"
}

# ──────────────────────────────────────────────────────────────────────────────
# pipeline.md
# ──────────────────────────────────────────────────────────────────────────────

@test "pipeline.md states monitoring is not a control" {
  run grep -qE "[Mm]onitoring is (not|NOT) a control|[Mm]onitoring.*MUST NOT.*credit" "$PIPELINE"
  [ "$status" -eq 0 ]
}

@test "pipeline.md forbids crediting post-release detection as risk reduction" {
  # Post-release detection activities (monitoring, alerting, rollback readiness)
  # must not reduce residual risk.
  run grep -qE "post-release.*(not|NOT) (reduce|control|credit)|detection.*(not|NOT) (reduce|prevention)" "$PIPELINE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# wip.md
# ──────────────────────────────────────────────────────────────────────────────

@test "wip.md states monitoring is not a control" {
  run grep -qE "[Mm]onitoring is (not|NOT) a control|[Mm]onitoring.*MUST NOT.*credit" "$WIP"
  [ "$status" -eq 0 ]
}

@test "wip.md forbids crediting post-release detection as risk reduction" {
  run grep -qE "post-release.*(not|NOT) (reduce|control|credit)|detection.*(not|NOT) (reduce|prevention)" "$WIP"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# plan.md
# ──────────────────────────────────────────────────────────────────────────────

@test "plan.md states monitoring is not a control" {
  run grep -qE "[Mm]onitoring is (not|NOT) a control|[Mm]onitoring.*MUST NOT.*credit" "$PLAN"
  [ "$status" -eq 0 ]
}

@test "plan.md forbids crediting post-release detection as risk reduction" {
  run grep -qE "post-release.*(not|NOT) (reduce|control|credit)|detection.*(not|NOT) (reduce|prevention)" "$PLAN"
  [ "$status" -eq 0 ]
}
