#!/usr/bin/env bats
# Doc-lint guard: work-problems SKILL.md must include an inter-iteration
# verification check (P036). After each subagent returns, the orchestrator
# must verify via `git status --porcelain` that the tree is clean (or
# dirty for a known deliberate reason) before spawning the next iteration.
#
# Structural assertion — Permitted Exception to the source-grep ban
# (ADR-005 / P011). Asserts the skill specification document contains the
# inter-iteration check so a silent subagent commit failure cannot
# compound across iterations.
#
# Cross-reference:
#   P036 (work-problems orchestrator does not verify commit-landing between iterations)
#   P035 (commit-gate fallback, the primary mitigation this backstops)
#   @jtbd JTBD-006 (progress the backlog while I'm away)

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

@test "SKILL.md cites P036 (inter-iteration verification)" {
  run grep -n "P036" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md has an inter-iteration verification step (after commit, before next iteration)" {
  # The step should appear between the commit/release-cadence step and
  # the "Step 7: Loop" section, with a recognisable heading.
  run grep -niE "inter-iteration verification|verif.*iteration|post-iteration verif" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md inter-iteration check uses git status --porcelain" {
  run grep -n "git status --porcelain" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md inter-iteration check halts the loop on unexpected dirty state" {
  # Must describe halting / stopping when the tree is dirty without a
  # known-deliberate reason.
  run grep -niE "halt|stop the loop|dirty.*(halt|stop|block)|uncommitted.*(halt|stop|block|detected)" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md inter-iteration check distinguishes clean tree from deliberate dirty state" {
  # Not all dirty states are errors — e.g. a governance doc transition
  # the subagent deliberately left for the next iteration to pick up.
  # The check should permit a documented dirty state and halt on an
  # undocumented one.
  run grep -niE "deliberate|known reason|expected|documented.*dirty|known.*dirty" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Non-Interactive Decision Making table covers unexpected dirty state" {
  # AFK mode: inter-iteration dirty state should have a default action.
  run grep -niE "inter[- ]iteration|unexpected dirty" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
