#!/usr/bin/env bats
# Doc-lint guard: create-adr SKILL.md must prevent the post-rename edit that
# originally required re-staging during ADR supersession.
#
# Structural assertion — Permitted Exception to the source-grep ban
# (ADR-005 / P011). The test asserts that the supersession step either
# preserves the old ADR as immutable after `git mv`, eliminating the staging
# trap instead of documenting a workaround for it.
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

@test "create-adr SKILL.md eliminates the post-rename edit staging trap (P057)" {
  run grep -inE "Do not edit the old decision's frontmatter or body" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "create-adr SKILL.md cites P057 on eliminating the trap (P057)" {
  run grep -nE "P057 staging trap.*no post-rename edit" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
