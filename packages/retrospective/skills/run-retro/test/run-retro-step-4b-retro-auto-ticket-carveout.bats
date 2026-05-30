#!/usr/bin/env bats
#
# packages/retrospective/skills/run-retro/test/run-retro-step-4b-retro-auto-ticket-carveout.bats
#
# P342: run-retro Step 4b stage classification must mirror the trust-
# boundary established at Step 4a (verification close-on-evidence) — so
# the same mechanical-stage carve-out applies whether retro fires in iter
# context (work-problems Step 5 iter-prompt) OR standalone in main turn.
#
# The fix shape amends Step 4b stage classification:
#   - Mechanical-auto-ticket path: recurring class-of-behaviour /
#     SKILL-contract drift / hook misbehaviour / framework-gap → Stage 1
#     auto-creates a ticket via /wr-itil:capture-problem (or
#     manage-problem if capture sibling not yet available).
#   - Direction-setting-queue path: genuine user-judgment-bound questions
#     (design choice, deviation-approval, framework boundary) → queued
#     as outstanding_questions for orchestrator-level Step 2.5 surface
#     when retro runs inside an AFK iter; surfaced at retro end when
#     standalone.
#   - Ambiguous → default to mechanical-auto-ticket (per P342 trust-
#     boundary asymmetry preventing silent queue accumulation).
#
# Contract-assertion tests per ADR-037 Permitted Exception (structural
# checks on prose contract; behavioural harness for SKILL.md pending
# P081 Phase 2 / P012).
#
# @problem P342
# @adr ADR-044 (Decision-Delegation Contract — mechanical-stage carve-out per Step 4a precedent)
# @adr ADR-013 Rule 5 (policy-authorised silent proceed for capture-* on retro path)
# @adr ADR-014 (governance skills commit own work — capture-problem commits per ticket)
# @adr ADR-032 (foreground-spawns-N-background fanout pattern already documented for Stage 1)
# @jtbd JTBD-006 (durable WSJF-ranked backlog accumulation)
# @jtbd JTBD-201 (audit-trail integrity)

SKILL_FILE="${BATS_TEST_DIRNAME}/../SKILL.md"

setup() {
  [ -f "$SKILL_FILE" ]
}

# ── Step 4b carve-out subsection presence ───────────────────────────────────

@test "Step 4b P342: SKILL.md names the mechanical-auto-ticket vs direction-setting-queue split" {
  # The fix establishes a classification split at Stage 1 routing.
  # Mechanical-class observations route to auto-ticket; direction-class
  # to outstanding_questions queue.
  run grep -F "mechanical-auto-ticket" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4b P342: SKILL.md cites Step 4a precedent for the mechanical-stage carve-out" {
  # The carve-out's authority is the Step 4a verification close-on-
  # evidence precedent. Cite explicitly so the trust-boundary symmetry
  # is discoverable.
  run grep -nE 'Step 4a precedent|same trust[- ]boundary.*Step 4a|Step 4a.*precedent' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4b P342: SKILL.md names recurring class-of-behaviour as auto-ticket route" {
  # Recurring class-of-behaviour / SKILL-contract drift / hook
  # misbehaviour / framework-gap → auto-ticket. The taxonomy must be
  # documented at Step 4b so the same classification fires whether retro
  # runs in iter context OR standalone.
  run grep -nE 'recurring class-of-behaviour|class-of-behaviour observation' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4b P342: SKILL.md names direction-setting as outstanding_questions route" {
  # Direction-setting (design choice, deviation-approval, framework
  # boundary) → outstanding_questions when retro runs inside an AFK
  # iter; surfaced at retro end when standalone.
  run grep -nE 'direction-setting.*outstanding_questions|Direction-setting observation' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4b P342: SKILL.md names ambiguous default-to-auto-ticket asymmetry" {
  # Per P342 trust-boundary asymmetry: ambiguous → default to auto-
  # ticket. This prevents the silent-queue accumulation P342 was filed
  # to close.
  run grep -nE 'Ambiguous.*auto-ticket|default to auto-ticket|ambiguous.*default.*ticket' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ── Cross-reference to work-problems Step 5 iter-prompt carve-out ──────────

@test "Step 4b P342: SKILL.md cross-references work-problems Step 5 iter-prompt symmetry" {
  # The work-problems iter-prompt amendment is the sibling locus — the
  # same trust-boundary fires in both surfaces. Cross-reference so the
  # symmetry is discoverable from either side.
  run grep -nE 'work-problems Step 5|work-problems.*iter-prompt|Step 5 iter-prompt' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ── ADR-044 framework-resolution boundary citation ─────────────────────────

@test "Step 4b P342: SKILL.md cites ADR-044 as the framework-resolution authority for the carve-out" {
  run grep -F "ADR-044" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ── ADR-014 commit ownership preserved ─────────────────────────────────────

@test "Step 4b P342: SKILL.md preserves ADR-014 capture-* commit ownership for auto-ticket path" {
  # capture-problem (or manage-problem fallback) commits per ADR-014;
  # run-retro does not commit auto-ticket creates.
  run grep -F "ADR-014" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ── P342 ticket cross-reference ─────────────────────────────────────────────

@test "Step 4b P342: SKILL.md cites P342 as the trust-boundary mirror ticket" {
  run grep -nE 'P342\b' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
