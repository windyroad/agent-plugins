#!/usr/bin/env bats
# Doc-lint guard: create-adr SKILL.md must document the re-stage-after-Edit
# requirement for ADR supersession renames (Step 6).
#
# Structural assertion — Permitted Exception to the source-grep ban
# (ADR-005 / P011). The test asserts that the supersession step either
# warns authors that `git mv` stages only the rename, or instructs them
# to re-stage the file after editing frontmatter + "Superseded by" section.
#
# Cross-reference:
#   P057: docs/problems/057-git-mv-plus-edit-staging-ordering-trap.*.md
#   ADR-014: docs/decisions/014-governance-skills-commit-their-own-work.proposed.md
#   @jtbd JTBD-002 (ship with confidence — audit trail)

setup() {
  TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
  REPO_ROOT="$(cd "${TEST_DIR}/../../../../.." && pwd)"
  SKILL_FILE="${REPO_ROOT}/packages/architect/skills/create-adr/SKILL.md"
}

@test "create-adr SKILL.md exists (P057 precondition)" {
  [ -f "$SKILL_FILE" ]
}

@test "create-adr SKILL.md instructs re-staging the renamed ADR file after Edit (P057)" {
  # Authors must be told to run `git add <new>` (or equivalent) after editing
  # the renamed file (supersession adds a `Superseded by` section and a status
  # frontmatter update).
  run grep -inE "re-stage|re‑stage|\`git add\`.*after|after.*\`git add\`|git add <new>|git add .*\.superseded\.md|stages only the rename" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "create-adr SKILL.md cites P057 on the re-stage requirement (P057)" {
  # Traceability: the new guidance must cite P057 so reviewers can chase
  # the fix back to the incident that motivated it.
  run grep -n "P057" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
