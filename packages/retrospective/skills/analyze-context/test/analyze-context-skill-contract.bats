#!/usr/bin/env bats

# P101 / ADR-043: new skill /wr-retrospective:analyze-context (deep layer)
# at packages/retrospective/skills/analyze-context/SKILL.md. Doc-lint
# structural test (Permitted Exception per ADR-005). Asserts the SKILL.md
# carries: the canonical name, citations of ADR-043 / ADR-026 / ADR-014 /
# ADR-013, references to the cheap-layer measurement primitive, the report
# path convention, the HTML-comment-trailer snapshot schema, the AFK
# never-auto-fires discipline, the ADR-014 commit-message convention, and
# the ADR-026 forbidden-qualitative-phrase ban.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SKILL_MD="$REPO_ROOT/packages/retrospective/skills/analyze-context/SKILL.md"
}

@test "analyze-context: SKILL.md exists at expected path" {
  [ -f "$SKILL_MD" ]
}

@test "analyze-context: frontmatter declares the wr-retrospective:analyze-context name" {
  run grep -F 'name: wr-retrospective:analyze-context' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "analyze-context: cites ADR-043 as the source decision" {
  run grep -F 'ADR-043' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "analyze-context: cites ADR-026 (Agent output grounding)" {
  run grep -F 'ADR-026' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "analyze-context: cites ADR-014 (Governance skills commit own work)" {
  run grep -F 'ADR-014' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "analyze-context: cites ADR-013 Rule 6 (AFK fallback)" {
  run grep -F 'ADR-013 Rule 6' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "analyze-context: references the cheap-layer measurement primitive" {
  run grep -F 'packages/retrospective/scripts/measure-context-budget.sh' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "analyze-context: declares the report path convention docs/retros/<date>-context-analysis.md" {
  run grep -F 'docs/retros/' "$SKILL_MD"
  [ "$status" -eq 0 ]
  # `--` separates flags from pattern; `-context-analysis.md` would otherwise
  # parse as an option flag.
  run grep -F -- '-context-analysis.md' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "analyze-context: HTML-comment trailer schema present (context-snapshot)" {
  run grep -F 'context-snapshot:' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "analyze-context: trailer schema cites measurement-method and measured-at fields" {
  run grep -F 'measurement-method' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'measured-at' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "analyze-context: auto-fires from run-retro Step 2c per ADR-043 Amendment 2026-06-08 (P295)" {
  # P295 settlement: deep layer auto-fires from cheap-layer Step 2c when the
  # combined trigger holds. Replaces the prior 'never auto-invoked' clause.
  run grep -iF 'auto-fires from run-retro Step 2c' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'Amendment 2026-06-08' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "analyze-context: SKILL.md no longer asserts 'never auto-invoked' / 'never auto-fires' (P295 supersedes)" {
  # The supersession discipline: the post-P295 SKILL.md MUST NOT carry the
  # contradicting 'never auto-fires' / 'never auto-invoked' prose, or future
  # agents will read it as still-authoritative and revert the wiring.
  run grep -F 'never auto-invoked' "$SKILL_MD"
  [ "$status" -ne 0 ]
  run grep -F 'Never auto-fires' "$SKILL_MD"
  [ "$status" -ne 0 ]
}

@test "analyze-context: cites the combined-trigger threshold values (14 days + 20%)" {
  # ADR-043 Amendment 2026-06-08 chosen initial thresholds per ADR-026
  # grounding rule (concrete numerics + no-prior-data sentinel).
  run grep -F '14 days' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F '20%' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "analyze-context: cites the once-per-day guard via TODAY snapshot file presence" {
  run grep -F 'once-per-day guard' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F '<TODAY>-context-analysis.md' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "analyze-context: ADR-014 commit-message convention declared (docs(retros): context analysis)" {
  run grep -F 'docs(retros): context analysis' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "analyze-context: bans qualitative-only phrases per ADR-026" {
  run grep -F 'load is negligible' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'microseconds only' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "analyze-context: requires comparable-prior citation in suggestions" {
  run grep -F 'comparable prior' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "analyze-context: routes to /wr-risk-scorer:assess-release fallback when subagent unavailable" {
  run grep -F '/wr-risk-scorer:assess-release' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "analyze-context: documents per-plugin decomposition step" {
  run grep -F 'Per-Plugin Decomposition' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "analyze-context: documents policy-breach detection step" {
  run grep -F 'Policy Breaches' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "analyze-context: cites P101 (driver ticket) and P091 (parent meta)" {
  run grep -F 'P101' "$SKILL_MD"
  [ "$status" -eq 0 ]
}
