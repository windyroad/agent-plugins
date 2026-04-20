#!/usr/bin/env bats

# Doc-lint structural test (Permitted Exception per ADR-005 — structural
# SKILL.md content checks, not behavioural). Mirrors the pattern from
# ADR-011, ADR-027, and ADR-028 doc-lint tests.
#
# P059: install-updates skill must detect ADR-documented rename-mapped
# stale enabled-plugin keys and auto-migrate them within already-confirmed
# siblings. The mapping table at .claude/skills/install-updates/rename-mapping.json
# is the source of truth.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  SKILL_MD="$REPO_ROOT/.claude/skills/install-updates/SKILL.md"
  RENAME_JSON="$REPO_ROOT/.claude/skills/install-updates/rename-mapping.json"
}

@test "install-updates: rename-mapping.json exists" {
  [ -f "$RENAME_JSON" ]
}

@test "install-updates: rename-mapping.json has the wr-problem -> wr-itil entry per ADR-010 (P059)" {
  run grep -F '"from": "wr-problem"' "$RENAME_JSON"
  [ "$status" -eq 0 ]
  run grep -F '"to": "wr-itil"' "$RENAME_JSON"
  [ "$status" -eq 0 ]
  run grep -F '"adr": "ADR-010"' "$RENAME_JSON"
  [ "$status" -eq 0 ]
}

@test "install-updates: rename-mapping.json is valid JSON" {
  run node -e 'JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"))' "$RENAME_JSON"
  [ "$status" -eq 0 ]
}

@test "install-updates: SKILL.md references rename-mapping.json (P059)" {
  run grep -F 'rename-mapping.json' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "install-updates: SKILL.md documents the auto-migrate carve-out (P059)" {
  # Step 6.5 introduces auto-migration without a second consent gate.
  run grep -F 'Auto-migrate ADR-documented stale entries' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "install-updates: SKILL.md cites ADR-030 amendment for direct settings.json mutation (P059)" {
  # The carve-out language must explicitly name the ADR-030 Confirmation
  # amendment so the settings.json mutation is auditable.
  run grep -iE 'ADR-030.*amendment|Confirmation amendment' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "install-updates: SKILL.md final report includes auto-migrated entries section (P059)" {
  run grep -F 'Auto-migrated stale entries' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "install-updates: SKILL.md ban on auto-migrating non-ADR-documented stale entries (P059)" {
  # Manual user uninstalls (not in rename-mapping.json) must not be migrated.
  run grep -iE 'NOT auto-migrated|not auto-migrate' "$SKILL_MD"
  [ "$status" -eq 0 ]
}
