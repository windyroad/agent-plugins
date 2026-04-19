#!/usr/bin/env bats
# Doc-lint guard: manage-problem SKILL.md must surface Verification Pending
# tickets whose fix path has been exercised in practice — the detection-layer
# fix for P048. Minimal-scope candidates per P048:
#   - Fix 1: step 9d always fires even on the fast-path cache hit.
#   - Fix 4: step 9c / Verification Queue highlights tickets whose release
#     age is >= 14 days as "likely verified" candidates.
#
# Candidates 2 (standalone verify-fixes op), 3 (exercise observations with a
# new file-level state dimension), and 5 (AFK-mode hook) are deferred —
# candidate 3 needs an ADR-scope decision per P048 investigation tasks.
#
# Structural assertion — Permitted Exception to the source-grep ban
# (ADR-005 / P011).
#
# Cross-reference:
#   P048: docs/problems/048-manage-problem-does-not-detect-verification-candidates.open.md
#   ADR-022 (Verification Pending status): docs/decisions/022-problem-lifecycle-verification-pending-status.proposed.md
#   ADR-013 Rule 1: docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md
#   @jtbd JTBD-001 (enforce governance without slowing down)
#   @jtbd JTBD-006 (progress the backlog while I'm away)
#   @jtbd JTBD-101 (extend the suite with clear patterns)

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

@test "SKILL.md exists (P048 precondition)" {
  [ -f "$SKILL_FILE" ]
}

@test "SKILL.md fast-path explicitly fires step 9d on cache hit (P048 Candidate 1)" {
  # The fast-path currently reads: "Skip steps 9a-9b entirely / Proceed
  # directly to step 9c". P048 reports step 9d being treated as skipped
  # alongside 9a-9b. Fix: add explicit wording that step 9d fires even on
  # cache hit, so verification candidates are always offered on review.
  run grep -inE "step 9d.*(always fires?|still fires?|fires? (even|on) (cache|fast-path))|fast-path.*step 9d fires|cache hit.*step 9d" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md step 9c Verification Queue highlights release-age candidates (P048 Candidate 4)" {
  # Review output must surface Verification Pending tickets whose release
  # age crosses a threshold as "likely verified" candidates. Accept either
  # a literal "likely verified" callout OR an explicit age-based criterion
  # (>= 14 days) in the Verification Queue presentation.
  run grep -inE "likely verified|release age|age.*(>=|greater than|over|older than).*(days?|d)|stale verification" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md step 9c Verification Queue documents the 14-day default threshold (P048 Candidate 4)" {
  # The 14-day threshold is a within-skill default per architect review;
  # the default must be named in the SKILL.md so implementations stay
  # consistent until a policy-level decision moves it.
  run grep -inE "14[ -]day|14 days|fourteen days" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md cites P048 for the detection-layer extension" {
  # Traceability: the SKILL.md must name the problem ticket this
  # detection extension addresses so reviewers can chase history.
  run grep -n "P048" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
