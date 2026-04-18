#!/usr/bin/env bats
# Doc-lint guard: run-retro SKILL.md must include the skill-recommendation branch.
#
# Structural assertion — Permitted Exception to the source-grep ban (ADR-005 / P011).
# These tests do not assert hook behaviour; they assert that the skill specification
# document includes the skill-candidate branch added in P044.
#
# Cross-reference:
#   P044 (docs/problems/044-run-retro-does-not-recommend-new-skills.known-error.md)
#   ADR-013 Rule 1 / Rule 6 (docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md)
#   @jtbd JTBD-001 (enforce governance without slowing down)
#   @jtbd JTBD-101 (extend the suite with clear patterns)

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

@test "SKILL.md exists and has frontmatter" {
  [ -f "$SKILL_FILE" ]
  run head -1 "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [ "$output" = "---" ]
}

@test "SKILL.md Step 2 includes the skill-candidate reflection category (P044)" {
  # P044 fix: Step 2 must prompt for recurring workflows that would be better as skills.
  # Regression guard: if Step 2 is rewritten and the skill-candidate prompt is dropped,
  # this test fails.
  run grep -n "recurring workflow.*better as a skill\|would be better as a skill" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md includes a Step 4b Recommend new skills branch (P044)" {
  # P044 fix: a dedicated output branch for skill candidates, distinct from Step 4
  # (problem tickets) and Step 5 (summary).
  run grep -n "Recommend new skills\|Step 4b" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 4b uses AskUserQuestion (ADR-013 Rule 1)" {
  # ADR-013 Rule 1: the skill-candidate decision branch must use AskUserQuestion,
  # not prose '(a)/(b)/(c)' enumeration. Architect review flagged this as the
  # gotcha to avoid when implementing P044.
  run grep -n "AskUserQuestion" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 4b header matches ADR-013 structured-interaction pattern" {
  # Header: "Skill candidate" identifies the AskUserQuestion call site and is what
  # other tests / review tooling can grep for.
  run grep -n "Skill candidate" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 4b names the three structured options (P044)" {
  # The three decision options must be explicit: create, track, skip.
  run grep -n "Create a new skill" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -n "Track as a problem ticket" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -n "Skip — not skill-worthy\|Skip - not skill-worthy" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 4b has non-interactive fallback per ADR-013 Rule 6" {
  # ADR-013 Rule 6: if AskUserQuestion is unavailable, flag candidates instead of
  # silently choosing. P044 implementation uses "flagged — not actioned" wording.
  run grep -n "non-interactive\|Rule 6" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 summary template has a Skill Candidates slot (P044)" {
  # P044 fix: the summary template must include a Skill Candidates section so
  # recommendations are visible in the session audit alongside BRIEFING changes
  # and problem tickets.
  run grep -n "### Skill Candidates" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md does not contain 'Options: (a)' prose option list (ADR-013)" {
  # ADR-013 Rule 1: user-facing decisions must use AskUserQuestion, not prose
  # "Options: (a)/(b)/(c)". This matches the narrow pattern used by
  # manage-problem-no-prose-options.bats so criteria lists using (a)/(b)/(c)
  # as internal enumeration (which are fine) don't trip the test.
  run grep -n "Options: (a)" "$SKILL_FILE"
  [ "$status" -ne 0 ]
}

@test "SKILL.md does not contain 'Your call:' prose option prompt (ADR-013)" {
  # ADR-013 Rule 1: mirrors the manage-problem regression guard.
  run grep -n "Your call:" "$SKILL_FILE"
  [ "$status" -ne 0 ]
}
