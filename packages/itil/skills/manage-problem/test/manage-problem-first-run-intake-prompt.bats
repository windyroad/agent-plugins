#!/usr/bin/env bats

# P065 / ADR-036 Confirmation line 198: manage-problem SKILL.md must
# wire the first-run intake-scaffold prompt — citing ADR-036 + the AFK
# fail-safe + the marker contract.
#
# Doc-lint structural test (Permitted Exception per ADR-005). The wiring
# itself is a SKILL.md preamble pointer (architect direction 2026-04-26),
# so behavioural assertions live at the contract layer of scaffold-intake;
# this bats fixes the wiring point so future maintainers cannot silently
# remove the cross-reference.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SKILL_MD="$REPO_ROOT/packages/itil/skills/manage-problem/SKILL.md"
}

@test "manage-problem: SKILL.md cites ADR-036 (first-run-prompt contract)" {
  run grep -F 'ADR-036' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "manage-problem: SKILL.md cross-references the scaffold-intake skill" {
  run grep -F 'wr-itil:scaffold-intake' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "manage-problem: SKILL.md documents the first-run intake-scaffold detection clause" {
  # Detection clause must reference at least one intake-file path AND the
  # decline marker so future maintainers see how the trigger fires.
  run grep -iE 'intake' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F '.claude/.intake-scaffold-declined' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "manage-problem: SKILL.md documents the AFK fail-safe (no AskUserQuestion in AFK; iteration-report note)" {
  # Per ADR-013 Rule 6, the AFK orchestrator branch must not fire
  # AskUserQuestion. The SKILL.md preamble pointer must call out this
  # fail-safe so adopters reading the skill understand the divergence.
  run grep -iE 'afk|rule 6' "$SKILL_MD"
  [ "$status" -eq 0 ]
}
