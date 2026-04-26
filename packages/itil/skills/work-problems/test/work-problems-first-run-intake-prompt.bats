#!/usr/bin/env bats

# P065 / ADR-036 Confirmation line 199: work-problems SKILL.md must wire
# the first-run intake-scaffold pointer + AFK fail-safe + marker contract.
#
# Doc-lint structural test (Permitted Exception per ADR-005). Sister bats
# to manage-problem-first-run-intake-prompt.bats.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SKILL_MD="$REPO_ROOT/packages/itil/skills/work-problems/SKILL.md"
}

@test "work-problems: SKILL.md cites ADR-036 (first-run-prompt contract)" {
  run grep -F 'ADR-036' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems: SKILL.md cross-references the scaffold-intake skill" {
  run grep -F 'wr-itil:scaffold-intake' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems: SKILL.md documents the AFK fail-safe (no auto-scaffold; iteration-report pending-note)" {
  # AFK orchestrator branch must NOT auto-scaffold; instead the iteration
  # appends a one-line "pending intake scaffold" note to its summary.
  # The SKILL.md preamble pointer documents this so AFK consumers see
  # the divergence at glance.
  run grep -iE 'pending.intake.scaffold|pending intake scaffold|silent note' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems: SKILL.md cites the decline marker path (ADR-009 + ADR-036)" {
  run grep -F '.claude/.intake-scaffold-declined' "$SKILL_MD"
  [ "$status" -eq 0 ]
}
