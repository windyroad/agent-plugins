#!/usr/bin/env bats
#
# packages/itil/skills/work-problems/test/work-problems-mid-loop-userpromptsubmit-handler.bats
#
# Behavioural tests for the mid-loop UserPromptSubmit handler contract
# (P135 Phase 3 / R4 / ADR-044). The explicit corrective for the
# 2026-04-27 iter-9-killed overcorrection.
#
# When the orchestrator receives a user message DURING an iter, the
# in-flight iter MUST complete naturally to its ITERATION_SUMMARY
# emission BEFORE the orchestrator surfaces the queue + new direction.
# Killing the iter mid-flight (SIGTERM the iter PID) is forbidden —
# it wastes in-flight work and breaks the iter subprocess contract.
#
# tdd-review: structural-permitted (justification: skill behavioural
# harness pending P012 + P081 Phase 2; SKILL.md contract assertions
# bridge until then; expected to migrate to behavioural form once the
# harness exists)
#
# @problem P135 Phase 3 R4
# @adr ADR-044 (Decision-Delegation Contract — mid-loop interrupt handling)
# @adr ADR-032 (subprocess-boundary contract; iter completes naturally)
# @adr ADR-005 / ADR-037 (testing strategy — bridge during harness build)
# @jtbd JTBD-006 (AFK orchestrator must respect in-flight iter)

SKILL_FILE="${BATS_TEST_DIRNAME}/../SKILL.md"

setup() {
  [ -f "$SKILL_FILE" ]
}

# ── Mid-loop UserPromptSubmit handler contract ──────────────────────────────

@test "SKILL.md documents mid-loop UserPromptSubmit handler (P135 Phase 3 R4)" {
  run grep -F "Mid-loop UserPromptSubmit handling" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md mid-loop handler clause MUST let the in-flight iter complete naturally to ITERATION_SUMMARY emission" {
  run grep -F "complete naturally to its" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ITERATION_SUMMARY"* ]]
}

@test "SKILL.md mid-loop handler clause forbids SIGTERM to the iter PID" {
  run grep -F "no SIGTERM to the iter PID" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md mid-loop handler clause forbids killing iter mid-flight" {
  run grep -F "Do NOT abort the iter mid-flight" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md cites the 2026-04-27 iter-9-killed overcorrection as the corrective precedent" {
  run grep -F "iter-9-killed overcorrection" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md mid-loop handler surfaces the queue + new direction together AFTER iter completes" {
  run grep -F "surfaces the queue + the new direction together" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md cites the ~$5 + 25 min wasted-work cost as the loss measurement for the corrective" {
  # Concrete cost citation per ADR-026 grounding
  run grep -F "$5 + 25 min" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
