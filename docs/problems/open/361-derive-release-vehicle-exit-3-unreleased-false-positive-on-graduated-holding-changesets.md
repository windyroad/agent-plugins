# Problem 361: wr-itil-derive-release-vehicle exit-3 "unreleased" false positive on ADR-061 graduated holding changesets

**Status**: Open
**Reported**: 2026-06-11
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-006
**Persona**: developer

## Description

wr-itil-derive-release-vehicle reports exit-3 "changeset still present in working tree (unreleased)" as a false positive when the referenced changeset is an ADR-061 holding-graduation reinstate whose code already de-facto shipped with a sibling release (P359 holding-does-not-withhold-shipment class). Observed 2026-06-11 AFK work-problems iter 1: P211's fix commit 796c9c86 is an ancestor of the @windyroad/itil 0.49.3 version bump 34d6a8f8 published on npm, the ticket's Fix Strategy carries the P330 seed `**Release vehicle**: .changeset/wr-itil-p211-iter-prompt-re-grounding.md` (seed lookup succeeded — no exit-2), yet `wr-itil-derive-release-vehicle 211` exits 3 because the graduated changeset entry is back in `.changeset/` awaiting next-release changelog attribution. The helper's presence-in-.changeset/ test conflates "changelog entry not yet drained" with "code not yet released"; under the ADR-061 Rule 5 graduation flow these diverge. Effect: K-to-V transitions on de-facto-released tickets get a wrong "unreleased" signal in transition-problem Step 6 routing; AFK iters must override manually. Likely fix: teach the helper a third check — when the changeset file is present, verify whether the fix commit is an ancestor of the latest published version bump (`git merge-base --is-ancestor` against the last "chore: version packages" commit touching the package) and exit 0 with a "de-facto-released (attribution pending)" note instead of exit 3. Composes with P330 (the helper + seed contract) and P359 (holding ships code).

## Symptoms

(deferred to investigation)

## Workaround

(deferred to investigation)

## Impact Assessment

- **Who is affected**: (deferred to investigation)
- **Frequency**: (deferred to investigation)
- **Severity**: (deferred to investigation)
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Investigate root cause
- [ ] Create reproduction test

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P330, P359

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)

- **Hang-off-check candidate-cap short-circuit (P346 Phase 3)**: mechanical pre-filter surfaced 6 candidates sharing the ADR-061 signal (>5 cap) — subagent dispatch skipped per the capture-problem sub-step 2b latency bound; re-evaluate absorption at next /wr-itil:review-problems. Candidates: P082, P162, P211, P247, P308, P350 (ADR-061 body matches in open/+verifying/). Strongest semantic parents: P359 (open — changeset holding does not withhold shipment; this ticket is the helper-surface consequence of that insight) and P330 (verifying — the derive-release-vehicle helper + seed contract; cannot absorb new scope while verifying).
