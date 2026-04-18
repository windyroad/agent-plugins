#!/usr/bin/env bats
# Doc-lint guard: create-adr SKILL.md step 3 (Determine sequence number)
# must include the next-ID collision guard against origin per ADR-019
# confirmation criterion 2.
#
# Structural assertion — Permitted Exception to the source-grep ban (ADR-005 / P011).
# These tests assert that the skill specification document instructs the
# ADR creator to compare next-number against origin/<base> before
# assigning, so parallel sessions don't produce colliding ADR numbers.
#
# Cross-reference:
#   P043 (next-ID collision guard in ticket-creator skills)
#   ADR-019 (AFK orchestrator preflight, including next-ID guard)

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

@test "SKILL.md cites ADR-019 (next-ID collision guard)" {
  run grep -n "ADR-019" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md step 3 references git ls-tree origin for next-number lookup" {
  # ADR-019 mechanism: the ADR creator MUST re-check next-number against
  # `git ls-tree origin/<base>` before assigning.
  run grep -n "git ls-tree origin" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md mentions taking the max of local and origin numbers" {
  run grep -niE "max of (the )?(two|local and origin)|max\(.*origin" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
