#!/usr/bin/env bats

# P170 / RFC-002 / ADR-031 Open-Execution Q1 resolution: work-problems
# SKILL.md wires the shared migration routine at Step 0a (after Step 0
# fetch/divergence preflight, before Step 1 backlog scan). Closes the
# Step 1 false-zero defect — flat-layout adopters without auto-migrate
# at Step 0a would enumerate zero matches at Step 1 and stop-condition
# would fire incorrectly. Doc-lint structural test — behavioural
# assertions live at packages/shared/test/sync-migrate-problems-layout.bats
# (T7) and the end-to-end behavioural fixture
# packages/itil/skills/work-problems/test/work-problems-auto-migrate.bats (T10).

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SKILL_MD="$REPO_ROOT/packages/itil/skills/work-problems/SKILL.md"
}

@test "work-problems: SKILL.md declares Step 0a auto-migrate (T9 wiring point)" {
  run grep -E '^### Step 0a:|^### 0a\.|Step 0a:' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems: SKILL.md Step 0a cites P170 / RFC-002 / ADR-031" {
  run grep -F 'P170' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'ADR-031' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems: SKILL.md Step 0a sources packages/itil/lib/migrate-problems-layout.sh" {
  run grep -F 'packages/itil/lib/migrate-problems-layout.sh' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems: SKILL.md Step 0a calls migrate_problems_to_per_state_layout entrypoint" {
  run grep -F 'migrate_problems_to_per_state_layout' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems: SKILL.md Step 0a fires AFTER Step 0 fetch/divergence and BEFORE Step 1 backlog scan" {
  local step_0_line step_0a_line step_1_line
  step_0_line=$(grep -nE '^### Step 0:' "$SKILL_MD" | head -1 | cut -d: -f1)
  step_0a_line=$(grep -nE '^### Step 0a:' "$SKILL_MD" | head -1 | cut -d: -f1)
  step_1_line=$(grep -nE '^### Step 1:' "$SKILL_MD" | head -1 | cut -d: -f1)
  [ -n "$step_0_line" ]
  [ -n "$step_0a_line" ]
  [ -n "$step_1_line" ]
  [ "$step_0_line" -lt "$step_0a_line" ]
  [ "$step_0a_line" -lt "$step_1_line" ]
}

@test "work-problems: SKILL.md Step 0a addresses the Step 1 false-zero defect (ADR-031 Backward Compatibility)" {
  # Architect explicitly noted Step 1 enumeration would mis-report
  # "nothing to do" on flat-layout adopters without Step 0a wiring.
  run grep -E 'false.zero|Step 1 enumerat|flat-layout adopter' "$SKILL_MD"
  [ "$status" -eq 0 ]
}
