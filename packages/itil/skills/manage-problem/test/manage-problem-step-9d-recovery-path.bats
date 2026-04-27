#!/usr/bin/env bats
#
# packages/itil/skills/manage-problem/test/manage-problem-step-9d-recovery-path.bats
#
# Behavioural tests for manage-problem Step 9d's recovery-path
# documentation (P135 Phase 2 / R5 / ADR-044).
#
# Step 9d closes verifying tickets on evidence WITHOUT firing
# AskUserQuestion (per ADR-044 framework-resolution boundary).
# Mirrors the run-retro Step 4a recovery-path contract.
#
# tdd-review: structural-permitted (justification: skill behavioural
# harness pending P012 + P081 Phase 2; SKILL.md contract assertions
# bridge until then; expected to migrate to behavioural form once
# the harness exists)
#
# @problem P135 Phase 2 R5
# @adr ADR-044 (Decision-Delegation Contract — closes are reversible)
# @adr ADR-022 (verification-pending lifecycle)
# @adr ADR-026 (cost-source grounding for in-session evidence)
# @adr ADR-005 / ADR-037 (testing strategy — bridge during harness build)
# @jtbd JTBD-001 / JTBD-006 / JTBD-201

SKILL_FILE="${BATS_TEST_DIRNAME}/../SKILL.md"

setup() {
  [ -f "$SKILL_FILE" ]
}

# ── Step 9d's close-on-evidence contract ────────────────────────────────────

@test "Step 9d SKILL.md cites /wr-itil:transition-problem as the close-on-evidence dispatch target" {
  # Bound the search to Step 9d (not the entire file)
  run awk '/^\*\*Step 9d:/,/^\*\*Step 9e:/ {print}' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"/wr-itil:transition-problem"* ]]
}

@test "Step 9d SKILL.md names ADR-044 framework-resolution boundary as the rationale for no-AskUserQuestion close" {
  run awk '/^\*\*Step 9d:/,/^\*\*Step 9e:/ {print}' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ADR-044"* ]]
}

@test "Step 9d SKILL.md cites ADR-026 grounding requirement for in-session evidence" {
  run awk '/^\*\*Step 9d:/,/^\*\*Step 9e:/ {print}' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ADR-026"* ]]
}

@test "Step 9d SKILL.md cites ADR-022 verification-pending lifecycle semantics" {
  run awk '/^\*\*Step 9d:/,/^\*\*Step 9e:/ {print}' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ADR-022"* ]]
}

# ── Recovery-path contract ──────────────────────────────────────────────────

@test "Step 9d SKILL.md documents that closes are reversible" {
  run awk '/^\*\*Step 9d:/,/^\*\*Step 9e:/ {print}' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"reversible"* ]]
}

@test "Step 9d SKILL.md names the recovery invocation (transition-problem known-error)" {
  run awk '/^\*\*Step 9d:/,/^\*\*Step 9e:/ {print}' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"known-error"* ]]
}

@test "Step 9d SKILL.md cites 2026-04-27 P124 verifying-flip-back precedent" {
  run awk '/^\*\*Step 9d:/,/^\*\*Step 9e:/ {print}' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"P124"* ]]
}

# ── Ambiguous-evidence preservation (no auto-close on weak evidence) ────────

@test "Step 9d SKILL.md preserves the ambiguous-evidence path (left as Verification Pending)" {
  run awk '/^\*\*Step 9d:/,/^\*\*Step 9e:/ {print}' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ambiguous"* ]] || [[ "$output" == *"Verification Pending"* ]]
}

@test "Step 9d SKILL.md routes user disagreement through authentic-correction surface" {
  run awk '/^\*\*Step 9d:/,/^\*\*Step 9e:/ {print}' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"authentic-correction"* ]] || [[ "$output" == *"P078"* ]]
}

# ── Step 9d output contract ─────────────────────────────────────────────────

@test "Step 9d SKILL.md says output table records each close action with citation" {
  run awk '/^\*\*Step 9d:/,/^\*\*Step 9e:/ {print}' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"citation"* ]] || [[ "$output" == *"output table"* ]]
}
