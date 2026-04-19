#!/usr/bin/env bats
# Doc-lint guard: manage-problem SKILL.md must document the re-stage-after-Edit
# requirement for every `git mv` block that is followed by a content edit.
#
# Structural assertion — Permitted Exception to the source-grep ban (ADR-005 / P011).
# The tests assert that the skill specification document warns authors that
# `git mv` alone stages only the rename, and subsequent Edit-tool modifications
# must be re-staged explicitly (`git add <new>`) before commit — otherwise the
# commit captures a rename-only change and the content edit leaks into the
# next commit, corrupting the audit trail (P054 / P046 incident, 2026-04-19).
#
# Cross-reference:
#   P057: docs/problems/057-git-mv-plus-edit-staging-ordering-trap.*.md
#   ADR-014: docs/decisions/014-governance-skills-commit-their-own-work.proposed.md
#   ADR-022: docs/decisions/022-problem-lifecycle-verification-pending-status.proposed.md
#   @jtbd JTBD-002 (ship with confidence — audit trail)
#   @jtbd JTBD-006 (progress the backlog while I'm away — audit trail)

setup() {
  TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
  REPO_ROOT="$(cd "${TEST_DIR}/../../../../.." && pwd)"
  SKILL_FILE="${REPO_ROOT}/packages/itil/skills/manage-problem/SKILL.md"
}

@test "manage-problem SKILL.md exists (P057 precondition)" {
  [ -f "$SKILL_FILE" ]
}

@test "manage-problem SKILL.md warns that git mv stages only the rename (P057)" {
  # The document must explicitly state that `git mv` stages the rename into
  # the index but does NOT pick up subsequent Edit-tool content changes.
  run grep -inE "git mv.*(only the rename|rename only|not .*content|stages only)" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "manage-problem SKILL.md instructs re-staging the renamed file after Edit (P057)" {
  # Authors must be told to run `git add <new>` (or equivalent) after editing
  # the renamed file, before commit.
  run grep -inE "re-stage|re‑stage|\`git add\`.*after|after.*\`git add\`|git add <new>|git add .*\.verifying\.md|git add .*\.known-error\.md" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "manage-problem SKILL.md cites P057 on the re-stage requirement (P057)" {
  # Traceability: the new guidance must cite P057 so reviewers can chase
  # the fix back to the incident that motivated it.
  run grep -n "P057" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
