#!/usr/bin/env bats
# Doc-lint guard: manage-problem SKILL.md step 3 (Assign the next ID) must
# include the next-ID collision guard against origin per ADR-019
# confirmation criterion 2.
#
# Structural assertion — Permitted Exception to the source-grep ban (ADR-005 / P011).
# These tests assert that the skill specification document instructs the
# orchestrator to compare next-ID against origin/<base> before assigning,
# so parallel sessions don't produce colliding ticket numbers.
#
# Cross-reference:
#   P043 (next-ID collision guard in ticket-creator skills)
#   P040 (work-problems does not fetch origin before starting — sibling)
#   ADR-019 (AFK orchestrator preflight, including next-ID guard)
#   @jtbd JTBD-006 (Progress the Backlog While I'm Away)

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

@test "SKILL.md cites ADR-019 (next-ID collision guard)" {
  run grep -n "ADR-019" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md step 3 references git ls-tree origin for next-ID lookup" {
  # ADR-019 mechanism: the orchestrator MUST re-check next-ID assignment
  # against `git ls-tree origin/<base>` before creating any new ticket.
  run grep -n "git ls-tree origin" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md mentions taking the max of local and origin IDs" {
  # The guard logic is: take the max of local-max-ID and origin-max-ID,
  # then increment. Skill must mention this combination.
  run grep -niE "max of (the )?(two|local and origin)|max\(.*origin" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
