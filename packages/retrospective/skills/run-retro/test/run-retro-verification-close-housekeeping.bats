#!/usr/bin/env bats

# P068: run-retro SKILL.md documents the Verification-close housekeeping
# step (Step 4a) that surfaces in-session evidence for `.verifying.md`
# tickets and delegates the close transition to /wr-itil:manage-problem.
#
# Doc-lint structural test (Permitted Exception per ADR-005). Asserts
# SKILL.md wording for: the glob, the evidence-scan grounding (ADR-026),
# the three categorisation buckets, the AskUserQuestion prompt contract
# (ADR-013 Rule 1), the AFK fallback (ADR-013 Rule 6), the delegation
# boundary to manage-problem Step 7 (ADR-022 + ADR-014 ownership), and
# the ADR-027 auto-delegation compatibility note.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SKILL_MD="$REPO_ROOT/packages/retrospective/skills/run-retro/SKILL.md"
}

@test "run-retro: SKILL.md contains Step 4a Verification-close housekeeping (P068)" {
  run grep -F '### 4a. Verification-close housekeeping (P068)' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 4a globs docs/problems/*.verifying.md per ADR-022" {
  run grep -F 'docs/problems/*.verifying.md' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 4a delegates the close transition to /wr-itil:manage-problem Step 7" {
  run grep -F '/wr-itil:manage-problem' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'run-retro does **not** rename, edit the Status field, or commit' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 4a documents all three evidence-category buckets" {
  run grep -F 'Exercised successfully in-session' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'Not exercised in-session' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'Exercised with regression' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 4a requires specific-citation grounding (ADR-026)" {
  run grep -F 'ADR-026 grounding' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'not bare counts' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 4a AskUserQuestion prompt contract requires fix summary AND citations inline (ADR-013 Rule 1)" {
  run grep -F 'ADR-013 Rule 1' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'Question body MUST include the fix summary AND the specific citations' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 4a three AskUserQuestion options (Close / Leave Verification Pending / Flag for manual review)" {
  run grep -F 'Close P<NNN>' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'Leave as Verification Pending' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'Flag for manual review' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 4a AFK fallback surfaces evidence in the retro report and does NOT auto-close (ADR-013 Rule 6)" {
  run grep -F 'Non-interactive / AFK fallback (per ADR-013 Rule 6)' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'do NOT auto-close' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 4a ADR-027 compatibility note documents session-context handling" {
  run grep -F 'ADR-027 compatibility note' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'subagent' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 4a cites feedback_verify_from_own_observation memory for the deferred-close rationale" {
  run grep -F 'feedback_verify_from_own_observation.md' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 4a documents interaction with manage-problem Step 9d and same-session verifyings are skipped" {
  run grep -F 'manage-problem Step 9d' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'same-session verifyings' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 5 summary adds a Verification Candidates section" {
  run grep -F '### Verification Candidates' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Verification Candidates table columns match the Step 4a output semantics" {
  run grep -F '| Ticket | Fix summary | In-session citations | Decision |' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 4a does not miscite ADR-018 as the retrospective contract (P068 architect review)" {
  # The SKILL.md change must not claim ADR-018 governs the run-retro contract.
  # ADR-018 is about AFK inter-iteration release cadence, not retrospective.
  run grep -iE 'ADR-018.*retrospective (contract|ADR)|retrospective (contract|ADR).*ADR-018' "$SKILL_MD"
  [ "$status" -ne 0 ]
}
