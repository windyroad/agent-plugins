#!/usr/bin/env bats

# P101 / ADR-043: run-retro SKILL.md gains a Step 2c (Context-usage measurement
# — cheap layer) between Step 2b (Pipeline-instability scan) and Step 3
# (Update the briefing tree). The cheap layer invokes
# packages/retrospective/scripts/measure-context-budget.sh and renders a
# per-source-bucket table in the retro summary at < 5% of the session budget.
#
# Doc-lint structural test (Permitted Exception per ADR-005). Asserts SKILL.md
# wording for: the step header, citation of ADR-043, citation of ADR-026
# grounding rule, citation of the diagnostic script path, the AFK fallback
# (ADR-013 Rule 6) prose, the defensive-trip fail-open contract, the
# composition-with-P099 / P105 paragraphs, and the user-direction-only
# discipline on the deep layer.
#
# Behavioural assertions on the script itself live in
# packages/retrospective/scripts/test/measure-context-budget.bats.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SKILL_MD="$REPO_ROOT/packages/retrospective/skills/run-retro/SKILL.md"
}

@test "run-retro: SKILL.md contains Step 2c Context-usage measurement (P101)" {
  run grep -F '### 2c. Context-usage measurement (cheap layer, P101)' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 2c cites ADR-043 as the source decision" {
  run grep -F 'ADR-043' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 2c invokes measure-context-budget.sh as the primitive" {
  run grep -F 'packages/retrospective/scripts/measure-context-budget.sh' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 2c cites ADR-026 grounding rule" {
  run grep -F 'ADR-026' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 2c bans qualitative-only phrases per ADR-026" {
  # Forbidden phrases listed verbatim in Step 2c step 4
  run grep -F 'load is negligible' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'microseconds only' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 2c documents the defensive-trip fail-open contract" {
  run grep -F 'cheap layer disabled' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 2c AFK Rule 6 fallback prose present" {
  run grep -F 'ADR-013 Rule 6' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'AFK behaviour' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 2c documents first-retro / no-prior-snapshot path" {
  run grep -F 'no prior snapshot' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 2c cites P099 + P105 composition (no double-counting)" {
  run grep -F 'P099' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'P105' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 2c references HTML-comment trailer for snapshot persistence" {
  run grep -F 'context-snapshot' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 2c routes deep analysis to /wr-retrospective:analyze-context only on user direction" {
  run grep -F '/wr-retrospective:analyze-context' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: Step 2c is placed between Step 2b and Step 3" {
  # Capture line numbers for ordering check
  step_2b_line=$(grep -n '^### 2b\.' "$SKILL_MD" | head -1 | cut -d: -f1)
  step_2c_line=$(grep -n '^### 2c\.' "$SKILL_MD" | head -1 | cut -d: -f1)
  step_3_line=$(grep -n '^### 3\. Update the briefing tree' "$SKILL_MD" | head -1 | cut -d: -f1)

  [ -n "$step_2b_line" ]
  [ -n "$step_2c_line" ]
  [ -n "$step_3_line" ]

  [ "$step_2b_line" -lt "$step_2c_line" ]
  [ "$step_2c_line" -lt "$step_3_line" ]
}
