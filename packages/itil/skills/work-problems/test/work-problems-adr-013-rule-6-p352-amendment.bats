#!/usr/bin/env bats
# ADR-013 Rule 6 P352 amendment (2026-06-06): queue-and-continue is the
# universal AFK default when a skill needs user input but AskUserQuestion is
# unavailable. HALT/SKIP/AUTO-DEFAULT are deviations requiring inline-cited
# carve-out justification.
#
# Structural assertion — Permitted Exception to the source-grep ban (ADR-005 /
# P011). These assertions are load-bearing-string checks on the ADR + SKILL
# specification prose. Per P081, structural tests are placeholders for
# behavioural tests against P012's skill-testing harness; until the harness
# can exercise AFK fallback shapes, prose assertions on the carve-out audit
# are the confirmation mechanism named in the amended Rule 6 Confirmation
# section.
#
# tdd-review: structural-permitted (justification: ADR Rule 6 + SKILL.md prose
# contract assertions for an interaction-pattern contract that has no
# behavioural skill-runtime harness yet — P012 + P081 Phase 2 bridge window.
# Isomorphic precedent in this repo: work-problems-above-appetite-remediation.bats,
# create-adr-substance-confirm-pattern.bats, create-adr-adr-044-contract.bats.)
#
# @problem P352 (AFK queue-and-continue is the universal default)
# @adr ADR-013 (structured user interaction; Rule 6 amended 2026-06-06)
# @adr ADR-044 (decision-delegation contract; AUTO-DEFAULT lives inside framework-resolution)
# @adr ADR-052 (behavioural-by-default with structural bridge window)
# @adr ADR-074 (confirm decision substance before building; authorises HALT carve-outs)
# @jtbd JTBD-006 (Progress the Backlog While I'm Away — primary persona)
# @jtbd JTBD-001 (Enforce Governance Without Slowing Down — queue keeps governance on during AFK)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  ADR_013="${REPO_ROOT}/docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md"
}

# ----------------------------------------------------------------------
# ADR-013 Rule 6 amendment prose
# ----------------------------------------------------------------------

@test "ADR-013 file exists" {
  [ -f "$ADR_013" ]
}

@test "ADR-013 Rule 6 names queue-and-continue as the universal default (P352 amendment)" {
  # The load-bearing prose: queue-and-continue is THE universal default.
  run grep -nE "queue-and-continue is the universal default" "$ADR_013"
  [ "$status" -eq 0 ]
}

@test "ADR-013 Rule 6 dates the amendment (2026-06-06)" {
  # Date-anchoring lets future readers correlate the prose with P352 timeline.
  run grep -nE "2026-06-06 amendment" "$ADR_013"
  [ "$status" -eq 0 ]
}

@test "ADR-013 Rule 6 names halt-with-directive AND silent-skip as deviations" {
  # The amendment's contract: HALT and SKIP are DEVIATIONS requiring carve-out
  # justification — they are not the default.
  run grep -nE "DEVIATIONS that require an explicit" "$ADR_013"
  [ "$status" -eq 0 ]
}

@test "ADR-013 Rule 6 documents the capture-problem HALT carve-out (ADR-074 authority)" {
  # The amendment must explicitly name the documented HALT carve-outs so
  # readers know the SKILL surfaces that LEGITIMATELY halt and why.
  run grep -nE "capture-problem.*derive-then-ratify HALT" "$ADR_013"
  [ "$status" -eq 0 ]
}

@test "ADR-013 Rule 6 documents the create-adr Step 5 HALT carve-out" {
  run grep -nE "create-adr.*Step 5 substance-confirm HALT" "$ADR_013"
  [ "$status" -eq 0 ]
}

@test "ADR-013 Rule 6 documents the manage-problem create-gate HALT carve-out" {
  run grep -nE "manage-problem.*create-gate HALT" "$ADR_013"
  [ "$status" -eq 0 ]
}

@test "ADR-013 Rule 6 names AUTO-DEFAULT as framework-resolved-only (ADR-044 boundary)" {
  # AUTO-DEFAULT is permitted ONLY when the decision is framework-resolved.
  # Outside the framework-resolution boundary, AUTO-DEFAULT is a defect.
  run grep -nE "AUTO-DEFAULT.*permitted ONLY when the decision is framework-resolved" "$ADR_013"
  [ "$status" -eq 0 ]
}

@test "ADR-013 Rule 6 cites ADR-044 (decision-delegation framework-resolution boundary)" {
  run grep -nE "ADR-044" "$ADR_013"
  [ "$status" -eq 0 ]
}

@test "ADR-013 Rule 6 cites ADR-074 (substance-confirm authority for HALT carve-outs)" {
  run grep -nE "ADR-074" "$ADR_013"
  [ "$status" -eq 0 ]
}

@test "ADR-013 Rule 6 cites JTBD-006 (Progress the Backlog While I'm Away)" {
  run grep -nE "JTBD-006" "$ADR_013"
  [ "$status" -eq 0 ]
}

@test "ADR-013 Rule 6 cites P352 as the originating ticket" {
  run grep -nE "\bP352\b" "$ADR_013"
  [ "$status" -eq 0 ]
}

@test "ADR-013 Rule 6 records the shared-helper extraction as a follow-on (deferred)" {
  # The ratified design explicitly deferred the shared-helper extraction to
  # follow-on. The prose must record the deferral so future readers (and
  # future iter agents) know the interim contract.
  run grep -nE "Shared-helper extraction deferred" "$ADR_013"
  [ "$status" -eq 0 ]
}

# ----------------------------------------------------------------------
# Per-SKILL carve-out audit annotations
# ----------------------------------------------------------------------

@test "capture-problem SKILL.md carries the P352 carve-out audit (HALT per ADR-074)" {
  SKILL="${REPO_ROOT}/packages/itil/skills/capture-problem/SKILL.md"
  [ -f "$SKILL" ]
  run grep -nE "ADR-013 Rule 6 carve-out audit \(P352" "$SKILL"
  [ "$status" -eq 0 ]
  # And the carve-out must name its authorising ADR
  run grep -nE "authorised by \*\*ADR-074" "$SKILL"
  [ "$status" -eq 0 ]
}

@test "create-adr SKILL.md carries the P352 carve-out audit (Step 1 AUTO-DEFAULT + Step 5 HALT)" {
  SKILL="${REPO_ROOT}/packages/architect/skills/create-adr/SKILL.md"
  [ -f "$SKILL" ]
  run grep -nE "ADR-013 Rule 6 carve-out audit \(P352" "$SKILL"
  [ "$status" -eq 0 ]
}

@test "manage-problem SKILL.md carries the P352 carve-out audit (Step 4b AUTO-DEFAULT)" {
  SKILL="${REPO_ROOT}/packages/itil/skills/manage-problem/SKILL.md"
  [ -f "$SKILL" ]
  run grep -nE "ADR-013 Rule 6 carve-out audit \(P352" "$SKILL"
  [ "$status" -eq 0 ]
}

@test "review-problems SKILL.md cites the P352 amendment at the Step 4.5 AFK branch" {
  SKILL="${REPO_ROOT}/packages/itil/skills/review-problems/SKILL.md"
  [ -f "$SKILL" ]
  run grep -nE "ADR-013 Rule 6 universal default \(P352" "$SKILL"
  [ "$status" -eq 0 ]
}

@test "scaffold-intake SKILL.md cites the P352 amendment as canonical queue-and-continue" {
  SKILL="${REPO_ROOT}/packages/itil/skills/scaffold-intake/SKILL.md"
  [ -f "$SKILL" ]
  run grep -nE "ADR-013 Rule 6 universal default \(P352" "$SKILL"
  [ "$status" -eq 0 ]
}

@test "run-retro SKILL.md cites the P352 amendment at the Step 1.5 AFK branch" {
  SKILL="${REPO_ROOT}/packages/retrospective/skills/run-retro/SKILL.md"
  [ -f "$SKILL" ]
  run grep -nE "ADR-013 Rule 6 universal default \(P352" "$SKILL"
  [ "$status" -eq 0 ]
}
