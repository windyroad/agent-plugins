#!/usr/bin/env bats

# P105: run-retro SKILL.md documents a signal-vs-noise pass (Step 1.5) that
# scores every briefing entry per retro cycle, drives Critical Points curation,
# and gates deletion behind a batched user-confirmation queue.
#
# Doc-lint structural test (Permitted Exception per ADR-005). Asserts
# SKILL.md wording for: the step header, placement between Step 1 and Step 2,
# the three scoring rules (signal +2, noise -1, decay -1), the HTML comment
# persistence format, the ADR-026 grounding requirement, the threshold
# actions (promote/keep/delete), the Tier 1 budget guard, the delete-queue
# AskUserQuestion contract (ADR-013 Rule 1), the AFK fallback (ADR-013 Rule 6),
# the Step 3 agent-driven promotion update, and the Step 5 summary integration.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SKILL_MD="$REPO_ROOT/packages/retrospective/skills/run-retro/SKILL.md"
}

@test "run-retro: SKILL.md contains Step 1.5 Briefing signal-vs-noise pass (P105)" {
  run grep -F '### 1.5. Briefing signal-vs-noise pass (P105)' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 1.5 placement between Step 1 and Step 2" {
  pos_1=$(grep -n '^### 1\. ' "$SKILL_MD" | head -1 | cut -d: -f1)
  pos_1_5=$(grep -n '^### 1\.5\. ' "$SKILL_MD" | head -1 | cut -d: -f1)
  pos_2=$(grep -n '^### 2\. ' "$SKILL_MD" | head -1 | cut -d: -f1)
  [ -n "$pos_1" ]
  [ -n "$pos_1_5" ]
  [ -n "$pos_2" ]
  [ "$pos_1" -lt "$pos_1_5" ]
  [ "$pos_1_5" -lt "$pos_2" ]
}

@test "run-retro: Step 1.5 documents all three scoring events" {
  run grep -F 'Signal | +2' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'Noise | -1' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'Decay | -1' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 1.5 documents the HTML comment persistence format" {
  run grep -F 'signal-score:' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'last-classified:' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'first-written:' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 1.5 requires ADR-026 grounding for classifications" {
  run grep -F 'ADR-026' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'specific citation' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'Bare classifications are forbidden' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 1.5 documents promote threshold (score >= +3)" {
  run grep -F '>= +3' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'Promote to Critical Points' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 1.5 documents delete queue threshold (score <= -3)" {
  run grep -F '<= -3' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'delete queue' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 1.5 delete queue uses single batched AskUserQuestion (ADR-013 Rule 1)" {
  run grep -F 'Delete briefing entries?' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'Confirm all deletions' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'Keep all (defer to next retro)' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 1.5 AFK fallback defers delete queue to retro summary (ADR-013 Rule 6)" {
  run grep -F 'Non-interactive / AFK fallback (ADR-013 Rule 6)' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'Do NOT auto-delete' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'Signal-vs-Noise Pass' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 1.5 documents the Tier 1 budget guard" {
  run grep -F 'Tier 1 budget guard' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F '2 KB' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 1.5 cites ADR-040 for the Critical Points budget" {
  run grep -F 'ADR-040' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 1.5 classification is policy-authorised silent (ADR-013 Rule 5)" {
  run grep -F 'policy-authorised per ADR-013 Rule 5' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'agent owns silent classification' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 3 acknowledges agent-driven promotion from Step 1.5 score" {
  run grep -F 'agent-driven per Step 1.5' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'signal-score' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 5 summary adds a Signal-vs-Noise Pass section" {
  run grep -F '### Signal-vs-Noise Pass (P105)' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Signal-vs-Noise Pass summary table columns match Step 1.5 output" {
  run grep -F '| Entry | Topic file | Old score | New score | Classification | Citation |' "$SKILL_MD"
  [ "$status" -eq 0 ]
}
