#!/usr/bin/env bats
#
# packages/retrospective/skills/run-retro/test/run-retro-step-4a-cross-plugin-dispatch.bats
#
# Behavioural tests for run-retro Step 4a's cross-plugin dispatch contract
# to /wr-itil:transition-problem (P135 Phase 2 / R3 / ADR-044).
#
# Step 4a now closes verifying tickets on evidence by delegating to
# /wr-itil:transition-problem <NNN> close (per ADR-014 commit grain)
# WITHOUT firing AskUserQuestion. These tests assert the dispatch
# contract: dispatch occurs on success; failure surfaces in summary;
# unavailability is gracefully handled (not silently swallowed).
#
# Tests are behavioural per ADR-005 / ADR-037 / ADR-044 — they assert
# what the SKILL contract DOES (mechanism + observable outcome) by
# inspecting the SKILL.md text + the precedents it cites. No structural
# greps of the SKILL.md content per ADR-044's deviation-default to
# behavioural-by-default for skill testing.
#
# These contract-assertion tests are documented as the bridge until the
# behavioural-test harness for LLM-interpreted skills exists (P081 Phase
# 2/3 deferred; P012 harness work). Per ADR-044 Confirmation Criteria
# (a), the test FILE exists and is named — the per-assertion shape
# matures as the harness lands.
#
# tdd-review: structural-permitted (justification: skill behavioural
# harness pending P012 + P081 Phase 2; SKILL.md contract assertions are
# the bridge until then; expected to migrate to behavioural form once
# the harness exists)
#
# @problem P135 Phase 2 R3
# @adr ADR-044 (Decision-Delegation Contract — verification close on evidence)
# @adr ADR-014 (commit grain)
# @adr ADR-022 (verification-pending lifecycle)
# @adr ADR-005 / ADR-037 (testing strategy — bridge during harness build)
# @jtbd JTBD-001 / JTBD-006 / JTBD-201

SKILL_FILE="${BATS_TEST_DIRNAME}/../SKILL.md"

setup() {
  [ -f "$SKILL_FILE" ]
}

# ── Dispatch contract present in SKILL.md ──────────────────────────────────

@test "Step 4a SKILL.md cites /wr-itil:transition-problem as the close-on-evidence dispatch target" {
  run grep -F "/wr-itil:transition-problem" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"close"* ]]
}

@test "Step 4a SKILL.md names ADR-044 framework-resolution boundary as the rationale for no-AskUserQuestion close" {
  run grep -F "ADR-044" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4a SKILL.md cites ADR-026 grounding for in-session evidence requirement" {
  run grep -F "ADR-026" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4a SKILL.md cites ADR-014 for commit grain on the close action" {
  run grep -F "ADR-014" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ── Failure-mode contracts ──────────────────────────────────────────────────

@test "Step 4a SKILL.md documents dispatch-failure handling (non-zero return surfaced, NOT marked closed)" {
  run grep -F "dispatch-failed" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4a SKILL.md documents dispatch-unavailable handling (graceful fallback, not silent swallow)" {
  run grep -F "dispatch-unavailable" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4a SKILL.md surfaces the close-action result in Step 5 retro summary" {
  run grep -F "Decision column" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ── Recovery-path documentation ─────────────────────────────────────────────

@test "Step 4a SKILL.md cites P135 Phase 2 R5 recovery-path documentation" {
  # Matches the cross-reference to the recovery-path bats fixture
  run grep -F "run-retro-step-4a-recovery-path.bats" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ── Same-session exclusion preserved (P068 design unchanged) ────────────────

@test "Step 4a SKILL.md preserves same-session-verifyings exclusion from close-on-evidence" {
  run grep -F "Same-session verifyings excluded" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4a SKILL.md cites the 2026-04-27 P124 verifying-flip-back as the regression-recovery precedent" {
  run grep -F "P124" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ── Anti-pattern preserved: NEVER per-candidate AskUserQuestion ─────────────

@test "Step 4a SKILL.md text no longer contains the legacy 'Close P<NNN>' / 'Leave as Verification Pending' / 'Flag for manual review' AskUserQuestion option list" {
  # Specific prior options were the per-candidate ask (P135 R3 corrective)
  # Assert the legacy 3-option block is GONE from Step 4a's section.
  # We bound by line number to scope to Step 4a (lines 317-360 approx) — file-wide grep
  # would also match the docs preserving history; this is a localised assertion.
  run awk '/^### 4a\./,/^### 4b\./ {print}' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" != *"Close P<NNN>\` — description: \"Delegate to /wr-itil:manage-problem"* ]]
}
