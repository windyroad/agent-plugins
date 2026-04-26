#!/usr/bin/env bats

# P126: work-problems halt paths must route accumulated user-answerable
# skips through Step 2.5's surfacing routine before emitting the AFK
# summary. P122 fixed the routing at Step 2.5 stop-condition #2; P126
# extends the same contract to the remaining halt paths (Step 0
# session-continuity, Step 0 fetch failure, Step 6.5 CI-failure, Step
# 6.5 ADR-042 Rule 5, Step 6.75 dirty-for-unknown-reason).
#
# The fix shape: extract Step 2.5's surfacing routine into a reusable
# named sub-step (Step 2.5b) that every halt path cross-references
# before emitting its summary. Empty-skip halts skip the round-trip
# (gating clause: ≥1 user-answerable skip accumulated).
#
# Doc-lint contract assertions per ADR-037 Permitted Exception
# (structural checks on prose contract, not behavioural coverage).
#
# @problem P126
# @jtbd JTBD-001 (Enforce Governance Without Slowing Down)
# @jtbd JTBD-006 (Progress the Backlog While I'm Away)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SKILL_MD="$REPO_ROOT/packages/itil/skills/work-problems/SKILL.md"
  BRIEFING_MD="$REPO_ROOT/docs/briefing/afk-subprocess.md"
}

@test "work-problems P126: SKILL.md exists" {
  [ -f "$SKILL_MD" ]
}

@test "work-problems P126: SKILL.md names Step 2.5b as the reusable surfacing routine" {
  # The fix extracts Step 2.5's AskUserQuestion-when-available-else-table
  # logic into a named reusable sub-step that halt paths can cross-reference
  # uniformly. The name MUST appear as a heading or anchor so cross-references
  # resolve to a single source of truth.
  run grep -F 'Step 2.5b' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P126: Step 2.5b heading exists in SKILL.md" {
  # Stronger structural check: Step 2.5b must be a markdown heading (### or
  # ####) so it is a navigable anchor, not just an inline mention.
  run grep -E '^#{3,4} Step 2\.5b' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P126: Step 2.5b preserves the AskUserQuestion default branch" {
  # Step 2.5b must inherit P122's interactive-default routing — calling
  # AskUserQuestion when available is the load-bearing fix.
  run grep -F 'AskUserQuestion' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P126: Step 2.5b preserves the table fallback for ADR-013 Rule 6" {
  # Rule 6 fail-safe: when AskUserQuestion is unavailable, emit the
  # Outstanding Design Questions table.
  run grep -F 'Outstanding Design Questions' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P126: Step 2.5b is gated on at least one accumulated user-answerable skip" {
  # The gating clause prevents empty-skip halts from triggering an
  # unnecessary round-trip. Architect-flagged refinement: the gate clause
  # must be named in Step 2.5b so future authors don't copy-paste cross-
  # references and forget the gate.
  run grep -nE 'at least one accumulated user-answerable skip|≥ ?1 (accumulated )?user-answerable skip|>= ?1 user-answerable skip|one or more user-answerable skip' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P126: Step 0 session-continuity halt cross-references Step 2.5b" {
  # P109's Step 0 AFK fallback halts with a Prior-Session State report.
  # When iters have accumulated user-answerable skips before the halt fires
  # (rare at Step 0 since iters haven't run yet, but the contract must be
  # uniform), the halt must run Step 2.5b first.
  run grep -nE 'Step 0.*Step 2\.5b|session-continuity.*Step 2\.5b' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P126: Step 0 fetch failure halt cross-references Step 2.5b" {
  # Step 0's git fetch network failure halt also emits a final summary
  # without iter context — the cross-reference is for contract uniformity
  # even when no skips can accumulate at Step 0.
  run grep -nE 'fetch.*Step 2\.5b|Network failure.*Step 2\.5b|fetch failure.*Step 2\.5b' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P126: Step 6.5 CI-failure halt cross-references Step 6.5b" {
  # The Step 6.5 "Failure handling" clause halts on push:watch / release:watch
  # failure. After N iters this halt path frequently has accumulated user-
  # answerable skips (the empirically observed P126 surface).
  run grep -nE 'Failure handling.*Step 2\.5b|CI failure.*Step 2\.5b|release:watch.*Step 2\.5b' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P126: Step 6.5 ADR-042 Rule 5 halt cross-references Step 2.5b with halt-vs-prior-skip guard" {
  # Architect-flagged refinement: the cross-reference under Rule 5 halt
  # must explicitly distinguish "Step 2.5b surfaces prior-iter accumulated
  # skips" from "ADR-042 Rule 5 halt remains the bug signal — the user is
  # NOT asked how to remediate the above-appetite state". Two grep checks:
  # cross-reference present AND the guard prose present nearby.
  run grep -nE 'Rule 5.*Step 2\.5b|halted-above-appetite.*Step 2\.5b' "$SKILL_MD"
  [ "$status" -eq 0 ]
  # Guard: prior-iter accumulated skips are surfaced; the halt-causing
  # scorer-gap remains a halt with bug-signal.
  run grep -nE 'prior[- ]iter accumulated|surfaces? prior[- ]iter|NOT ask the user how to remediate|halt-causing scorer[- ]gap' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P126: Step 6.75 dirty-for-unknown-reason halt cross-references Step 2.5b" {
  # P036's Step 6.75 inter-iter verification halt emits a final summary
  # when git status is dirty for unknown reason between iters. After N
  # iters this halt path is the second most common P126 surface
  # empirically.
  run grep -nE 'Dirty for an unknown reason.*Step 2\.5b|dirty[- ]for[- ]unknown[- ]reason.*Step 2\.5b|Step 6\.75.*Step 2\.5b' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P126: Step 2.5 still cross-references Step 2.5b (single source of truth)" {
  # The original Step 2.5 stop-condition #2 branch must also call into
  # Step 2.5b — keeping the surfacing logic in one place rather than
  # duplicated between Step 2.5 and Step 2.5b.
  run grep -nE 'Step 2\.5 .*Step 2\.5b|Step 2\.5b.*surfacing|Step 2\.5\b.*calls? Step 2\.5b' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P126: Decisions Table row exists for halt-paths-cross-route via Step 2.5b" {
  # The "Non-Interactive Decision Making" Decisions Table at the bottom
  # of SKILL.md must carry a row that names the cross-halt routing so the
  # decision summary is consistent with the Step prose.
  run grep -nE '\| Halt[- ]path .*Step 2\.5b|halt path.*accumulated user-answerable' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P126: Briefing entry documents the halt-paths-must-route principle" {
  # The cross-session briefing entry must record the principle alongside
  # the existing P122 entry so future sessions inherit the reasoning.
  [ -f "$BRIEFING_MD" ]
  run grep -nE 'P126|halt[- ]paths[- ]must[- ]route|halt-paths-must-route-design-questions-through-Step-2\.5' "$BRIEFING_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P126: Briefing entry cross-references P122" {
  # Architect-flagged refinement: the briefing entry must cite both
  # P122 (parent) and P126 (extension) so the principle's evolution is
  # traceable.
  run grep -nE 'P122' "$BRIEFING_MD"
  [ "$status" -eq 0 ]
}
