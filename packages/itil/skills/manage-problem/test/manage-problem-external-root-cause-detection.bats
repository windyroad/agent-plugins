#!/usr/bin/env bats

# P063: manage-problem SKILL.md documents the external-root-cause
# detection block that triggers /wr-itil:report-upstream (ADR-024)
# when root cause is external.
#
# Doc-lint structural test (Permitted Exception per ADR-005) — asserts
# SKILL.md wording for detection tokens, AskUserQuestion three-option
# prompt, AFK fallback, and the stable `- **Upstream report pending** —`
# marker. Mirrors work-problems-release-cadence.bats and
# report-upstream-contract.bats patterns.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  MP_SKILL="$REPO_ROOT/packages/itil/skills/manage-problem/SKILL.md"
  WP_SKILL="$REPO_ROOT/packages/itil/skills/work-problems/SKILL.md"
}

@test "manage-problem: SKILL.md contains the External-root-cause detection block (P063)" {
  run grep -F 'External-root-cause detection (P063)' "$MP_SKILL"
  [ "$status" -eq 0 ]
}

@test "manage-problem: SKILL.md documents strict detection tokens (upstream, third-party, external, vendor)" {
  run grep -F '`upstream`, `third-party`, `external`, `vendor`' "$MP_SKILL"
  [ "$status" -eq 0 ]
}

@test "manage-problem: SKILL.md documents the scoped-npm detection pattern" {
  run grep -F '@[\w-]+/[\w-]+' "$MP_SKILL"
  [ "$status" -eq 0 ]
}

@test "manage-problem: SKILL.md documents the three AskUserQuestion options (invoke / defer / false positive)" {
  run grep -F 'Invoke /wr-itil:report-upstream now' "$MP_SKILL"
  [ "$status" -eq 0 ]
  run grep -F 'Defer and note in ticket' "$MP_SKILL"
  [ "$status" -eq 0 ]
  run grep -F 'Not actually upstream' "$MP_SKILL"
  [ "$status" -eq 0 ]
}

@test "manage-problem: SKILL.md defines the stable Upstream report pending marker with fixed wording" {
  run grep -F -- '- **Upstream report pending** — external dependency identified; invoke /wr-itil:report-upstream when ready' "$MP_SKILL"
  [ "$status" -eq 0 ]
}

@test "manage-problem: SKILL.md documents the AFK non-interactive fallback (option 2, append marker, no auto-invoke)" {
  run grep -iE 'non-interactive.*afk|afk.*fallback' "$MP_SKILL"
  [ "$status" -eq 0 ]
  # Explicit ban on auto-invoke
  run grep -F 'Do NOT auto-invoke' "$MP_SKILL"
  [ "$status" -eq 0 ]
}

@test "manage-problem: SKILL.md documents the already-noted check to avoid duplicate prompts" {
  run grep -F 'Already-noted check' "$MP_SKILL"
  [ "$status" -eq 0 ]
}

@test "manage-problem: SKILL.md documents both insertion points (Open → Known Error AND upstream-blocked park)" {
  run grep -F 'Open → Known Error transition' "$MP_SKILL"
  [ "$status" -eq 0 ]
  run grep -F 'Parking path with `upstream-blocked` reason' "$MP_SKILL"
  [ "$status" -eq 0 ]
}

@test "manage-problem: Parked lifecycle entry cross-references the external-root-cause detection block" {
  run grep -F 'If the park reason is `upstream-blocked`' "$MP_SKILL"
  [ "$status" -eq 0 ]
}

@test "manage-problem: SKILL.md references ADR-024 and ADR-013 Rule 6 in the detection block" {
  run grep -F 'ADR-024 Confirmation criterion 3a' "$MP_SKILL"
  [ "$status" -eq 0 ]
  run grep -F 'ADR-013 Rule 6' "$MP_SKILL"
  [ "$status" -eq 0 ]
}

@test "work-problems: upstream-blocked skip row runs the AFK fallback before skipping" {
  run grep -F 'append the pending-upstream-report marker' "$WP_SKILL"
  [ "$status" -eq 0 ]
}

@test "work-problems: upstream-blocked taxonomy entry documents the AFK fallback" {
  run grep -F 'Before skipping, run the manage-problem external-root-cause detection AFK fallback' "$WP_SKILL"
  [ "$status" -eq 0 ]
}

@test "work-problems: Non-Interactive Decision Making table has the external-root-cause row (P063)" {
  run grep -F 'External root cause detected at Open → Known Error' "$WP_SKILL"
  [ "$status" -eq 0 ]
}

@test "work-problems: uses the same stable marker wording as manage-problem" {
  run grep -F -- '- **Upstream report pending** — external dependency identified; invoke /wr-itil:report-upstream when ready' "$WP_SKILL"
  [ "$status" -eq 0 ]
}
