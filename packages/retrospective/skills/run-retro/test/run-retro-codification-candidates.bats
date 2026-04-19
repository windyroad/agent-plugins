#!/usr/bin/env bats
# Doc-lint guard: run-retro SKILL.md must include a generalised codification
# branch that recommends agents, hooks, and other codifiable outputs — not
# only skills. This is the P050 generalisation of P044's single-output-type
# recommendation surface, extended by P051 with an improvement axis for
# existing codifiables.
#
# Structural assertion — Permitted Exception to the source-grep ban (ADR-005 / P011).
# These tests assert that the skill specification document includes the
# multi-shape codification branch introduced by P050 and the improvement-axis
# extension introduced by P051.
#
# Cross-reference:
#   P051: docs/problems/051-run-retro-does-not-recommend-improvements-to-existing-codifiables.open.md
#   P050: docs/problems/050-run-retro-does-not-recommend-other-codifiable-outputs.known-error.md
#   P044: docs/problems/044-run-retro-does-not-recommend-new-skills.known-error.md (predecessor)
#   ADR-013 Rule 1 / Rule 6 (docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md)
#   @jtbd JTBD-101 (extend the suite with clear patterns)
#   @jtbd JTBD-006 (progress the backlog while I'm away — AFK-safe Rule 6 fallback)
#   @jtbd JTBD-001 (enforce governance without slowing down)

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

@test "SKILL.md Step 2 includes a generalised codification reflection category (P050)" {
  # P050 fix: Step 2 must prompt for recurring patterns that would be better
  # codified — not only as skills. The generalised wording names "codif"
  # (codification / codifiable / codified) so reviewers and agents can tell
  # P050 shipped.
  run grep -in "codification candidate\|codifiable\|codify\|codified" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 2 names at least three codification shapes beyond skills (P050)" {
  # The shape question is the point of P050. Names at minimum: agent, hook,
  # and one of: settings, script, CI step, ADR, JTBD, guide, test. "skill"
  # stays in the list as a worked example so P044 muscle memory survives.
  run grep -ic "agent" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
  run grep -ic "hook" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
  run grep -icE "settings|script|ci step|ADR|JTBD|guide|test fixture" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}

@test "SKILL.md Step 4b recommendation branch covers multiple shapes (P050)" {
  # Step 4b must route per-shape. The recommendation branch names more than
  # just "skill" as an output type.
  run grep -inE "(agent|hook).*stub|stub.*(agent|hook)|create.*(agent|hook)|(agent|hook).*candidate" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 4b uses a single AskUserQuestion with shape-prefixed options (ADR-013 Rule 1)" {
  # Architect decision: flat AskUserQuestion with type-prefixed labels, not a
  # two-step chained flow. At least three shape-prefixed option lines must
  # appear in the Step 4b block. Match both plain and backticked forms:
  #   "Skill — ..." / "`Skill — ...`" / "**Skill** — ..."
  run grep -cE "(\`|\*\*)?(Skill|Agent|Hook|Settings|Script|CI|ADR|JTBD|Guide|Problem|Test fixture|Memory)(\`|\*\*)? +(—|-) " "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [ "$output" -ge 3 ]
}

@test "SKILL.md Step 4b routes ADR candidates to wr-architect:create-adr (P050)" {
  # Dedicated codification skills already exist — Step 4b must route to them,
  # not duplicate intake.
  run grep -in "wr-architect:create-adr\|/wr-architect:create-adr" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 4b routes JTBD candidates to wr-jtbd:update-guide (P050)" {
  run grep -in "wr-jtbd:update-guide\|/wr-jtbd:update-guide" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 4b preserves non-interactive fallback for generalised shapes (ADR-013 Rule 6)" {
  # The Rule 6 fallback that P044 introduced must cover the generalised surface.
  # When AskUserQuestion is unavailable, all shape candidates are flagged rather
  # than silently chosen.
  run grep -in "non-interactive\|Rule 6" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 summary has a Codification Candidates section with Shape column (P050)" {
  # P050 candidate fix (3): unified table. Either:
  #   - a "### Codification Candidates" heading AND a "Shape" column, OR
  #   - a "### Codification Candidates" heading with per-shape rows.
  # Accept either shape but require the heading.
  run grep -n "### Codification Candidates\|## Codification Candidates" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -in "shape" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md retains 'skill' as a worked example within the generalised category (backward compat with P044)" {
  # Architect advisory: keep 'skill' in the shape list as one worked example so
  # the existing P044 muscle memory and the run-retro-skill-candidates.bats
  # line-30 grep still pass. This is the compatibility test.
  run grep -in "would be better as a skill\|better as a skill\|as a skill\|skill candidate" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# P051 improvement-axis assertions
#
# P051 extends the P050 codification surface with an improvement axis so
# existing skills, agents, hooks, ADRs, and guides can be recommended for
# targeted edits (not only new creation). The architect decision requires:
#   - flat shape-prefixed option list (no two-step create-vs-improve question)
#   - parallel naming (e.g. `Skill — improvement stub` mirrors
#     `Skill — create stub`)
#   - Kind column in the Step 5 summary table (create / improve)
#   - non-interactive fallback records the improvement Kind alongside Shape
# ---------------------------------------------------------------------------

@test "SKILL.md Step 2 includes an improvement reflection category for existing codifiables (P051)" {
  # P051 fix: Step 2 must prompt for flaws observed in existing skills /
  # agents / hooks / ADRs / guides — the improvement axis. The generalised
  # phrasing names "improvement" or "improve" alongside "codification" so
  # reviewers and agents can tell P051 shipped.
  run grep -inE "existing (skill|agent|hook|codifiable).*(flaw|friction|gap|improve|improvement)|improvement(-| )shaped|improvement reflection|improvement candidate|improve an existing" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 4b names improvement-shaped options for multiple shapes (P051)" {
  # P051 fix: the flat option list must carry `Skill — improvement ...`,
  # `Agent — improvement ...`, and `Hook — improvement ...` rows in addition
  # to the create-stub rows introduced by P050. Match at least three
  # shape-prefixed improvement options.
  run grep -cE "(\`|\*\*)?(Skill|Agent|Hook|ADR|Guide|Problem)(\`|\*\*)? +(—|-) +(improvement|supersede|amend|edit)" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [ "$output" -ge 3 ]
}

@test "SKILL.md Step 4b routes improvement-axis ADR candidates to create-adr with supersede hint (P051)" {
  # ADR improvement shape is "supersede or amend an existing ADR". The
  # routing target stays `/wr-architect:create-adr` (it writes the new ADR
  # with a supersedes reference) — P051 adds the supersede/amend wording as
  # a shape-prefixed option so the improvement axis is recognisable.
  # Require both: an `ADR — supersede` (or equivalent) shape-prefixed option
  # AND a route through `wr-architect:create-adr` near that option.
  run grep -inE "(\`|\*\*)?ADR(\`|\*\*)? +(—|-) +(supersede|amend)" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 summary distinguishes create from improve via a Kind column (P051)" {
  # P051 candidate fix (3): the Codification Candidates table gains a `Kind`
  # column carrying `create` / `improve`. Accept either a literal "Kind"
  # column header or explicit `create / improve` values cited in the summary
  # template. Both forms signal that the summary separates the two axes.
  run grep -inE "\| *Kind *\||Kind column|Kind.*create.*improve|create / improve|create/improve" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 4b non-interactive fallback covers improvement candidates (P051 + ADR-013 Rule 6)" {
  # Rule 6 fallback must mention the improvement axis explicitly so an AFK
  # loop that flags an improvement candidate records Kind=improve alongside
  # Shape (per architect advisory — the audit trail needs both axes for
  # improvements). Accept either explicit Kind=improve language in the
  # fallback block, OR a statement that the fallback records the Kind
  # alongside Shape.
  run grep -inE "flagged.*improve|improvement.*flagged|Kind.*(Shape|alongside)|(Shape|alongside).*Kind" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
