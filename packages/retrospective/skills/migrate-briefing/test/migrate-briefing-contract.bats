#!/usr/bin/env bats

# Contract-level structural tests for /wr-retrospective:migrate-briefing.
# Permitted Exception per ADR-005 — structural SKILL.md content checks,
# mirrored on scaffold-intake-contract.bats. Behavioural coverage lives
# in migrate-briefing-fixture.bats per ADR-052.
#
# Closes P204 verification surface.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SKILL_DIR="$REPO_ROOT/packages/retrospective/skills/migrate-briefing"
  SKILL_MD="$SKILL_DIR/SKILL.md"
  REFERENCE_MD="$SKILL_DIR/REFERENCE.md"
  SCRIPT="$REPO_ROOT/packages/retrospective/scripts/migrate-briefing.sh"
  SHIM="$REPO_ROOT/packages/retrospective/bin/wr-retrospective-migrate-briefing"
}

@test "migrate-briefing: SKILL.md exists" {
  [ -f "$SKILL_MD" ]
}

@test "migrate-briefing: REFERENCE.md exists (ADR-038 split)" {
  [ -f "$REFERENCE_MD" ]
}

@test "migrate-briefing: implementation script exists and is executable" {
  [ -x "$SCRIPT" ]
}

@test "migrate-briefing: bin shim exists and is executable" {
  [ -x "$SHIM" ]
}

@test "migrate-briefing: SKILL.md frontmatter declares the skill name" {
  run grep -F 'name: wr-retrospective:migrate-briefing' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "migrate-briefing: SKILL.md cites ADR-040 (target tree shape — load-bearing per architect)" {
  run grep -F 'ADR-040' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "migrate-briefing: SKILL.md cites ADR-032 foreground-synchronous pattern" {
  run grep -F 'ADR-032' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -iE 'foreground.synchronous' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "migrate-briefing: SKILL.md cites ADR-014 self-commit pattern" {
  run grep -F 'ADR-014' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "migrate-briefing: SKILL.md cites ADR-038 progressive-disclosure pattern" {
  run grep -F 'ADR-038' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "migrate-briefing: SKILL.md cites ADR-052 behavioural-tests-default" {
  run grep -F 'ADR-052' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "migrate-briefing: SKILL.md cites ADR-049 (no repo-relative paths — recurring class)" {
  run grep -F 'ADR-049' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "migrate-briefing: SKILL.md declares two-direction idempotency clause" {
  # Both no-op directions named: tree already present + no legacy file.
  run grep -iE 'tree.already.present|already.migrated' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -iE 'no.legacy.file|legacy.*does.not.exist|missing or empty' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "migrate-briefing: SKILL.md carries Rule 6 audit section (ADR-013)" {
  run grep -F 'Rule 6' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "migrate-briefing: SKILL.md cross-references P204 (the closing ticket)" {
  run grep -F 'P204' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "migrate-briefing: SKILL.md does NOT carry repo-relative packages/ paths (P151/P153/P219/P317 class)" {
  # No bash invocations that hardcode a packages/.../scripts/ path —
  # the script ships via ADR-049 PATH shim.
  run grep -E 'packages/[a-z]+/scripts/migrate-briefing\.sh' "$SKILL_MD"
  [ "$status" -ne 0 ]
}

@test "migrate-briefing: REFERENCE.md documents the heading-extraction algorithm" {
  run grep -iE 'heading.extraction|slug.derivation|collision' "$REFERENCE_MD"
  [ "$status" -eq 0 ]
}

@test "migrate-briefing: REFERENCE.md documents code-fence-aware parsing" {
  run grep -iE 'fence|code.fence|in_fence' "$REFERENCE_MD"
  [ "$status" -eq 0 ]
}
