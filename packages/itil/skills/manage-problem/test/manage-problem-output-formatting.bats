#!/usr/bin/env bats
# Doc-lint guard: manage-problem SKILL.md must include the output formatting rule
# requiring human-readable titles alongside bare IDs (P032).
#
# Structural assertion — Permitted Exception to the source-grep ban (ADR-005 / P011).
# These tests assert that the skill specification document contains the output
# formatting instruction so agents include titles with IDs in prose output.
#
# Cross-reference:
#   P032 (agent output uses opaque IDs without titles)
#   @jtbd JTBD-001 (enforce governance without slowing down)

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

@test "SKILL.md contains output formatting section" {
  run grep -n "## Output Formatting" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md output formatting rule requires titles with IDs (P032)" {
  # P032: agents must include human-readable titles when referencing IDs in prose.
  # The rule must mention including the title alongside IDs.
  run grep -n "title" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -n "Output Formatting" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
