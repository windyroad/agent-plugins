#!/usr/bin/env bats
#
# packages/itil/skills/work-problems/test/work-problems-deviation-candidate-shape.bats
#
# Behavioural tests for the deviation-candidate sub-pattern in
# ITERATION_SUMMARY.outstanding_questions (P135 Phase 3 / R7 / ADR-044).
#
# Per ADR-044's anti-BUFD-for-framework-evolution clause: existing
# decisions are point-in-time; as reality changes, existing decisions
# may become wrong. The agent MUST surface deviation candidates with
# evidence (existing-decision citation + contradicting-evidence
# citation per ADR-026 + proposed shape) and queue them for user
# approval. Never auto-deviate; never blindly follow against evidence.
#
# This bats fixture covers the deviation-candidate schema surface in
# the ITERATION_SUMMARY contract + Step 2.5 5-option AskUserQuestion
# loop-end emit + jsonl persistence shape across iter subprocess
# boundary + the positive regression assertion (not-queueing-when-
# evidence-present is a regression).
#
# tdd-review: structural-permitted (justification: skill behavioural
# harness pending P012 + P081 Phase 2; SKILL.md contract assertions
# bridge until then; expected to migrate to behavioural form once the
# harness exists)
#
# @problem P135 Phase 3 R7
# @adr ADR-044 (Decision-Delegation Contract — deviation-approval surface)
# @adr ADR-026 (cost-source grounding for evidence citations)
# @adr ADR-032 (pending-questions artefact precedent for jsonl)
# @adr ADR-005 / ADR-037 (testing strategy — bridge during harness build)
# @jtbd JTBD-006 (AFK loop empirical-discovery surface)

SKILL_FILE="${BATS_TEST_DIRNAME}/../SKILL.md"

setup() {
  [ -f "$SKILL_FILE" ]
}

# ── Deviation-candidate schema documented in ITERATION_SUMMARY contract ─────

@test "SKILL.md ITERATION_SUMMARY.outstanding_questions schema documents deviation-candidate entry shape" {
  run grep -F "deviation-approval" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -F "Deviation-candidate entry" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "deviation-candidate schema requires existing_decision citation field" {
  run grep -F "existing_decision:" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "deviation-candidate schema requires contradicting_evidence citation per ADR-026 grounding" {
  run grep -F "contradicting_evidence:" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -F "ADR-026" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "deviation-candidate schema requires proposed_shape ∈ {amend, supersede, one-time}" {
  run grep -F "proposed_shape:" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -F '"amend" | "supersede" | "one-time"' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ── No-auto-deviate contract ────────────────────────────────────────────────

@test "SKILL.md asserts agent does NOT auto-deviate when existing decision appears no-longer-right" {
  run grep -F "does **NOT auto-deviate**" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md asserts agent never blindly follows against evidence" {
  run grep -F "never blindly follows against evidence" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Phase 3 contract: not-queueing-when-strong-contradicting-evidence-exists is a regression" {
  run grep -F "Not-queueing-when-strong-contradicting-evidence-exists is a regression" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ── Loop-end 5-option AskUserQuestion emit ─────────────────────────────────

@test "Step 2.5 deviation-candidate loop-end emit presents the 5-option AskUserQuestion" {
  run grep -F "Approve + amend ADR" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -F "Approve + supersede ADR" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -F "Approve + one-time exception" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -F "Reject (existing decision stands)" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -F "Defer (need more evidence)" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 2.5 ranking puts deviation-approval at highest precedence" {
  run grep -F "deviation-approval (highest)" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ── Jsonl persistence across iter subprocess boundary ───────────────────────

@test "SKILL.md persists outstanding_questions to .afk-run-state/outstanding-questions.jsonl" {
  run grep -F ".afk-run-state/outstanding-questions.jsonl" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md cites ADR-032 pending-questions artefact precedent for the jsonl shape" {
  run grep -F "ADR-032 pending-questions artefact precedent" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ── Anti-BUFD-for-framework-evolution clause cross-reference ────────────────

@test "SKILL.md cites ADR-044's anti-BUFD-for-framework-evolution as the rationale" {
  run grep -F "anti-BUFD-for-framework-evolution" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
