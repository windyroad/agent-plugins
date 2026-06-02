#!/usr/bin/env bats
# tdd-review: structural-permitted (justification: deferred-retrofit per P330 Investigation Task #3 — behavioural K→V-mock test deferred to follow-up commit; this structural backstop guards the SKILL prose carrying the Release-vehicle seed instruction in the meantime per ADR-052 § Surface 2 marker)
#
# Doc-lint guard: manage-problem SKILL.md Step 7 Known Error → Verification Pending block
# must document the P330 Option B seed step that appends a `**Release vehicle**: .changeset/<name>.md`
# paragraph to the ticket's Fix Strategy section BEFORE the `git mv` to `.verifying.md`.
# The same instruction must be mirrored in `transition-problem` SKILL.md Step 6 per ADR-010 amended
# (copy-not-move; P093 split-skill execution ownership).
#
# Cross-reference:
#   P330: docs/problems/known-error/330-derive-release-vehicle-helper-requires-pre-edit-of-ticket-changeset-reference-three-touch-when-one-touch-would-suffice.md
#   ADR-010: docs/decisions/010-rename-wr-problem-to-wr-itil.proposed.md (P093 amendment — copy-not-move)
#   ADR-014: docs/decisions/014-governance-skills-commit-their-own-work.proposed.md (single-commit grain)
#   ADR-022: docs/decisions/022-problem-lifecycle-verification-pending-status.proposed.md (Verifying status)
#   ADR-052: docs/decisions/052-behavioural-tests-default-for-skill-testing.proposed.md (Surface 2 marker)
#   @jtbd JTBD-002 (ship with confidence — audit trail self-documents the release vehicle)
#   @jtbd JTBD-006 (progress backlog AFK — eliminates the 3-of-4-dogfoods exit-2 routing friction)

setup() {
  TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
  REPO_ROOT="$(cd "${TEST_DIR}/../../../../.." && pwd)"
  MANAGE_PROBLEM_SKILL="${REPO_ROOT}/packages/itil/skills/manage-problem/SKILL.md"
  TRANSITION_PROBLEM_SKILL="${REPO_ROOT}/packages/itil/skills/transition-problem/SKILL.md"
}

@test "manage-problem SKILL.md exists (P330 precondition)" {
  [ -f "$MANAGE_PROBLEM_SKILL" ]
}

@test "transition-problem SKILL.md exists (P330 precondition)" {
  [ -f "$TRANSITION_PROBLEM_SKILL" ]
}

@test "manage-problem SKILL.md Step 7 documents the Release vehicle seed step (P330)" {
  # The K→V transition block must instruct authors to seed a `**Release vehicle**: .changeset/<name>.md`
  # paragraph in the ticket's `## Fix Strategy` section BEFORE the `git mv` to `.verifying.md`.
  run grep -inE 'Release vehicle.*\.changeset/' "$MANAGE_PROBLEM_SKILL"
  [ "$status" -eq 0 ]
}

@test "manage-problem SKILL.md Step 7 seed instruction precedes the K→V git mv (P330)" {
  # Verify ordering: the "Seed `Release vehicle`" instruction must appear BEFORE the
  # `git mv ... .known-error.md ... .verifying.md` block in Step 7. If the seed instruction
  # lands AFTER the rename in the prose, the agent reading top-to-bottom would do the
  # rename first and the seed-on-known-error-path would target a non-existent file.
  seed_line=$(grep -nE 'Seed `Release vehicle` reference BEFORE the rename' "$MANAGE_PROBLEM_SKILL" | head -1 | cut -d: -f1)
  rename_line=$(grep -nE 'git mv docs/problems/known-error/<NNN>-<title>\.md docs/problems/verifying/<NNN>-<title>\.md' "$MANAGE_PROBLEM_SKILL" | head -1 | cut -d: -f1)
  [ -n "$seed_line" ]
  [ -n "$rename_line" ]
  [ "$seed_line" -lt "$rename_line" ]
}

@test "manage-problem SKILL.md Step 7 cites P330 on the seed instruction (P330 traceability)" {
  # The seed instruction must cite P330 so reviewers can chase the rationale.
  run grep -nE 'P330' "$MANAGE_PROBLEM_SKILL"
  [ "$status" -eq 0 ]
}

@test "manage-problem SKILL.md Step 7 documents the two P057 staging-trap windows (seed + rename)" {
  # The amendment introduces a second Edit-tool window (seed Edit on .known-error.md).
  # The SKILL prose must explicitly call out that the existing single-`git add` shape covers
  # BOTH windows by riding the rename's index entry.
  run grep -inE 'Two P057 staging-trap windows|two .* Edit windows|seed Edit.*FIRST.*P057' "$MANAGE_PROBLEM_SKILL"
  [ "$status" -eq 0 ]
}

@test "transition-problem SKILL.md Step 6 mirrors the Release vehicle seed step (ADR-010 copy-not-move)" {
  # Per ADR-010 amended (P093 split-skill execution ownership), the manage-problem Step 7
  # block and the transition-problem Step 6 block must stay in sync. Both surfaces are user-
  # initiated K→V entry points (manage-problem fold-fix path + transition-problem standalone path).
  run grep -inE 'Release vehicle.*\.changeset/' "$TRANSITION_PROBLEM_SKILL"
  [ "$status" -eq 0 ]
}

@test "transition-problem SKILL.md Step 6 cites P330 on the seed instruction (ADR-010 copy-not-move)" {
  run grep -nE 'P330' "$TRANSITION_PROBLEM_SKILL"
  [ "$status" -eq 0 ]
}

@test "transition-problem SKILL.md Step 6 documents the two P057 staging-trap windows (seed + rename)" {
  run grep -inE 'Two P057 staging-trap windows|two .* Edit windows|seed Edit.*FIRST.*P057' "$TRANSITION_PROBLEM_SKILL"
  [ "$status" -eq 0 ]
}
