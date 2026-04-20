#!/usr/bin/env bats
# Doc-lint guard: run-retro SKILL.md Step 4b must implement the two-stage
# ticket-first flow introduced by P075. Every codify-worthy observation files
# a problem ticket first (mechanical, Stage 1); the codification shape is
# recorded as the proposed fix strategy on the ticket (user-interactive,
# Stage 2). The 19-option flat AskUserQuestion is removed.
#
# Structural assertion — Permitted Exception to the source-grep ban
# (ADR-005 / P011 / ADR-037 contract-assertion pattern). These tests assert
# that the SKILL.md contract document carries the new two-stage structure
# and the architect-required audit notes.
#
# @problem P075
# @jtbd JTBD-001 (enforce governance without slowing down — removes redundant ticketing axis)
# @jtbd JTBD-006 (progress the backlog while I'm away — AFK-safe Rule 6 fallback)
# @jtbd JTBD-101 (extend the suite with clear patterns)
# @jtbd JTBD-201 (audit trail of AI-assisted work — every observation lands in the backlog)
#
# Cross-reference:
#   P075: docs/problems/075-run-retro-codification-prompt-redundant-every-observation-is-a-problem.open.md
#   P016: concern-boundary split preserved in Stage 1
#   P044 / P050 / P051: reframed by P075 — fix-strategy on a problem ticket, not one option among 19
#   ADR-013 Rule 1 / Rule 6 (docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md)
#   ADR-032 (docs/decisions/032-governance-skill-invocation-patterns.proposed.md) —
#     foreground-spawns-N-background-fanout pattern and deferred-question contract
#   ADR-037 (docs/decisions/037-skill-testing-strategy.proposed.md) — contract-assertion bats pattern

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

@test "SKILL.md Step 4b has Stage 1 and Stage 2 headings (P075)" {
  # Two-stage flow is the load-bearing shape of the P075 fix.
  run grep -inE "Stage 1[: —-]|### Stage 1|\*\*Stage 1\*\*" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -inE "Stage 2[: —-]|### Stage 2|\*\*Stage 2\*\*" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 4b Stage 1 delegates to manage-problem (P075)" {
  # Stage 1 fires mechanically: every codify-worthy observation becomes a
  # problem ticket via the ticket-creation delegation path. Accept either the
  # foreground manage-problem path or the future capture-problem background
  # path (ADR-032 sibling).
  run grep -inE "/wr-itil:manage-problem|/wr-itil:capture-problem" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 4b Stage 1 is mechanical — no ticketing AskUserQuestion (P075)" {
  # The P075 user directive: "The answer should always be 'create a problem
  # ticket' so the question is redundant." Stage 1 must NOT present
  # ticketing as an AskUserQuestion option alongside other shapes. The
  # literal "Problem — invoke manage-problem" option from the legacy
  # 19-option flat list must be gone.
  run grep -in "Problem — invoke manage-problem\|Problem - invoke manage-problem" "$SKILL_FILE"
  [ "$status" -ne 0 ]
}

@test "SKILL.md Step 4b Stage 2 uses AskUserQuestion with 'Proposed fix' header (P075)" {
  # Stage 2 is the per-ticket fix-strategy prompt. Architect-pinned header is
  # "Proposed fix" to distinguish from the legacy "Codification candidate" header.
  run grep -inE "header:[[:space:]]*['\"]Proposed fix['\"]|\"Proposed fix\"" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 4b Stage 2 has four top-level architect-pinned options (ADR-013 Rule 1 cap)" {
  # ADR-013 Rule 1: AskUserQuestion options capped at 4. Architect review
  # flagged cascading follow-ups as an anti-pattern (P061 precedent); the
  # architect lean is free-text capture on the Fix Strategy section rather
  # than N-deep fan-out. Stage 2 must list the four architect-pinned option
  # labels as numbered Markdown list items.
  run grep -cE "^[[:space:]]*[0-9]+\.[[:space:]]+\`?(Skill — create stub|Skill — improvement stub|Other codification shape|Self-contained work)" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [ "$output" -ge 4 ]
}

@test "SKILL.md Step 4b Stage 2 option 4 is 'Self-contained work — no codification stub' (P075 + architect Q2)" {
  # Architect Q2: the "no codification" option must not re-create the P044
  # escape hatch. Required rename to "Self-contained work — no codification
  # stub" with a Rule 6 audit note clarifying the valid scope.
  run grep -inE "Self-contained work[[:space:]]*—[[:space:]]*no codification stub" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 4b Stage 2 option 4 carries a Rule 6 audit note (P075 + architect Q2)" {
  # Architect-required audit note: Option 4 valid only when the problem is a
  # bounded one-shot edit with no recurring-pattern signal. Protects P044's
  # recommend-skills intent from leaking.
  run grep -inE "bounded one-shot|no recurring[- ]pattern signal|not a recurring pattern|one-shot edit" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 4b Stage 2 option 3 captures 'Other codification shape' via free-text (P075 + architect Q4)" {
  # Architect Q4 lean (b): free-text Fix Strategy capture, not cascading
  # AskUserQuestion batches. The option must name the free-text capture
  # path so downstream readers can tell cascading was rejected.
  run grep -inE "Other codification shape.*free[- ]text|free[- ]text.*Fix Strategy|free[- ]text capture" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 4b records proposed fix on the ticket's '## Fix Strategy' section (P075)" {
  # Fix strategy lives on the ticket, not in the retro summary. This is the
  # structural invariant that decouples ticketing (Stage 1) from codification
  # (Stage 2).
  run grep -inE "## Fix Strategy|Fix Strategy section" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 4b cites ADR-032 for Stage 1 foreground-spawns-N-background fanout (architect Q1)" {
  # Architect Q1: Stage 1 is a legitimate foreground-spawns-N-background case
  # that ADR-032 does not currently contemplate. The SKILL.md must cite
  # ADR-032 explicitly so the cross-plugin ownership boundary is legible.
  run grep -inE "ADR-032|032-governance-skill-invocation-patterns" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 4b Stage 2 AFK fallback defers via deferred-question contract (P075 + architect Q3)" {
  # Architect Q3: ADR-032 lines 90-110 define the deferred-question artefact
  # shape (pending-questions + resumption context, FIFO). Stage 2 AFK branch
  # must cite that contract, not re-invent a new artefact.
  run grep -inE "deferred[- ]question|deferred question|pending[- ]question" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 4b Stage 1 preserves P016 concern-boundary split (P075)" {
  # Stage 1's mechanical ticketing must still apply the concern-boundary rule
  # so multi-concern observations split into separate tickets, not land as one
  # conflated ticket.
  run grep -inE "P016|concern[- ]boundary" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 4b retains ADR-013 Rule 6 non-interactive fallback (P075)" {
  # Rule 6 must still apply: when AskUserQuestion is unavailable, Stage 2
  # defers; Stage 1 fires regardless because it is mechanical.
  run grep -inE "Rule 6|non-interactive" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 4b drops the legacy 19-option flat list (P075 regression guard)" {
  # The legacy flat list had option rows like "Settings — propose entry",
  # "CI — propose step", "Test fixture — create stub", "Memory — propose
  # note". Those rows are replaced by Stage 2 Option 3's free-text capture.
  # This test is the regression guard — the legacy rows must not survive
  # the rewrite.
  run grep -inE "^[[:space:]]+[0-9]+\.[[:space:]]+\`?Settings[[:space:]]*—[[:space:]]*propose entry" "$SKILL_FILE"
  [ "$status" -ne 0 ]
  run grep -inE "^[[:space:]]+[0-9]+\.[[:space:]]+\`?CI[[:space:]]*—[[:space:]]*propose step" "$SKILL_FILE"
  [ "$status" -ne 0 ]
  run grep -inE "^[[:space:]]+[0-9]+\.[[:space:]]+\`?Test fixture[[:space:]]*—[[:space:]]*create stub" "$SKILL_FILE"
  [ "$status" -ne 0 ]
  run grep -inE "^[[:space:]]+[0-9]+\.[[:space:]]+\`?Memory[[:space:]]*—[[:space:]]*propose note" "$SKILL_FILE"
  [ "$status" -ne 0 ]
}
