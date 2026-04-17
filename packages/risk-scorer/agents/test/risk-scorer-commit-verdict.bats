#!/usr/bin/env bats
# Doc-lint guard: wip.md and assess-wip SKILL.md must define the
# RISK_VERDICT: COMMIT extension per ADR-016.
#
# Structural assertion — Permitted Exception to the source-grep ban (ADR-005 / P011).
# These tests assert that the agent and skill specification documents conform to
# the COMMIT verdict contract introduced by P024 / ADR-016.
#
# Cross-reference:
#   P024: docs/problems/024-risk-scorer-wip-flag-uncommitted-completed-work.open.md
#   ADR-016: docs/decisions/016-wip-verdict-commit-for-completed-governance-work.proposed.md
#   ADR-013: docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md
#   @jtbd JTBD-002 (ship with confidence)
#   @jtbd JTBD-001 (enforce governance without slowing down)

setup() {
  AGENTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  WIP_FILE="${AGENTS_DIR}/wip.md"
  SKILL_DIR="$(cd "${AGENTS_DIR}/../skills/assess-wip" && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

# ──────────────────────────────────────────────────────────────────────────────
# wip.md — COMMIT verdict definition
# ──────────────────────────────────────────────────────────────────────────────

@test "wip.md defines RISK_VERDICT: COMMIT as a third verdict type" {
  # ADR-016 §Verdict Contract: COMMIT is distinct from CONTINUE and PAUSE.
  # The agent prompt must name this verdict so the LLM knows to emit it.
  run grep -n "RISK_VERDICT:.*COMMIT\|RISK_VERDICT: COMMIT" "$WIP_FILE"
  [ "$status" -eq 0 ]
}

@test "wip.md defines RISK_COMMIT_REASON: output field" {
  # ADR-016 §Verdict Contract: COMMIT verdict must include a one-line reason
  # so the calling skill can surface a meaningful message to the user.
  run grep -n "RISK_COMMIT_REASON" "$WIP_FILE"
  [ "$status" -eq 0 ]
}

@test "wip.md defines governance-artefact detection heuristic for COMMIT verdict" {
  # ADR-016 §Detection Heuristic: COMMIT fires only when all uncommitted changes
  # are in governance artefact paths (docs/problems/, packages/*/skills/).
  # This guards against false-positive COMMIT signals on mixed diffs.
  run grep -in "governance.artefact\|governance artefact\|docs/problems\|packages/\*/skills" "$WIP_FILE"
  [ "$status" -eq 0 ]
}

@test "wip.md COMMIT verdict is only emitted when risk is within appetite" {
  # ADR-016 §Detection Heuristic criterion 1: risk must be ≤ 4 for COMMIT to fire.
  # Above-appetite changes must be PAUSE regardless of governance-artefact status.
  # Look for the explicit appetite gate in the COMMIT detection section specifically.
  run grep -in "PAUSE.*governance\|governance.*PAUSE\|appetite.*COMMIT\|COMMIT.*appetite\|COMMIT.*within\|within.*COMMIT" "$WIP_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# assess-wip SKILL.md — COMMIT verdict handling
# ──────────────────────────────────────────────────────────────────────────────

@test "assess-wip SKILL.md handles RISK_VERDICT: COMMIT distinctly from CONTINUE/PAUSE" {
  # ADR-016 §Consequences: assess-wip Step 4 must surface RISK_VERDICT: COMMIT
  # as a prominent suggestion to commit, not treat it the same as CONTINUE.
  run grep -n "COMMIT\|commit.*now\|commit now" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
