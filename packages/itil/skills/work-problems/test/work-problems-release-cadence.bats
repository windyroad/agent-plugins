#!/usr/bin/env bats
# Doc-lint guard: work-problems SKILL.md must include the inter-iteration
# release-cadence check per ADR-018.
#
# Structural assertion — Permitted Exception to the source-grep ban (ADR-005 / P011).
# These tests assert that the skill specification document contains the
# release-cadence step so the AFK orchestrator does not silently accumulate
# unreleased changesets across iterations.
#
# Cross-reference:
#   P041 (work-problems does not enforce release cadence)
#   ADR-018 (inter-iteration release cadence for AFK loops)
#   @jtbd JTBD-006 (Progress the Backlog While I'm Away)

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

@test "SKILL.md exists" {
  [ -f "$SKILL_FILE" ]
}

@test "SKILL.md cites ADR-018 (release cadence)" {
  # ADR-018 confirmation criterion: skill must reference the ADR.
  run grep -n "ADR-018" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md delegates to wr-risk-scorer:assess-release (preserves pure-scorer contract from ADR-015)" {
  # ADR-018 mechanism: must delegate to the assess-release skill rather than
  # re-implementing risk scoring inline.
  run grep -n "assess-release" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md references release:watch as the drain mechanism" {
  # ADR-018 mechanism: drain action runs npm run release:watch (after
  # push:watch) when the queue hits appetite.
  run grep -n "release:watch" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md references push:watch as part of the drain mechanism" {
  # ADR-018 mechanism: drain action runs push:watch before release:watch.
  run grep -n "push:watch" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md has a release-cadence step between iterations" {
  # The inter-iteration check should appear as a discrete step or subsection
  # so it is not buried in prose.
  run grep -niE "release.cadence|cadence check|release queue" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Non-Interactive Decision Making table covers pipeline risk at appetite" {
  # ADR-018 confirmation criterion: the non-interactive defaults table must
  # include a row for the release-drain decision, otherwise an AFK reader
  # cannot find the rule.
  run grep -niE "Pipeline risk at appetite|release queue.*appetite|drain.*release" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
