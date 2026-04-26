#!/usr/bin/env bats

# P065 / ADR-036 / ADR-037 Confirmation: scaffold-intake SKILL.md must
# encode the contract documented in ADR-036's Decision Outcome.
#
# Doc-lint structural test (Permitted Exception per ADR-005 — structural
# SKILL.md content checks, not behavioural). Mirrors the report-upstream
# contract bats pattern and the ADR-037 "Source review (at implementation
# time)" requirement that every shipped skill ships at least one
# `<skill>-contract.bats`.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SKILL_MD="$REPO_ROOT/packages/itil/skills/scaffold-intake/SKILL.md"
  TEMPLATE_DIR="$REPO_ROOT/packages/itil/skills/scaffold-intake/templates"
}

@test "scaffold-intake: SKILL.md exists" {
  [ -f "$SKILL_MD" ]
}

@test "scaffold-intake: SKILL.md frontmatter declares the skill name" {
  run grep -F 'name: wr-itil:scaffold-intake' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "scaffold-intake: SKILL.md cross-references ADR-036 (driver decision)" {
  run grep -F 'ADR-036' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "scaffold-intake: SKILL.md cites ADR-032 foreground-synchronous pattern" {
  run grep -F 'ADR-032' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -iE 'foreground.synchronous' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "scaffold-intake: SKILL.md contains an explicit Rule 6 audit section (ADR-032 + ADR-013 Rule 6)" {
  # ADR-032 line 191 requires every skill that uses AskUserQuestion to
  # carry an enumerable Rule 6 audit. ADR-036 lines 92-97 ship the table
  # shape.
  run grep -iE 'rule 6 audit|rule-6 audit' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "scaffold-intake: SKILL.md enumerates the three trigger surfaces (ADR-036)" {
  # Trigger 1: first-run prompt from manage-problem / work-problems.
  # Trigger 2: pre-publish PreToolUse gate (hard stop).
  # Trigger 3: optional CI check (deferred / --ci flag).
  run grep -iE 'trigger 1|first-run' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -iE 'trigger 2|pre-publish' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -iE 'trigger 3|ci check|--ci' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "scaffold-intake: SKILL.md cites the INTAKE_BYPASS env override (ADR-036)" {
  run grep -F 'INTAKE_BYPASS' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "scaffold-intake: SKILL.md cites both marker files (ADR-036 + ADR-009)" {
  run grep -F '.claude/.intake-scaffold-done' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F '.claude/.intake-scaffold-declined' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "scaffold-intake: SKILL.md documents idempotent + --force semantics (ADR-036)" {
  run grep -iE 'idempotent' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F -- '--force' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F -- '--dry-run' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "scaffold-intake: SKILL.md enumerates the five required intake files (ADR-036 Detection 5)" {
  for path in 'config.yml' 'problem-report.yml' 'SECURITY.md' 'SUPPORT.md' 'CONTRIBUTING.md'; do
    run grep -F "$path" "$SKILL_MD"
    [ "$status" -eq 0 ] || { echo "missing reference: $path"; return 1; }
  done
}

@test "scaffold-intake: SKILL.md documents AFK fail-safe (no auto-scaffold) per JTBD-006" {
  # JTBD-006 + ADR-013 Rule 6: AFK orchestrator branch must NOT auto-write
  # template files. The skill documents this as a Rule 6 fail-safe.
  run grep -iE 'afk|rule 6' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -iE 'no auto.?scaffold|do not auto.?scaffold|silent note|pending.intake.scaffold' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "scaffold-intake: SKILL.md cites ADR-014 commit discipline" {
  run grep -F 'ADR-014' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# --- Templates directory ---

@test "scaffold-intake: templates/ directory exists with five template seeds" {
  [ -d "$TEMPLATE_DIR" ]
  [ -f "$TEMPLATE_DIR/config.yml.tmpl" ]
  [ -f "$TEMPLATE_DIR/problem-report.yml.tmpl" ]
  [ -f "$TEMPLATE_DIR/SECURITY.md.tmpl" ]
  [ -f "$TEMPLATE_DIR/SUPPORT.md.tmpl" ]
  [ -f "$TEMPLATE_DIR/CONTRIBUTING.md.tmpl" ]
}

@test "scaffold-intake: problem-report.yml.tmpl is problem-first (P066 shape)" {
  run grep -F 'title: "[problem] "' "$TEMPLATE_DIR/problem-report.yml.tmpl"
  [ "$status" -eq 0 ]
  run grep -F 'labels: ["problem", "needs-triage"]' "$TEMPLATE_DIR/problem-report.yml.tmpl"
  [ "$status" -eq 0 ]
}

@test "scaffold-intake: templates use mustache-style substitution tokens (ADR-036)" {
  # ADR-036 declares the token list. Each token must appear in at least
  # one template file for the substitution surface to be wired.
  for token in '{{project_name}}' '{{project_url}}' '{{security_contact}}'; do
    run grep -rF "$token" "$TEMPLATE_DIR/"
    [ "$status" -eq 0 ] || { echo "missing token: $token"; return 1; }
  done
}
