#!/usr/bin/env bats
# Doc-lint guard: manage-problem / work-problems / manage-incident SKILL.md
# files must document the Verification Pending lifecycle status per ADR-022.
# README.md template must present a Verification Queue section driven off the
# `.verifying.md` glob.
#
# Structural assertion — Permitted Exception to the source-grep ban
# (ADR-005 / P011). These tests assert that the three skill specification
# documents and the README template contain the status contract introduced
# by ADR-022 (Problem lifecycle — Verification Pending).
#
# Migration of existing `.known-error.md` files to `.verifying.md` is a
# separate follow-up commit per ADR-022 Scope; these tests cover only the
# documentation/contract changes that land in this iteration.
#
# Cross-reference:
#   ADR-022: docs/decisions/022-problem-lifecycle-verification-pending-status.proposed.md
#   P049: docs/problems/049-known-error-status-overloaded-with-fix-released-substate.*.md
#   P048: docs/problems/048-manage-problem-does-not-detect-verification-candidates.open.md
#   ADR-011: docs/decisions/011-manage-incident-skill.proposed.md
#   ADR-014: docs/decisions/014-governance-skills-commit-their-own-work.proposed.md
#   @jtbd JTBD-001 (enforce governance without slowing down)
#   @jtbd JTBD-006 (progress the backlog while I'm away)
#   @jtbd JTBD-101 (extend the suite with clear patterns)
#   @jtbd JTBD-201 (restore service fast with an audit trail)

setup() {
  TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
  # Test file lives at packages/itil/skills/manage-problem/test/ — walk up to the
  # repo root and then into the three SKILL.md locations.
  REPO_ROOT="$(cd "${TEST_DIR}/../../../../.." && pwd)"
  MANAGE_PROBLEM="${REPO_ROOT}/packages/itil/skills/manage-problem/SKILL.md"
  WORK_PROBLEMS="${REPO_ROOT}/packages/itil/skills/work-problems/SKILL.md"
  MANAGE_INCIDENT="${REPO_ROOT}/packages/itil/skills/manage-incident/SKILL.md"
  README_FILE="${REPO_ROOT}/docs/problems/README.md"
}

@test "ADR-022 exists (P049 precondition)" {
  [ -f "${REPO_ROOT}/docs/decisions/022-problem-lifecycle-verification-pending-status.proposed.md" ] || \
    [ -f "${REPO_ROOT}/docs/decisions/022-problem-lifecycle-verification-pending-status.accepted.md" ]
}

@test "manage-problem SKILL.md exists (P049 precondition)" {
  [ -f "$MANAGE_PROBLEM" ]
}

@test "manage-problem SKILL.md lifecycle table includes Verification Pending status (P049 + ADR-022)" {
  # ADR-022 Confirmation item 1: the lifecycle table must carry
  # "Verification Pending | .verifying.md" as a first-class row.
  run grep -inE "Verification Pending" "$MANAGE_PROBLEM"
  [ "$status" -eq 0 ]
  run grep -inE "\.verifying\.md" "$MANAGE_PROBLEM"
  [ "$status" -eq 0 ]
}

@test "manage-problem SKILL.md WSJF multiplier table documents Verification Pending exclusion (P049 + ADR-022)" {
  # ADR-022 Confirmation item 1: status multiplier table must carry a row
  # with the new status and either multiplier 0 OR explicit "excluded"
  # wording. Accept either so future tuning within the ADR's "reassessment
  # criteria" envelope doesn't require this test to change.
  run grep -inE "Verification Pending.*(0|excluded)|excluded.*Verification Pending" "$MANAGE_PROBLEM"
  [ "$status" -eq 0 ]
}

@test "manage-problem SKILL.md documents the Known Error to Verification Pending transition (P049 + ADR-022)" {
  # ADR-022 Scope line 61: the skill must describe the Known Error →
  # Verification Pending transition explicitly (git mv + Status field
  # update + Fix Released section in the same commit).
  run grep -inE "(Known Error|\.known-error\.md).*(→|->|to).*(Verification Pending|\.verifying\.md)|git mv.*\.verifying\.md" "$MANAGE_PROBLEM"
  [ "$status" -eq 0 ]
}

@test "manage-problem SKILL.md review step 9 targets .verifying.md via glob or suffix (P049 + ADR-022)" {
  # ADR-022 Confirmation: step 9d targets *.verifying.md via glob rather
  # than scanning .known-error.md bodies.
  run grep -inE "\*\.verifying\.md|\.verifying\.md.*glob|glob.*\.verifying\.md" "$MANAGE_PROBLEM"
  [ "$status" -eq 0 ]
}

@test "manage-problem SKILL.md review step 9 has a Verification Queue section (P049 + ADR-022)" {
  # ADR-022 Scope line 63: dedicated Verification Queue section parallel to
  # the main ranked table.
  run grep -inE "Verification Queue" "$MANAGE_PROBLEM"
  [ "$status" -eq 0 ]
}

@test "manage-problem SKILL.md cites ADR-022 (P049)" {
  # Traceability: the skill must cite the ADR that governs the status
  # contract so reviewers can chase the decision from the implementation.
  run grep -n "ADR-022" "$MANAGE_PROBLEM"
  [ "$status" -eq 0 ]
}

@test "work-problems SKILL.md classifier uses the .verifying.md suffix (P049 + ADR-022)" {
  # ADR-022 Scope line 67: work-problems classifier becomes suffix-based
  # rather than file-body-scan-based.
  run grep -inE "\.verifying\.md" "$WORK_PROBLEMS"
  [ "$status" -eq 0 ]
}

@test "manage-incident SKILL.md linked-problem close gating accepts .verifying.md (P049 + ADR-022)" {
  # ADR-022 Scope line 68: incident close gating accepts .verifying.md
  # alongside .known-error.md and .closed.md; .open.md still blocks.
  run grep -inE "\.verifying\.md" "$MANAGE_INCIDENT"
  [ "$status" -eq 0 ]
}

@test "docs/problems/README.md template has a Verification Queue section (P049 + ADR-022)" {
  # ADR-022 Scope line 69: README replaces the hand-maintained "Known Errors
  # (Fix Released — pending verification)" shadow table with a Verification
  # Queue driven off the glob.
  run grep -inE "Verification Queue" "$README_FILE"
  [ "$status" -eq 0 ]
}
