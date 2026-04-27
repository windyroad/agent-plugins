#!/usr/bin/env bats
#
# packages/retrospective/skills/run-retro/test/run-retro-step-4a-recovery-path.bats
#
# Behavioural tests for run-retro Step 4a's recovery-path documentation
# (P135 Phase 2 / R5 / ADR-044).
#
# Step 4a closes verifying tickets on evidence WITHOUT firing
# AskUserQuestion (per ADR-044 framework-resolution boundary). The
# recovery contract is critical: closes are reversible, the recovery
# path is documented inline in the Step 5 retro summary, and the user
# can correct via authentic-correction (ADR-044 category 6) if a close
# was wrong.
#
# These tests assert the SKILL.md documents the recovery path
# alongside each close action, names the specific recovery invocation,
# and cites the 2026-04-27 P124 verifying-flip-back precedent as the
# real-world demonstration of the recovery path working end-to-end.
#
# Tests are contract-assertion bridge per ADR-044 Confirmation Criteria
# (a) — same justification as the cross-plugin-dispatch fixture above.
#
# tdd-review: structural-permitted (justification: skill behavioural
# harness pending P012 + P081 Phase 2; SKILL.md contract assertions
# bridge until then; expected to migrate to behavioural form once the
# harness exists)
#
# @problem P135 Phase 2 R5
# @adr ADR-044 (Decision-Delegation Contract — closes are reversible)
# @adr ADR-022 (verification-pending lifecycle)
# @adr ADR-014 (commit grain on the recovery commit)
# @adr ADR-005 / ADR-037 (testing strategy — bridge during harness build)
# @jtbd JTBD-001 / JTBD-006 / JTBD-201

SKILL_FILE="${BATS_TEST_DIRNAME}/../SKILL.md"

setup() {
  [ -f "$SKILL_FILE" ]
}

# ── Recovery-path documented in Step 4a ─────────────────────────────────────

@test "Step 4a SKILL.md documents the recovery path inline alongside close-on-evidence" {
  run awk '/^### 4a\./,/^### 4b\./ {print}' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Recovery"* ]]
}

@test "Step 4a SKILL.md names the recovery skill invocation (transition-problem known-error)" {
  run awk '/^### 4a\./,/^### 4b\./ {print}' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"transition-problem"* ]]
  [[ "$output" == *"known-error"* ]]
}

@test "Step 4a SKILL.md cites 2026-04-27 P124 verifying-flip-back as recovery precedent" {
  run awk '/^### 4a\./,/^### 4b\./ {print}' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"P124"* ]]
  [[ "$output" == *"flip-back"* ]]
}

@test "Step 4a SKILL.md affirms closes are reversible" {
  run awk '/^### 4a\./,/^### 4b\./ {print}' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"reversible"* ]]
}

# ── Recovery surfaces in Step 5 summary ─────────────────────────────────────

@test "Step 4a SKILL.md says the close action + recovery path lands in Step 5 retro summary" {
  run awk '/^### 4a\./,/^### 4b\./ {print}' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Step 5"* ]] || [[ "$output" == *"summary"* ]]
}

# ── Authentic-correction surface preserved ──────────────────────────────────

@test "Step 4a SKILL.md routes user disagreement through authentic-correction (ADR-044 category 6)" {
  run awk '/^### 4a\./,/^### 4b\./ {print}' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  # Either explicit "authentic-correction" or P078 (the canonical correction surface)
  [[ "$output" == *"authentic-correction"* ]] || [[ "$output" == *"P078"* ]]
}
