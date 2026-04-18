#!/usr/bin/env bats
# Doc-lint guard: manage-problem SKILL.md must include a concern-boundary
# analysis step for new problem creation.
#
# Structural assertion — Permitted Exception to the source-grep ban (ADR-005 / P011).
# These tests assert that the skill specification document conforms to the
# concern-boundary splitting contract introduced by P016.
#
# Cross-reference:
#   P016: docs/problems/016-manage-problem-should-split-multi-concern-tickets.open.md
#   ADR-013: docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md
#   @jtbd JTBD-001 (enforce governance without slowing down)
#   @jtbd JTBD-101 (extend the suite with clear patterns)

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

@test "SKILL.md includes a concern-boundary analysis step for new problem creation" {
  # P016: Before writing a problem file (step 5), the skill must check whether
  # the description contains multiple distinct root causes or concerns, and offer
  # to split if it does. This guards against conflated tickets that make WSJF
  # scoring meaningless.
  run grep -in "concern.boundary\|concern-boundary\|concern boundary\|boundary.*concern\|split.*concern\|multi.concern\|single.*concern" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md concern-boundary step uses AskUserQuestion, not prose (ADR-013)" {
  # ADR-013 Rule 1: all branch points must use AskUserQuestion, not prose options.
  # The concern-boundary split decision (split vs keep as one) is a branch point
  # and must be handled with a structured AskUserQuestion call, not a
  # '(a) split (b) keep' prose paragraph.
  # This test verifies the split prompt references AskUserQuestion (not just that
  # AskUserQuestion appears anywhere — the no-prose-options.bats test covers that).
  run grep -n "concern.boundary\|concern-boundary\|concern boundary\|split.*concern\|multi.concern" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  # The split decision must direct the skill to use AskUserQuestion
  run grep -in "split.*AskUserQuestion\|AskUserQuestion.*split\|split.*question\|question.*split\|split.*ask\|concern.*AskUserQuestion\|AskUserQuestion.*concern" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md concern-boundary step is scoped to new problem creation (not updates)" {
  # P016 fix must only fire during new problem creation (between steps 4 and 5),
  # not during updates or transitions. Scope constraint prevents spurious split
  # prompts on existing tickets being updated or transitioned.
  # This checks that the concern-boundary step is placed in the 'new problems'
  # section (steps 2-5), not in the update or transition sections.
  run grep -n "For new problems\|new problem" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  # The concern-boundary check must appear in the new-problems workflow context
  run grep -A5 -i "concern.boundary\|concern-boundary\|concern boundary\|multi.concern\|split.*concern" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md concern-boundary step specifies non-interactive fallback with auto-split" {
  # ADR-013 Rule 6: non-interactive fail-safe — when AskUserQuestion is unavailable,
  # the skill must auto-split rather than hanging or silently dropping the split.
  # This specifically requires "auto-split" or "automatically split" language in
  # the concern-boundary step, not just general "AskUserQuestion unavailable" text
  # which already exists for the commit step (step 11).
  run grep -in "auto.split\|automatically split" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
