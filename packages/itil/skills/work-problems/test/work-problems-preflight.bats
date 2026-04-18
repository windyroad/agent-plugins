#!/usr/bin/env bats
# Doc-lint guard: work-problems SKILL.md must include the preflight
# (fetch-origin + divergence handling) per ADR-019.
#
# Structural assertion — Permitted Exception to the source-grep ban (ADR-005 / P011).
# These tests assert that the skill specification document contains the
# preflight step so the AFK orchestrator does not iterate against a stale
# local backlog when origin/<base> has advanced.
#
# Cross-reference:
#   P040 (work-problems does not fetch origin before starting)
#   ADR-019 (AFK orchestrator preflight)
#   @jtbd JTBD-006 (Progress the Backlog While I'm Away)

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

@test "SKILL.md cites ADR-019 (preflight)" {
  # ADR-019 confirmation criterion: skill must reference the ADR.
  run grep -n "ADR-019" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md preflight runs git fetch origin" {
  # ADR-019 mechanism: must run `git fetch origin` before opening the
  # work loop.
  run grep -n "git fetch origin" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md preflight uses git pull --ff-only on trivial divergence" {
  # ADR-019 mechanism: trivial fast-forward is policy-authorised; non-ff is
  # not. The skill must cite --ff-only to prevent merge attempts.
  run grep -n "ff-only" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md preflight stops the loop on non-fast-forward divergence" {
  # Confirmation: divergence handling must include a stop-with-report path,
  # not a silent retry or merge.
  run grep -niE "non-fast-forward|non-ff" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md preflight has a discrete step before backlog scan" {
  # The preflight should appear as a discrete step (e.g. Step 0 — Preflight)
  # so it is not buried in prose.
  run grep -niE "step 0|preflight" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Non-Interactive Decision Making table covers origin divergence" {
  # ADR-019 confirmation: the non-interactive defaults table must include a
  # row for the divergence decision.
  run grep -niE "Origin diverged|origin.*divergence|fast-forward" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md explicitly forbids non-interactive merge/rebase remediation" {
  # ADR-019 forbids non-interactive rebase/merge attempts. The skill must
  # negate these (e.g. "Do NOT attempt to rebase or merge" or "are NOT
  # policy-authorised") rather than silently allow them. We assert the
  # negation appears, not that the words are absent — discussing forbidden
  # operations in the negative is exactly what the ADR requires.
  run grep -niE "Do NOT attempt to rebase or merge|NOT policy-authorised" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
