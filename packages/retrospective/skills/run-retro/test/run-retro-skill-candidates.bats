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

@test "SKILL.md Step 2 includes the skill-candidate reflection category (P044, updated by P050)" {
  # P044 fix: Step 2 must prompt for recurring workflows that would be better
  # as skills. P050 generalises this to a codification category, with "skill"
  # retained as one worked example within the shape list. This test accepts
  # either the original P044 phrasing OR the P050 generalised phrasing that
  # still names "skill" as a shape.
  run grep -in "recurring workflow.*better as a skill\|would be better as a skill\|recurring pattern.*better codified\|\*\*Skill\*\* — " "$SKILL_FILE"
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

@test "SKILL.md Step 4b header matches ADR-013 structured-interaction pattern (P044, updated by P050)" {
  # P044 used "Skill candidate" as the AskUserQuestion header. P050 generalises
  # to "Codification candidate" with "Skill" as one shape option. Accept either —
  # both preserve the ADR-013 Rule 1 structured-interaction shape.
  run grep -in "Skill candidate\|Codification candidate" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 4b names the structured options for skill-shaped candidates (P044, updated by P050, reframed by P075)" {
  # P044 required three specific option labels (Create a new skill / Track as
  # a problem / Skip — not skill-worthy). P050 generalised to "Skill — create
  # stub". P075 reframes Step 4b as a two-stage flow: Stage 1 tickets
  # mechanically (the former "Track as a problem" decision disappears
  # because ticketing is no longer a user choice); Stage 2 asks the
  # fix-strategy question with four options. P044's recommend-new-skills
  # intent now rides in Stage 2 Option 1 (`Skill — create stub`). The
  # former "Skip — not skill-worthy / not codify-worthy" path becomes
  # Stage 2 Option 4 (`Self-contained work — no codification stub`) with a
  # Rule 6 audit note preventing silent-skip. Accept all three forms across
  # the P044 / P050 / P075 lineage.
  run grep -in "Create a new skill\|Skill — create stub\|Skill - create stub" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  # Stage 1 ticketing delegation is mechanical post-P075; assert the
  # delegation path is named in SKILL.md so the P044 "Track as a problem
  # ticket" enforcement intent still has a visible home.
  run grep -in "Track as a problem ticket\|Problem — invoke manage-problem\|/wr-itil:manage-problem\|/wr-itil:capture-problem" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  # The skip-equivalent path. P075 renamed this to "Self-contained work" so
  # P044's escape-hatch pain pattern does not leak; keep the legacy strings
  # in the regex for backward compatibility across the P044 / P050 / P075
  # lineage.
  run grep -in "Skip — not skill-worthy\|Skip - not skill-worthy\|Skip — not codify-worthy\|Skip - not codify-worthy\|Self-contained work — no codification stub\|Self-contained work - no codification stub" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 4b has non-interactive fallback per ADR-013 Rule 6" {
  # ADR-013 Rule 6: if AskUserQuestion is unavailable, flag candidates instead of
  # silently choosing. P044 implementation uses "flagged — not actioned" wording.
  run grep -n "non-interactive\|Rule 6" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 summary template has a Skill / Codification Candidates slot (P044, updated by P050)" {
  # P044 fix: the summary template must include a Skill Candidates section so
  # recommendations are visible in the session audit alongside BRIEFING changes
  # and problem tickets. P050 generalises this to a unified "Codification
  # Candidates" table with a Shape column; skill-shaped candidates still appear
  # (as Shape: skill rows). Accept either heading.
  run grep -n "### Skill Candidates\|### Codification Candidates" "$SKILL_FILE"
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
