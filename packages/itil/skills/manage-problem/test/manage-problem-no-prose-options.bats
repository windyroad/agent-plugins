#!/usr/bin/env bats
# Doc-lint guard: manage-problem SKILL.md must not contain prose option prompts.
#
# Structural assertion — Permitted Exception to the source-grep ban (ADR-005 / P011).
# These tests do not assert hook behaviour; they assert that the skill specification
# document conforms to the structured-interaction contract.
#
# Cross-reference:
#   ADR-013 Confirmation criterion (docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md)
#   P021 investigation task: "add a BATS or doc-lint test that fails if the skill contains prose option patterns"
#   @jtbd JTBD-001 (enforce governance without slowing down)
#   @jtbd JTBD-101 (extend the suite with clear patterns)

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

@test "SKILL.md exists and has frontmatter" {
  [ -f "$SKILL_FILE" ]
  run head -1 "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [ "$output" = "---" ]
}

@test "SKILL.md does not contain 'Your call:' prose option prompt" {
  # ADR-013 Rule 1: all decision branch points must use AskUserQuestion, not prose.
  # 'Your call:' is the canonical unstructured prompt observed in P021 (risk-scorer image #3).
  run grep -n "Your call:" "$SKILL_FILE"
  [ "$status" -ne 0 ]   # grep exits 1 when no match — that IS the pass condition
}

@test "SKILL.md does not contain freestanding 'Options: (a)' prose list" {
  # ADR-013 Rule 1: prose option lists must not appear as skill instructions.
  # Pattern: 'Options: (a)' as an instruction to Claude to present unstructured choices.
  # Note: 'Would you like to: (a)' in AskUserQuestion examples is a different pattern
  # and is NOT matched by this assertion.
  run grep -n "Options: (a)" "$SKILL_FILE"
  [ "$status" -ne 0 ]
}

@test "SKILL.md does not contain 'which way?' prose branch prompt" {
  # ADR-013 Confirmation criterion lists 'which way?' as a prohibited prose prompt.
  run grep -n "which way?" "$SKILL_FILE"
  [ "$status" -ne 0 ]
}

@test "SKILL.md mandates AskUserQuestion for work-next selection (WSJF tie-break)" {
  # ADR-013 Rule 1: the step 9c work-selection branch must use AskUserQuestion,
  # not a prose '(a)/(b)/(c)' list. This is a regression guard — if step 9c is
  # edited and the AskUserQuestion mandate is removed, this test catches it.
  # P021 investigation task: manage-problem WSJF tie → assert AskUserQuestion.
  run grep -n "AskUserQuestion" "$SKILL_FILE"
  [ "$status" -eq 0 ]   # file MUST reference AskUserQuestion
}

@test "SKILL.md mandates AskUserQuestion for scope-change decisions during work" {
  # ADR-013 Rule 1: the 'Scope expansion during work' branch must use AskUserQuestion.
  # 'Scope change' is the header text used in the AskUserQuestion call for scope decisions
  # (per P021 amendment). Regression guard.
  run grep -n "Scope change" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
