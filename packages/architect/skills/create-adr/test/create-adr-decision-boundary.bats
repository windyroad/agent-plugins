#!/usr/bin/env bats
# Doc-lint guard: create-adr SKILL.md must include a decision-boundary
# analysis step for new ADR creation.
#
# Structural assertion — Permitted Exception to the source-grep ban (ADR-005 / P011).
# These tests assert that the skill specification document conforms to the
# decision-boundary splitting contract introduced by P017.
#
# Cross-reference:
#   P017: docs/problems/017-create-adr-should-split-multi-decision-records.open.md
#   ADR-013: docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md
#   Sibling: packages/itil/skills/manage-problem/test/manage-problem-concern-boundary.bats (P016)
#   @jtbd JTBD-001 (enforce governance without slowing down)
#   @jtbd JTBD-101 (extend the suite with clear patterns)

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

@test "SKILL.md includes a decision-boundary analysis step for new ADR creation" {
  # P017: Before writing an ADR file, the skill must check whether the input
  # contains multiple distinct decisions, and offer to split if it does.
  # Conflated ADRs damage auditability and block independent status transitions.
  run grep -in "decision.boundary\|decision-boundary\|decision boundary\|boundary.*decision\|split.*decision\|multi.decision\|single.*decision\|distinct.*decision\|decision.*distinct" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md decision-boundary step uses AskUserQuestion for split decision (ADR-013)" {
  # ADR-013 Rule 1: all branch points must use AskUserQuestion, not prose options.
  # The "split into separate ADRs" option must be presented via AskUserQuestion.
  # Match: AskUserQuestion appearing in context of "split" ADR instruction.
  run grep -in "Split into separate\|split into.*ADR\|ADR.*split\|split.*ADR" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md decision-boundary step specifies non-interactive auto-split fallback" {
  # ADR-013 Rule 6: non-interactive fail-safe — when AskUserQuestion is unavailable,
  # the skill must auto-split (not block/hang) for creation workflows.
  run grep -in "auto.split\|automatically split" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md decision-boundary step is scoped to new ADR creation (not supersession)" {
  # P017 fix must only fire during new ADR creation, not during supersession handling.
  # Checks for explicit scope language excluding supersession from the boundary check.
  run grep -in "not.*supersession\|supersession.*not\|new ADR creation only\|creation only\|does not apply.*supersession\|Scoped to" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
