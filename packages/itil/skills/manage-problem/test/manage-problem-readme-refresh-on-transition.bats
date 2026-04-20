#!/usr/bin/env bats

# P062: manage-problem SKILL.md documents that every Step 7 status
# transition refreshes docs/problems/README.md and stages it in the
# same commit — including folded-fix commits that ride with `fix(...)`.
#
# Doc-lint structural test (Permitted Exception per ADR-005). Asserts
# SKILL.md wording for the refresh block, the four transition scopes,
# the folded-fix-commit case, the fast-path interaction, and the
# Step 11 commit convention's stage-list requirement.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SKILL_MD="$REPO_ROOT/packages/itil/skills/manage-problem/SKILL.md"
}

@test "manage-problem: SKILL.md contains the README.md refresh block (P062)" {
  run grep -F 'README.md refresh on every transition (P062)' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "manage-problem: the refresh block lists all four transition scopes" {
  run grep -F 'Open → Known Error, Known Error → Verification Pending, Verification Pending → Closed, Parked' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "manage-problem: the refresh block covers folded-fix commits explicitly" {
  run grep -F '**Folded-fix commits**' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "manage-problem: the refresh block says refresh is a render not a re-rank" {
  run grep -F 'The refresh is a render, not a re-rank' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "manage-problem: the refresh block stages README.md in the same commit" {
  run grep -F 'git add docs/problems/README.md' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "manage-problem: Step 11 commit convention requires README.md in the stage list on transitions (P062)" {
  run grep -F 'stage list MUST include `docs/problems/README.md`' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "manage-problem: Step 11 references Step 7's refresh block from the stage-list requirement" {
  run grep -F "Step 7's \"README.md refresh on every transition\" block (P062)" "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "manage-problem: refresh block describes the fast-path interaction" {
  run grep -F 'Fast-path interaction' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'cache stays fresh by construction' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "manage-problem: refresh block describes Last reviewed line update" {
  run grep -F 'Update the "Last reviewed" line' "$SKILL_MD"
  [ "$status" -eq 0 ]
}
