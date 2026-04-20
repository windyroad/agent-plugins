#!/usr/bin/env bats

# Doc-lint structural test (Permitted Exception per ADR-005 — structural
# SKILL.md content checks, not behavioural). Mirrors the doc-lint pattern
# established in ADR-011 and ADR-027 Confirmation tests.
#
# Asserts the report-upstream skill's SKILL.md encodes the contract
# documented in ADR-024 Confirmation criterion 2:
# - template discovery step
# - security-path routing with SECURITY.md fallback
# - explicit ban on auto-public-issue for security-classified tickets
# - cross-reference back-write step
# - ADR-024 cross-reference
#
# Plus two architect-required additions surfaced during P055 Part B
# implementation review:
# - ADR-027 Step-0 deferral rationale present
# - ADR-028 voice-tone gate interaction documented

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SKILL_MD="$REPO_ROOT/packages/itil/skills/report-upstream/SKILL.md"
}

@test "report-upstream: SKILL.md exists" {
  [ -f "$SKILL_MD" ]
}

@test "report-upstream: SKILL.md documents template discovery via ISSUE_TEMPLATE (ADR-024 Confirmation 2.1)" {
  run grep -F 'ISSUE_TEMPLATE' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "report-upstream: SKILL.md routes via SECURITY.md with explicit fallback (ADR-024 Confirmation 2.2)" {
  run grep -ic 'SECURITY.md' "$SKILL_MD"
  [ "$status" -eq 0 ]
  [ "$output" -ge 2 ]
}

@test "report-upstream: SKILL.md explicitly bans auto-opening a public issue for security-classified tickets (ADR-024 Confirmation 2.3)" {
  run grep -iE 'never .*auto-open .*public issue' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "report-upstream: SKILL.md contains the cross-reference back-write step (ADR-024 Confirmation 2.4)" {
  run grep -F '## Reported Upstream' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "report-upstream: SKILL.md cross-references ADR-024 (ADR-024 Confirmation 2.5)" {
  run grep -F 'ADR-024' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "report-upstream: SKILL.md documents the ADR-027 Step-0 deferral rationale (architect review)" {
  run grep -F 'ADR-027' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -iE 'step.?0 deferral|step.?0' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "report-upstream: SKILL.md documents the ADR-028 voice-tone gate interaction (architect review)" {
  run grep -F 'ADR-028' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -iE 'voice-tone gate' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "report-upstream: SKILL.md encodes three distinct AFK branches (architect review)" {
  # Public-issue path / Security path with declared channel / Security path
  # halt-and-surface / Above-appetite commit. The "AFK behaviour summary"
  # table is the canonical place; assert its presence.
  run grep -F 'AFK behaviour summary' "$SKILL_MD"
  [ "$status" -eq 0 ]
}
