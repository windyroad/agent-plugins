#!/usr/bin/env bats

# P122: work-problems Step 2.5 stop-condition #2 routing must default to
# AskUserQuestion (interactive) and use the table emit only as the
# AskUserQuestion-unavailable fallback. The "non-interactive default for
# this skill" prose was wrong-by-design — JTBD-006 (AFK persona) is served
# by the iteration subprocess workers, not by suppressing AskUserQuestion
# at the orchestrator's main turn (which is interactive by construction).
#
# Doc-lint contract assertions per ADR-037 Permitted Exception (structural
# checks on prose contract, not behavioural coverage).

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SKILL_MD="$REPO_ROOT/packages/itil/skills/work-problems/SKILL.md"
}

@test "work-problems P122: SKILL.md exists" {
  [ -f "$SKILL_MD" ]
}

@test "work-problems P122: Step 2.5 removes the legacy AFK-as-default prose" {
  # The flipped default — the legacy "non-interactive path the default
  # for this skill" prose at Step 2.5 must be gone. (Note: Step 0's
  # session-continuity AFK branch intentionally retains its own AFK
  # default for a different reason; this test is scoped to Step 2.5's
  # specific phrasing only.)
  run grep -F 'non-interactive path the default for this skill' "$SKILL_MD"
  [ "$status" -ne 0 ]
}

@test "work-problems P122: Step 2.5 explicitly cites AskUserQuestion as the default branch" {
  # The new default-selection prose names a "Default branch" that calls
  # AskUserQuestion. Match the structural phrase rather than the
  # backtick-wrapped tool name to keep the grep portable.
  run grep -F 'Default branch' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P122: Step 2.5 cites the orchestrator-vs-subprocess principle" {
  # The flip's load-bearing reasoning: the orchestrator's main turn is
  # interactive by construction; AFK persona is served by the
  # subprocess-boundary contract under ADR-032, not by suppressing
  # AskUserQuestion at the orchestrator layer. (Architect FLAG —
  # cross-skill principle sentence.)
  run grep -F 'subprocess-boundary contract' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'interactive by construction' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P122: Step 2.5 preserves the user-answerable skip-reason scoping" {
  # P103 anti-pattern boundary: the AskUserQuestion default must NOT
  # broaden to architect-design or upstream-blocked skip-reasons. The
  # user-answerable scoping from Step 4's classifier remains in force.
  run grep -F 'user-answerable' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P122: Step 2.5 preserves the 4-question-per-call cap" {
  # AskUserQuestion's documented per-call limit; sequential calls when
  # the question set exceeds the cap.
  run grep -F '4 questions per' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P122: Step 2.5 preserves the table-fallback-when-unavailable branch" {
  # Rule 6 fail-safe: when AskUserQuestion is unavailable (restricted
  # permission mode, etc.), emit the Outstanding Design Questions table.
  run grep -F 'Outstanding Design Questions' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P122: Decisions Table row for stop-condition #2 names AskUserQuestion as default" {
  # The Step 6.5 Decisions Table row at the bottom of the SKILL.md
  # must agree with the Step 2.5 prose — the prior "table is the
  # default" wording must be flipped here too.
  run grep -E '^\| Stop-condition #2 .*AskUserQuestion' "$SKILL_MD"
  [ "$status" -eq 0 ]
}
