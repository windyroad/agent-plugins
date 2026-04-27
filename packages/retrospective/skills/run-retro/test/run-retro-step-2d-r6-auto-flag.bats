#!/usr/bin/env bats
#
# packages/retrospective/skills/run-retro/test/run-retro-step-2d-r6-auto-flag.bats
#
# Behavioural tests for Step 2d's R6-numeric-gate auto-flag contract
# (P135 follow-up / ADR-044 Reassessment Trigger). When the R6 gate
# fires (lazy count ≥2 across 3 consecutive retros), Step 2d MUST
# auto-queue a deviation-candidate so the framework reminds itself
# that Phase 4 enforcement-hook work is warranted.
#
# tdd-review: structural-permitted (justification: skill behavioural
# harness pending P012 + P081 Phase 2; SKILL.md contract assertions
# bridge until then; expected to migrate to behavioural form once
# the harness exists)
#
# @problem P135 (ADR-044 Reassessment / Phase 4 gating)
# @adr ADR-044 (Decision-Delegation Contract — R6 numeric gate)
# @adr ADR-005 / ADR-037 (testing strategy)
# @jtbd JTBD-001 / JTBD-006

SKILL_FILE="${BATS_TEST_DIRNAME}/../SKILL.md"

setup() {
  [ -f "$SKILL_FILE" ]
}

@test "Step 2d documents R6 numeric gate auto-flag mechanism (P135 Reassessment Trigger)" {
  run grep -F "R6 numeric gate auto-flag" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 2d invokes check-ask-hygiene.sh to detect R6 condition" {
  run grep -F "check-ask-hygiene.sh" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 2d R6 condition explicit: lazy count >=2 across 3 consecutive retros" {
  run grep -F "≥2 across 3 consecutive retros" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 2d auto-queues a deviation-candidate when R6 fires" {
  run grep -F "auto-queue a deviation-candidate" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 2d auto-flag deviation-candidate cites P135 + ADR-044" {
  # Bound to Step 2d section
  run awk '/^### 2d\./,/^### 3\./ {print}' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"P135"* ]]
  [[ "$output" == *"ADR-044"* ]]
}

@test "Step 2d auto-flag specifies the proposed_shape: amend (Phase 4 enforcement hook)" {
  run awk '/^### 2d\./,/^### 3\./ {print}' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"proposed_shape:"* ]]
  [[ "$output" == *"amend"* ]]
  [[ "$output" == *"Phase 4 enforcement hook"* ]]
}

@test "ADR-044 Reassessment cites R6 numeric gate as the explicit trigger" {
  ADR_FILE="${BATS_TEST_DIRNAME}/../../../../../docs/decisions/044-decision-delegation-contract.proposed.md"
  [ -f "$ADR_FILE" ]
  run grep -F "R6 numeric gate fires" "$ADR_FILE"
  [ "$status" -eq 0 ]
}

@test "ADR-044 Reassessment explicitly cross-references Step 2d's auto-queue mechanism" {
  ADR_FILE="${BATS_TEST_DIRNAME}/../../../../../docs/decisions/044-decision-delegation-contract.proposed.md"
  [ -f "$ADR_FILE" ]
  run grep -F "auto-queue a deviation-candidate" "$ADR_FILE"
  [ "$status" -eq 0 ]
}

@test "ADR-044 Reassessment names 'framework reminds itself' as the no-manual-tracking property" {
  ADR_FILE="${BATS_TEST_DIRNAME}/../../../../../docs/decisions/044-decision-delegation-contract.proposed.md"
  [ -f "$ADR_FILE" ]
  run grep -F "framework reminds itself" "$ADR_FILE"
  [ "$status" -eq 0 ]
}
