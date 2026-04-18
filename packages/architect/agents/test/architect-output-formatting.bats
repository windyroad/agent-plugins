#!/usr/bin/env bats
# Doc-lint guard: architect agent.md must include the output formatting rule
# requiring human-readable titles alongside bare IDs (P032).
#
# Structural assertion — Permitted Exception to the source-grep ban (ADR-005 / P011).
#
# Cross-reference:
#   P032 (agent output uses opaque IDs without titles)
#   @jtbd JTBD-001 (enforce governance without slowing down)

setup() {
  AGENT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  AGENT_FILE="${AGENT_DIR}/agent.md"
}

@test "agent.md contains output formatting section" {
  run grep -n "## Output Formatting" "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "agent.md output formatting rule requires titles with IDs (P032)" {
  run grep -n "title" "$AGENT_FILE"
  [ "$status" -eq 0 ]
  run grep -n "Output Formatting" "$AGENT_FILE"
  [ "$status" -eq 0 ]
}
