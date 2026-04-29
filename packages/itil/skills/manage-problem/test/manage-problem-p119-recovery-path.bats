#!/usr/bin/env bats
#
# packages/itil/skills/manage-problem/test/manage-problem-p119-recovery-path.bats
#
# Behavioural tests for manage-problem Step 2 substep 7's P119 hook-misfire
# recovery procedure (P144 / ADR-048).
#
# Step 2 substep 7 documents a two-tier recovery for the case where
# `mark_step2_complete` succeeded but the P119 PreToolUse:Write hook still
# denies the new ticket Write — typically because the P124 helper returned
# a subprocess SID instead of the orchestrator SID (ADR-048 Phase 3
# regression). Without documented recovery, the agent reaches for the
# brute-force-touch-every-marker anti-pattern (139-marker incident,
# 2026-04-28). User correction was emphatic: "WTF? Why did you bypass
# instead of using the skill?"
#
# This bats fixes the contract:
#   - Sub-block names the gate-misfire signal (active flow + helper-succeeded
#     + Write-denied conjunction).
#   - Two-tier procedure named (first-tier announce-marker scrape; second-tier
#     python3-via-Bash file-write).
#   - Audit-trail-preservation test as the gate-on-sanctioning rule.
#   - Anti-pattern call-out ("DO NOT brute-force") in durable form.
#   - ADR-048, P124, P142 cross-references.
#   - <!-- supersedes-when: P142 ships --> HTML comment for cleanup
#     discoverability.
#
# tdd-review: structural-permitted (justification: skill behavioural
# harness pending P012 + P081 Phase 2; SKILL.md contract assertions
# bridge until then; expected to migrate to behavioural form once
# the harness exists).
#
# @problem P144
# @adr ADR-048 (Documented recovery from gate misfire is the prescribed surface, not bypass)
# @adr ADR-009 (gate marker lifecycle)
# @adr ADR-013 Rule 5 (policy-authorised silent proceed)
# @adr ADR-022 (problem lifecycle status suffixes)
# @adr ADR-037 / P081 (testing strategy — bridge during harness build)
# @adr ADR-038 (progressive disclosure — deny message terse)
# @adr ADR-044 (decision-delegation — recovery is mechanical)
# @jtbd JTBD-001 / JTBD-101 / JTBD-201

SKILL_FILE="${BATS_TEST_DIRNAME}/../SKILL.md"

setup() {
  [ -f "$SKILL_FILE" ]
}

# Bound the search to Step 2 substep 7 region (between Step 2 heading and Step 3 heading).
step2_text() {
  awk '/^### 2\. /,/^### 3\. /' "$SKILL_FILE"
}

# ── Recovery sub-block presence ─────────────────────────────────────────────

@test "Step 2 SKILL.md contains a Recovery sub-block for hook-denial misfire" {
  run step2_text
  [ "$status" -eq 0 ]
  [[ "$output" == *"Recovery"* ]]
  [[ "$output" == *"hook denial"* ]] || [[ "$output" == *"hook still denies"* ]] || [[ "$output" == *"deny"* ]]
}

# ── Gate-misfire signal definition ──────────────────────────────────────────

@test "Step 2 SKILL.md names the gate-misfire signal precondition (active manage-problem flow)" {
  run step2_text
  [ "$status" -eq 0 ]
  # The signal requires that the agent is already executing manage-problem
  # Step 2 in the current turn — not just any prior session marker.
  [[ "$output" == *"already executing"* ]] || [[ "$output" == *"active"* ]] || [[ "$output" == *"this turn"* ]]
}

@test "Step 2 SKILL.md names mark_step2_complete success as part of the misfire signal" {
  run step2_text
  [ "$status" -eq 0 ]
  [[ "$output" == *"mark_step2_complete"* ]]
}

# ── Two-tier procedure ──────────────────────────────────────────────────────

@test "Step 2 SKILL.md names the first-tier recovery (announce-marker scrape)" {
  run step2_text
  [ "$status" -eq 0 ]
  [[ "$output" == *"first-tier"* ]] || [[ "$output" == *"First-tier"* ]]
  [[ "$output" == *"itil-assistant-gate-announced"* ]]
}

@test "Step 2 SKILL.md names the second-tier recovery (python3-via-Bash file-write)" {
  run step2_text
  [ "$status" -eq 0 ]
  [[ "$output" == *"second-tier"* ]] || [[ "$output" == *"Second-tier"* ]]
  [[ "$output" == *"python3"* ]]
  [[ "$output" == *"Bash"* ]]
}

# ── Audit-trail-preservation test ───────────────────────────────────────────

@test "Step 2 SKILL.md states the audit-trail-preservation test as the sanctioning rule" {
  run step2_text
  [ "$status" -eq 0 ]
  [[ "$output" == *"audit-trail"* ]] || [[ "$output" == *"audit trail"* ]]
}

@test "Step 2 SKILL.md names the anti-pattern bound (any-marker-anywhere is NOT the test)" {
  # Architect advisory: the bound must rule out the loose "any marker from any
  # earlier invocation in this session" reading — that's the P131 surface.
  run step2_text
  [ "$status" -eq 0 ]
  [[ "$output" == *"this ticket"* ]] || [[ "$output" == *"THIS ticket"* ]]
}

# ── Anti-pattern call-out (durable surface) ─────────────────────────────────

@test "Step 2 SKILL.md contains the explicit DO-NOT-brute-force anti-pattern wording" {
  run step2_text
  [ "$status" -eq 0 ]
  [[ "$output" == *"DO NOT brute-force"* ]] || [[ "$output" == *"do not brute-force"* ]] || [[ "$output" == *"Do not brute-force"* ]]
}

@test "Step 2 SKILL.md cites the 2026-04-28 user correction context for the anti-pattern" {
  run step2_text
  [ "$status" -eq 0 ]
  [[ "$output" == *"P144"* ]]
}

# ── Cross-references ────────────────────────────────────────────────────────

@test "Step 2 SKILL.md cites ADR-048 for the recovery procedure scope" {
  run step2_text
  [ "$status" -eq 0 ]
  [[ "$output" == *"ADR-048"* ]]
}

@test "Step 2 SKILL.md cites P124 as the helper-bug source" {
  run step2_text
  [ "$status" -eq 0 ]
  [[ "$output" == *"P124"* ]]
}

@test "Step 2 SKILL.md cites P142 as the structural fix (supersession trigger)" {
  run step2_text
  [ "$status" -eq 0 ]
  [[ "$output" == *"P142"* ]]
}

# ── Supersession comment (CI-enforced cleanup invariant) ────────────────────

@test "Step 2 SKILL.md carries the supersedes-when HTML comment so cleanup is discoverable" {
  # ADR-048 Reassessment Criteria: when P142's resolution ADR is accepted,
  # this comment must be removed from SKILL.md source. Today the comment
  # is present and this assertion passes; once P142 lands, the cleanup
  # signal lives here.
  run step2_text
  [ "$status" -eq 0 ]
  [[ "$output" == *"supersedes-when"* ]]
  [[ "$output" == *"P142"* ]]
}

# ── Mechanical (no-AskUserQuestion) per ADR-044 ─────────────────────────────

@test "Step 2 SKILL.md states the recovery is mechanical (no AskUserQuestion required)" {
  run step2_text
  [ "$status" -eq 0 ]
  [[ "$output" == *"mechanical"* ]] || [[ "$output" == *"ADR-044"* ]]
}
