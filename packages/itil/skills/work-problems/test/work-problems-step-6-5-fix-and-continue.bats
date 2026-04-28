#!/usr/bin/env bats

# P140: /wr-itil:work-problems Step 6.5 Failure handling subsection must
# document diagnose-then-classify routing — fix-and-continue for the
# documented mechanically-fixable allow-list, halt for everything else.
#
# Prior behaviour was a uniform halt-on-CI-failure rule that converted
# 1-line stale-grep-string updates and transient flakes into ~45min queue
# stalls, regressing JTBD-006 "Progress the Backlog While I'm Away"
# without any governance benefit. P140's Phase 1 amendment replaces that
# uniform rule with a closed allow-list policy authorising silent
# fix-and-continue per ADR-013 Rule 5, capped at 3 retries per iteration
# before falling back to the halt branch.
#
# Doc-lint contract assertions per ADR-037 Permitted Exception
# (contract-assertion class — same shape as the P130 / P126 / P135
# sibling fixtures). The asserted prose IS the load-bearing policy
# surface — re-reading the SKILL.md is the only way an AFK reader (and
# the iteration subprocess) learns the fixable-class taxonomy and the
# retry cap. Behavioural verification is impossible until Phase 2's
# advisory classifier ships (deferred per the ticket Fix Strategy —
# observe over 30 days).
#
# @problem P140
# @adr ADR-013 (Rule 5 — policy-authorised silent action)
# @adr ADR-014 (one-commit-per-iter; retries each ride their own commit)
# @adr ADR-018 (inter-iteration release cadence; this refines its
#       Failure handling clause)
# @adr ADR-026 (agent output grounding — diagnostic preamble citation)
# @adr ADR-037 (skill-testing strategy — contract-assertion class)
# @adr ADR-042 (above-appetite branch — Rule 3 commit-gate-per-retry
#       precedent composes with this fix-and-continue branch)
# @adr ADR-044 (decision-delegation contract — framework-resolution
#       boundary; closed allow-list extensions are deviation-candidates)
# @jtbd JTBD-006 (Progress the Backlog While I'm Away — primary)
# @jtbd JTBD-001 (Enforce Governance Without Slowing Down — composes;
#       per-retry gates preserve governance)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SKILL_MD="$REPO_ROOT/packages/itil/skills/work-problems/SKILL.md"
}

@test "work-problems P140: SKILL.md exists" {
  [ -f "$SKILL_MD" ]
}

# ── Failure handling subsection identity ───────────────────────────────────

@test "work-problems P140: Step 6.5 Failure handling subsection cites P140" {
  # The amendment must self-identify so future readers tracing back from
  # the ticket find the load-bearing prose without keyword-guessing.
  run grep -nE 'Failure handling.*P140|P140.*Failure handling' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── Diagnostic preamble (ADR-026 grounding) ────────────────────────────────

@test "work-problems P140: Failure handling cites gh run view --log-failed as the diagnostic preamble" {
  # ADR-026 grounding: the orchestrator MUST read the actual failure
  # output before classifying. Without this, classification degrades to
  # guess-from-context.
  run grep -nE 'gh run view.*--log-failed' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P140: Failure handling cites ADR-026 (grounding) on the diagnostic preamble" {
  # The grounding requirement should cite ADR-026 explicitly so the
  # connection is auditable.
  run grep -nE 'ADR-026' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── Fixable-in-iter allow-list (closed) ────────────────────────────────────

@test "work-problems P140: Failure handling names P081-class stale-grep-string as a fixable class" {
  run grep -nE 'P081-class stale-grep-string|stale-grep-string' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P140: Failure handling names hook stub mismatch as a fixable class" {
  run grep -niE 'hook stub mismatch' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P140: Failure handling names test ID drift as a fixable class" {
  run grep -niE 'test ID drift' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P140: Failure handling names environmental flake as a fixable class" {
  run grep -niE 'environmental flake' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P140: allow-list is framed as 'closed' (not extensible at agent discretion)" {
  # JTBD review guard-rail: persona could misread "fix-and-continue" as
  # "auto-fix anything" without the closed framing. Future agent edits
  # must not drift the allow-list open without explicit user direction.
  run grep -niE 'allow-list.*closed|closed.*allow-list' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P140: extending the allow-list is framed as a deviation-candidate per ADR-044" {
  # ADR-044 framework-resolution boundary: the closed list IS the
  # framework-resolved policy. Adding a class is a direction-setting
  # decision, not a mechanical fix.
  run grep -niE 'deviation-candidate.*ADR-044|ADR-044.*deviation' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P140: ambiguous classification defaults to halt (no diagnose-then-guess)" {
  # JTBD review guard-rail (b): without this, the persona-misread risk
  # of "auto-fix anything" re-enters via fuzzy classification.
  run grep -niE 'Ambiguous classification defaults to halt|ambiguous.*halt' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── Fix-and-continue branch ────────────────────────────────────────────────

@test "work-problems P140: Failure handling documents a fix-and-continue branch" {
  run grep -niE 'Fix-and-continue branch|fix-and-continue branch' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P140: each fix-and-continue retry rides standard ADR-014 commit gate flow (architect / JTBD / risk-scorer)" {
  # Architect-flagged invariant: governance gates MUST run on every
  # retry. The fix-and-continue branch does NOT bypass gates.
  run grep -niE 'standard ADR-014 commit gate flow|ADR-014.*commit gate' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P140: ADR-042 Rule 3 commit-gate-per-retry precedent is cross-referenced" {
  # ADR-042 already establishes that retries each ride their own
  # commit through full gate flow. P140 composes with that precedent
  # rather than inventing a new commit-cardinality rule.
  run grep -niE 'ADR-042 Rule 3' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── 3-retry cap (per iteration) ────────────────────────────────────────────

@test "work-problems P140: Failure handling caps fix-and-continue at 3 retries" {
  run grep -niE '3-retry cap|3 retr|three retr' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P140: 3-retry cap is per-iteration, not per-failure-class" {
  # Without this clarification, an agent could reset the counter on
  # each new failure class and drain budget indefinitely.
  run grep -niE 'per[- ]iteration, not per[- ]failure[- ]class|cap is per[- ]iteration' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── Halt branch preserved ──────────────────────────────────────────────────

@test "work-problems P140: Halt branch preserved for genuinely-unrecoverable failures" {
  run grep -niE 'genuinely-unrecoverable|genuinely unrecoverable' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P140: Halt branch enumerates auth failure / npm publish rejection / semantic test as unrecoverable" {
  # The halt branch's allow-list mirror — naming the unrecoverable
  # classes makes the boundary auditable.
  run grep -niE 'auth failure|npm publish rejection|semantic test.*judgment' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── Step 2.5b cross-reference preserved (P126) ─────────────────────────────

@test "work-problems P140: Halt branch routes through Step 2.5b surfacing routine (P126 preserved)" {
  # The halt branch's existing P126 cross-reference must survive the
  # amendment — surfacing accumulated user-answerable skips before
  # emitting the halt summary remains the contract.
  run grep -nE 'Step 2\.5b cross-reference \(P126\)' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── ADR-013 Rule 5 policy-authorised silent action ─────────────────────────

@test "work-problems P140: fix-and-continue branch is policy-authorised per ADR-013 Rule 5" {
  # ADR-044's framework-mediated surface includes "policy-authorised
  # silent proceed" — the closed allow-list IS the policy. Future
  # readers must find the citation to confirm this is not an ad-hoc
  # bypass of Rule 1.
  run grep -nE 'ADR-013 Rule 5|Rule 5 policy-authorised|policy-authorised.*ADR-013' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── Composition cross-references ───────────────────────────────────────────

@test "work-problems P140: Failure handling cross-references P081 (stop-gap composition)" {
  # P081 is the structural-tests-are-wasteful root cause. Most
  # P081-class stale-grep-string failures are P081's territory.
  # Fix-and-continue is the stop-gap; P081's full retrofit is the
  # structural elimination.
  run grep -nE 'P081' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P140: Failure handling cross-references P135 (decision-delegation contract)" {
  # P135 + ADR-044 frame the closed allow-list as the
  # framework-resolved policy.
  run grep -nE 'P135' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P140: Failure handling cross-references P130 (orchestrator main-turn ask discipline)" {
  # P130 ensures fix-and-continue does NOT introduce mid-iter asks —
  # the closed allow-list resolves the decision per ADR-044's
  # framework-resolution boundary.
  run grep -nE 'P130' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P140: Failure handling cross-references P132 (over-ask in interactive sessions)" {
  # P140 is the inverse of P132 on the failure-handling surface — both
  # arise from over-defensive uniform routing. Naming the symmetry
  # protects against future drift.
  run grep -nE 'P132' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── Mid-loop ask discipline halt-point bullet narrowed ─────────────────────

@test "work-problems P140: Step 6.5 CI-failure halt-point bullet narrows to outside-allow-list / cap-reached scope" {
  # The Mid-loop ask discipline subsection enumerates Step 6.5 CI-
  # failure as a halt point. After P140 the halt fires only on
  # unrecoverable failures — the bullet must reflect that narrower
  # scope, otherwise future readers conclude all CI failures still
  # halt.
  run grep -nE 'fixable-in-iter allow-list|3-retry cap reached|outside the.*allow-list' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── Non-Interactive Decision Making table row ──────────────────────────────

@test "work-problems P140: Decision Making table carries a CI-failure-during-Step-6.5-drain row" {
  # The decision table is the AFK reader's quick-reference; without a
  # row here the failure-handling refinement is buried 80 lines up in
  # Step 6.5.
  run grep -nE '\| CI failure during Step 6\.5 drain' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P140: Decision Making table row cites the closed fixable-in-iter allow-list" {
  run grep -nE 'closed fixable-in-iter allow-list' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P140: Decision Making table row cites the 3-retry cap" {
  run grep -nE 'CI failure during Step 6\.5.*3-retry cap|3-retry cap.*CI failure' "$SKILL_MD"
  [ "$status" -eq 0 ]
}
