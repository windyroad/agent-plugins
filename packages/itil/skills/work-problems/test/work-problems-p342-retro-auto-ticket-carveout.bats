#!/usr/bin/env bats

# P342: Iter retros queue their own observations as outstanding-questions
# for user-direction triage instead of auto-ticketing — same trust-
# boundary as /wr-retrospective:run-retro Step 4a (verification close-on-
# evidence).
#
# The fix shape amends the work-problems Step 5 iter-prompt body:
#   - Relax the "no capture-* siblings mid-loop" rule for RETRO-surfaced
#     observations specifically.
#   - Direct retro to auto-ticket recurring class-of-behaviour
#     observations via /wr-itil:capture-problem (mechanical-stage carve-
#     out per run-retro Step 4a precedent).
#   - Route ONLY direction-setting observations (genuine user-judgment-
#     bound questions) to outstanding_questions.
#   - Document the classification:
#       recurring class-of-behaviour / SKILL-contract drift / hook
#       misbehaviour / framework-gap → auto-ticket.
#       Direction-setting (design choice, deviation-approval, framework
#       boundary) → outstanding_questions.
#       Ambiguous → default to auto-ticket.
#
# Doc-lint contract assertions per ADR-037 Permitted Exception.
#
# @problem P342
# @adr ADR-044 (Decision-Delegation Contract — mechanical-stage carve-out per Step 4a precedent)
# @adr ADR-013 Rule 5 (policy-authorised silent proceed)
# @adr ADR-032 (governance skill invocation patterns — foreground-spawns-background fanout pattern for capture-*)
# @jtbd JTBD-006 (Progress the Backlog While I'm Away — durable WSJF-ranked backlog accumulation)
# @jtbd JTBD-201 (audit-trail — auto-ticketed observations become durable artefacts)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SKILL_MD="$REPO_ROOT/packages/itil/skills/work-problems/SKILL.md"
}

@test "work-problems P342: SKILL.md exists" {
  [ -f "$SKILL_MD" ]
}

# ── Step 5 iter-prompt: capture-* carve-out for retro observations ──────────

@test "work-problems P342: iter-prompt body carves out capture-* for retro-surfaced observations" {
  # The fix relaxes the "No capture-* siblings mid-loop" rule for RETRO
  # observations specifically. Existing P078-class spam rule remains for
  # non-retro mid-iter capture; the carve-out is bounded to retro.
  run grep -nE 'retro.*capture-\*|capture-\*.*retro|retro-surfaced.*capture|capture-problem.*retro' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P342: iter-prompt body directs retro to auto-ticket via /wr-itil:capture-problem" {
  # Recurring class-of-behaviour observations MUST route to
  # /wr-itil:capture-problem (mechanical-stage carve-out per run-retro
  # Step 4a precedent). The skill is named explicitly so adopters know
  # which capture sibling to invoke.
  run grep -nE '/wr-itil:capture-problem' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P342: iter-prompt cites Step 4a precedent for mechanical-stage carve-out" {
  # The carve-out's authority is the run-retro Step 4a verification
  # close-on-evidence precedent. Cite it so future authors don't unwind
  # the carve-out by re-applying the broad "no capture-* mid-loop" rule
  # uniformly.
  run grep -nE 'Step 4a precedent|run-retro Step 4a|Step 4a.*mechanical' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── Classification taxonomy ────────────────────────────────────────────────

@test "work-problems P342: iter-prompt classifies recurring class-of-behaviour as auto-ticket" {
  # Recurring class-of-behaviour / SKILL-contract drift / hook
  # misbehaviour / framework-gap → auto-ticket. The taxonomy MUST be
  # documented so future authors don't drift on classification.
  run grep -nE 'recurring class-of-behaviour|class-of-behaviour observation' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P342: iter-prompt classifies direction-setting as outstanding_questions" {
  # Direction-setting (design choice, deviation-approval, framework
  # boundary) → outstanding_questions. The route must be named so the
  # framework boundary is preserved.
  run grep -nE 'Direction-setting observation|direction-setting.*outstanding_questions' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P342: iter-prompt classifies ambiguous observations as default-to-auto-ticket" {
  # Ambiguous → default to auto-ticket. This is the trust-boundary
  # asymmetry that prevents observations from silently piling in the
  # queue file (per P342 Description).
  run grep -nE 'Ambiguous.*auto-ticket|default to auto-ticket|ambiguous.*default.*ticket' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── Trust-boundary mirror in run-retro Step 4b ─────────────────────────────

@test "work-problems P342: iter-prompt cross-references run-retro Step 4b carve-out symmetry" {
  # The run-retro Step 4b stage classification mirrors this carve-out so
  # the same trust-boundary applies whether retro fires in iter context
  # OR standalone in main turn. Cross-reference the sibling locus so the
  # symmetry is discoverable.
  run grep -nE 'run-retro.*Step 4b|Step 4b.*mirror|symmetry.*Step 4b|Step 4b.*carve-out' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── Cross-reference to P342 ────────────────────────────────────────────────

@test "work-problems P342: Related section cites P342 as the originating ticket" {
  run grep -nE '\*\*P342\*\*|P342\b' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── Anti-pattern preservation: P130 mid-loop ask discipline unaffected ─────

@test "work-problems P342: iter-prompt preserves P130 NEVER call AskUserQuestion mid-loop discipline" {
  # The P342 carve-out is for capture-* siblings on the retro path only;
  # the iter-prompt's mid-loop AskUserQuestion ban is unchanged.
  run grep -nE 'NEVER call .?AskUserQuestion.? mid-loop|MUST NOT call .?AskUserQuestion.? between iter' "$SKILL_MD"
  [ "$status" -eq 0 ]
}
