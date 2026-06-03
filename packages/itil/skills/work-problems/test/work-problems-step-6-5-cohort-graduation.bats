#!/usr/bin/env bats

# P246: /wr-itil:work-problems Step 6.5 cohort-graduation pre-check must
# invoke the deterministic graduation evaluator BEFORE the Drain action
# when the within-appetite-with-releasable-material branch fires AND
# docs/changesets-holding/ is non-empty.
#
# Refined framing (per user direction 2026-05-17): graduation criterion
# is positive evidence that the surface works as desired (ADR-061 Rule 4
# per-class evidence floor), NOT elapsed wall-clock time. Calendar
# predicates (`≥7 days in-repo dogfood`, `on or after <date>`) are NEVER
# a primary graduation trigger.
#
# Pre-check parses `GRADUATION_CANDIDATE` lines from the evaluator and
# branches per the 3-status taxonomy the evaluator actually emits:
#
#   status=resolved              → git mv from holding to .changeset/,
#                                   README "Recently reinstated" append,
#                                   amend iter commit per ADR-042 Rule 3
#                                   (policy-authorised silent proceed per
#                                    ADR-013 Rule 5 + ADR-061 Rule 5).
#   status=vp-blocked            → skip (ADR-061 Rule 2 VP carve-out).
#   status=halt-no-resolution    → halt at the framework-prescribed
#                                   "Step 6.5 cohort-graduation halt-
#                                   no-resolution" halt point (ADR-061
#                                   Rule 1a terminal).
#
# Class=3b cohorts graduate atomically per ADR-061 Rule 3b — entire
# cohort ships or none does.
#
# Doc-lint contract assertions per ADR-037 Permitted Exception (contract-
# assertion class). The asserted prose IS the load-bearing policy surface
# — re-reading SKILL.md is the only way an AFK reader (and the iteration
# subprocess) learns the new pre-check behaviour. These tests function as
# regression guards against re-introducing calendar-trigger framings,
# silently removing the pre-check, or drifting the 3-status branching.
#
# @problem P246
# @adr ADR-061 (parent principle — Rules 1/1a/2/3/4/5/6/7)
# @adr ADR-042 (Rule 3 amend-based folding for graduation reinstate commit)
# @adr ADR-018 (release-cadence policy parent — drain condition unchanged)
# @adr ADR-013 (Rule 5 policy-authorised silent proceed)
# @adr ADR-037 (skill-testing strategy — contract-assertion class)
# @adr ADR-044 (framework-resolution boundary — no AskUserQuestion mid-iter)
# @jtbd JTBD-006 (Progress the Backlog While I'm Away — primary)
# @jtbd JTBD-302 (Trust That the README Describes the Plugin I Just Installed)
# @jtbd JTBD-001 (Enforce Governance Without Slowing Down)
# @jtbd JTBD-101 (Extend the Suite with New Plugins)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SKILL_MD="$REPO_ROOT/packages/itil/skills/work-problems/SKILL.md"
  HOLDING_README="$REPO_ROOT/docs/changesets-holding/README.md"
}

# ── Preconditions ──────────────────────────────────────────────────────────

@test "work-problems P246: SKILL.md exists" {
  [ -f "$SKILL_MD" ]
}

@test "work-problems P246: changesets-holding README exists" {
  [ -f "$HOLDING_README" ]
}

# ── Pre-check sub-step exists and cites the evaluator shim ────────────────

@test "work-problems P246: SKILL.md Step 6.5 contains 'Cohort-graduation pre-check' sub-step" {
  run grep -nE 'Cohort-graduation pre-check.*ADR-061 Rule 5.*P246' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P246: pre-check invokes wr-risk-scorer-evaluate-graduation shim" {
  run grep -nE 'wr-risk-scorer-evaluate-graduation' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P246: pre-check fires BEFORE the Drain action (on within-appetite branch)" {
  # The pre-check must precede the Drain action heading; if SKILL.md
  # ever inverts the order, the just-graduated entries would not ride
  # the existing release flow.
  pre_check_line=$(grep -nE '^\*\*Cohort-graduation pre-check' "$SKILL_MD" | head -1 | cut -d: -f1)
  drain_line=$(grep -nE '^\*\*Drain action ' "$SKILL_MD" | head -1 | cut -d: -f1)
  [ -n "$pre_check_line" ]
  [ -n "$drain_line" ]
  [ "$pre_check_line" -lt "$drain_line" ]
}

# ── Three-status branching contract ───────────────────────────────────────

@test "work-problems P246/P308: status=resolved routes to Rule 4 evidence-floor judgement (NOT auto-graduate)" {
  # P308 amendment: status=resolved is necessary-but-not-sufficient.
  # The evaluator script disclaims Rule 4 (LLM-owned). SKILL prose must
  # surface Rule 4 evidence-floor judgement before any git mv.
  run grep -nE '`status=resolved`.*route to.*Rule 4 evidence-floor judgement' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P308: Rule 4-ratified graduate path performs git mv from holding to .changeset/" {
  # The git mv is downstream of the Rule 4 evidence-floor ratification,
  # not directly on the evaluator's status=resolved.
  run grep -nE 'git mv docs/changesets-holding/<basename> \.changeset/<basename>' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P308: Rule 4-ratified graduate path amends the iter commit per ADR-042 Rule 3" {
  run grep -nE 'Amend the iter.s main commit per ADR-042 Rule 3 amend-based folding' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P246: pre-check branches on status=vp-blocked → skip (ADR-061 Rule 2)" {
  run grep -nE '`status=vp-blocked`.*skip.*ADR-061 Rule 2' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P246: pre-check branches on status=halt-no-resolution → halt at framework-prescribed point" {
  run grep -nE '`status=halt-no-resolution`.*halt.*ADR-061 Rule 1a terminal' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P246: SKILL.md does NOT branch on non-existent status=no-graduate-evidence-floor" {
  # Architect verdict: the evaluator emits only resolved | vp-blocked |
  # halt-no-resolution. A SKILL branch handling a non-existent token
  # would be dead code (Confirmation Violation).
  run grep -nE 'no-graduate-evidence-floor' "$SKILL_MD"
  [ "$status" -ne 0 ]
}

# ── Cohort propagation (class=3b atomic) ──────────────────────────────────

@test "work-problems P246: class=3b cohorts graduate atomically (entire cohort ships or none does)" {
  run grep -nE 'class=3b cohorts.*ALL members.*graduate together atomically|cohort ships or none does' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P246: cohort propagation cites ADR-061 Rule 3b" {
  run grep -nE 'Rule 3b cohort propagation' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── Framework-prescribed halt point added ─────────────────────────────────

@test "work-problems P246: new halt point 'Step 6.5 cohort-graduation halt-no-resolution' in Mid-loop ask discipline list" {
  run grep -nE 'Step 6\.5 cohort-graduation halt-no-resolution halt.*P246' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P246: halt-no-resolution halt routes through Step 2.5b cross-reference" {
  # Architect verdict: halt-no-resolution must inherit the established
  # Step 2.5b routing pattern (CI failure / Rule 5 above-appetite /
  # dirty-unknown all route this way).
  run grep -nE 'cohort-graduation.*Step 2\.5b cross-reference|halt-with-batched-questions per the Step 2\.5b cross-reference' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P246: Mid-loop ask between iters row enumerates the new halt point" {
  run grep -nE 'Mid-loop ask between iters.*Step 6\.5 cohort-graduation halt-no-resolution halt' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── Non-Interactive Decision Making table reflects amendment ──────────────

@test "work-problems P246: Decision Making table carries the resolved-graduate row" {
  run grep -nE '\| Cohort-graduation pre-check.*status=resolved' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P246: Decision Making table carries the vp-blocked-skip row" {
  run grep -nE '\| Cohort-graduation pre-check.*status=vp-blocked' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P246: Decision Making table carries the halt-no-resolution-halt row" {
  run grep -nE '\| Cohort-graduation pre-check.*status=halt-no-resolution' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── Evidence-based criterion (calendar-trigger rejection) ─────────────────

@test "work-problems P246: pre-check states graduation criterion is evidence-of-working-as-desired, NOT elapsed wall-clock time" {
  run grep -nE 'evidence-of-working-as-desired.*not elapsed wall-clock time|not elapsed wall-clock time' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P246: pre-check explicitly rejects calendar predicates as primary triggers" {
  run grep -nE 'Calendar predicates are NEVER a primary graduation trigger' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P246: pre-check cites user direction verbatim ('Dogfooding makes sense, but it shouldn't be time based')" {
  run grep -nE "Dogfooding makes sense, but it shouldn.t be time based, it should be until we are happy that it.s working as desired" "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P246: pre-check cites user correction verbatim ('Why are we waiting?')" {
  run grep -nE "Why are we waiting\?.*That seems to go against the principles if you ask me" "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── Policy authorisation (ADR-013 Rules 1/5/6 + ADR-061 Rules 4/5 + P352) ─

@test "work-problems P308: pre-check cites ADR-061 Rule 4 as the LLM-owned evidence-floor surface" {
  # Rule 4 evidence-floor judgement is class-specific and LLM-owned per
  # ADR-044 framework-resolution boundary; surfacing it as AskUserQuestion
  # (interactive) or queue (AFK) is the load-bearing delegation surface.
  run grep -nE 'ADR-061 Rule 4' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P308: pre-check cites ADR-013 Rule 6 as the AFK queue-and-continue fail-safe" {
  # Per P352 user-ratified universal default: when AskUserQuestion is
  # unavailable (AFK iter), queue the question + continue — do NOT halt,
  # do NOT silently fail-soft, do NOT auto-default.
  run grep -nE 'ADR-013 Rule 6.*P352|P352.*ADR-013 Rule 6' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P308: pre-check cites ADR-061 Rule 5 (graduation criterion authorises intent, gates authorise action)" {
  run grep -nE 'ADR-061 Rule 5' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P308: interactive branch fires AskUserQuestion per-held-entry (not silent proceed)" {
  # The amendment lifts the prior silent-proceed clause — Rule 4 judgement
  # is LLM-owned; the user must ratify before the git mv.
  run grep -nE 'interactive.*AskUserQuestion.*per[- ]held[- ]entry|per[- ]held[- ]entry.*AskUserQuestion' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P308: AFK branch queues outstanding_question per held entry (queue-and-continue)" {
  run grep -nE 'AFK.*queue.*outstanding_question.*per held entry|queue.*outstanding_question.*per held entry.*AFK|AFK.*queue.*outstanding_question|outstanding_question.*do NOT graduate' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P308: AskUserQuestion option labels inline evidence + Rule 4 criterion (P350 brief-before-ID)" {
  # P350 empathy-gap correction: AskUserQuestion text must inline the
  # per-held-entry evidence summary + Rule 4 class-specific criterion;
  # opaque P-ID / ADR-ID references alone are non-compliant.
  run grep -nE 'P350|brief.*before.*ID|inline.*evidence' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── Governance gates apply (ADR-061 Rule 7) ───────────────────────────────

@test "work-problems P246: pre-check governance gates apply per ADR-061 Rule 7" {
  run grep -nE 'Governance gates apply.*ADR-061 Rule 7|graduation reinstate goes through the standard ADR-014 commit flow' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── Audit trail (ADR-061 Rule 6) ──────────────────────────────────────────

@test "work-problems P246: pre-check audit trail cites ADR-061 Rule 6" {
  run grep -nE 'Audit trail.*ADR-061 Rule 6' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P246: audit trail appends README 'Recently reinstated' entry" {
  run grep -nE 'Recently reinstated.*resolved problem-ticket ID.*Priority value|graduation criterion met.*status=resolved' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── Idempotency ───────────────────────────────────────────────────────────

@test "work-problems P246: pre-check is idempotent when holding-area is empty" {
  run grep -nE 'Idempotency.*holding-area is empty|safe to invoke when holding-area is empty' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P246: pre-check is idempotent when no candidates resolve (all vp-blocked)" {
  run grep -nE 'Safe when no candidates resolve.*all .vp-blocked.' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── Holding README Process amendment ──────────────────────────────────────

@test "work-problems P246: holding README Process step 5 cites P246 refined framing" {
  run grep -nE 'refined by P246|P246 refined framing' "$HOLDING_README"
  [ "$status" -eq 0 ]
}

@test "work-problems P246: holding README Process step 5 states criterion is positive evidence (NOT calendar)" {
  run grep -nE 'positive evidence that the surface works as desired' "$HOLDING_README"
  [ "$status" -eq 0 ]
}

@test "work-problems P246: holding README Process step 5 rejects calendar predicates as primary trigger" {
  run grep -nE 'Calendar predicates.*never.*primary graduation trigger|NEVER a primary graduation trigger' "$HOLDING_README"
  [ "$status" -eq 0 ]
}

@test "work-problems P246: holding README Process step 5 cites user direction verbatim" {
  run grep -nE "Dogfooding makes sense, but it shouldn.t be time based" "$HOLDING_README"
  [ "$status" -eq 0 ]
}

@test "work-problems P246: holding README Process step 5 enumerates the 3-status taxonomy" {
  run grep -nE 'status=<resolved\|vp-blocked\|halt-no-resolution>' "$HOLDING_README"
  [ "$status" -eq 0 ]
}

@test "work-problems P246: holding README Process step 5 explicitly preserves at-hold-time historical contracts" {
  # Architect verdict: per-entry Currently held lines authored BEFORE
  # the P246 framing are retained as at-hold-time historical contracts
  # (not retroactively rewritten).
  run grep -nE 'retained as at-hold-time historical contracts.*not retroactively rewritten' "$HOLDING_README"
  [ "$status" -eq 0 ]
}

# ── P246 self-identification (ticket-trace) ───────────────────────────────

@test "work-problems P246: SKILL.md self-identifies the cohort-graduation pre-check as P246's amendment" {
  run grep -nE 'P246' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P246: holding README self-identifies the Process amendment as P246's refined framing" {
  run grep -nE 'P246' "$HOLDING_README"
  [ "$status" -eq 0 ]
}

# ── P308 self-identification (ticket-trace) ───────────────────────────────

@test "work-problems P308: SKILL.md self-identifies the Rule 4 evidence-floor amendment as P308" {
  run grep -nE 'P308' "$SKILL_MD"
  [ "$status" -eq 0 ]
}
