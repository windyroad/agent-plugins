# Problem 416: Outstanding-questions drain appends a superseding human decision without reconciling the stale Fix Strategy section it overrides

**Status**: Open
**Reported**: 2026-07-04
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-001
**Persona**: plugin-developer

## Description

The outstanding-questions drain that records human decisions across many tickets in one commit (e.g. commit `fcefe5d3` "record human decisions from outstanding-questions drain (12 tickets)") appends a new `## Human decision — <date>` section to each ticket but does NOT reconcile any pre-existing `## Fix Strategy` / "ratified" section the new decision may **supersede**. Result: tickets left internally contradictory — two conflicting recorded decisions, the stale one still presenting as the active fix direction.

Concrete evidence: P178 carried a 2026-06-17 `## Fix Strategy — ratified` **hard-block** section AND a superseding 2026-07-03 `## Human decision` (**trace-based conditional**) with no supersession marker between them. A later `/wr-itil:work-problems` iter (2026-07-04) had to manually reconcile them — mark the hard-block SUPERSEDED, re-point the fix shape, and mark the RCA framework-position task resolved — before the ticket could be progressed. Ticket 136 shows the same co-occurrence pattern (a `## Human decision` section alongside a pre-existing `## Fix Strategy`/ratified section).

Fix path: when the drain records a decision that supersedes a prior ratified Fix Strategy / position on a ticket, it should mark the prior section superseded (banner + heading update) and re-point the fix shape in the **same** edit — not silently append a contradicting section. Affects the governance ticket corpus fed to future AFK iters, which anchor on the (now stale) Fix Strategy and can build on a rejected direction (a P314/P315-class build-on-then-superseded hazard).

Recurring-class: the same drain mechanism touched ~12 tickets in one commit, so any ticket among that set (or a future drain) that already carried a ratified position is exposed to the same contradiction.

## Symptoms

- A problem ticket carries both a `## Fix Strategy` (or "ratified") section AND a later `## Human decision — <date>` section whose substance contradicts it, with no supersession marker linking them.
- A downstream AFK iter reads the earlier (stale) Fix Strategy as the active direction and must pause to reconcile before it can progress the ticket.
- `git grep -l` for tickets touched by a drain commit that ALSO have both a `## Human decision` and a `## Fix Strategy`/ratified heading surfaces contradiction-risk candidates (P178 confirmed; 136 co-occurrence).

## Workaround

The reading iter reconciles by hand: mark the superseded section with a `> **SUPERSEDED**` banner, update its heading, re-point the fix shape to match the newer decision, and flip any RCA task that the new decision resolves. Costs a manual read-and-reconcile pass per exposed ticket (P178, 2026-07-04).

## Impact Assessment

- **Who is affected**: (deferred to investigation) — primary: AFK `/wr-itil:work-problems` iters that anchor on the stale Fix Strategy; secondary: maintainers auditing decided tickets.
- **Frequency**: (deferred to investigation) — one drain commit touched ~12 tickets; exposure is limited to those that already carried a ratified position.
- **Severity**: (deferred to investigation) — likely Moderate; does not block ship but risks building on a superseded direction (P314/P315 class).
- **Analytics**: (deferred to investigation) — count of tickets with co-present `## Human decision` + unreconciled `## Fix Strategy`/ratified sections.

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Locate the drain surface that writes the `## Human decision — <date>` sections (candidates: `/wr-itil:work-problems` Step 2.5 batched outstanding-questions drain; a review-problems / manage-problem drain path) and confirm it has no reconcile-prior-strategy step.
- [ ] Sweep the ~12 tickets from commit `fcefe5d3` for the same stale-strategy contradiction (grep for co-present `## Human decision` + `## Fix Strategy`/ratified) and list residual instances.
- [ ] Create reproduction/behavioural test asserting the drain marks a superseded prior Fix Strategy rather than silently appending a contradicting decision.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P178 (the exposed instance, reconciled 2026-07-04); P135 (decision-delegation master); P315 (implement-on-unconfirmed-decisions / build-on-then-superseded class).

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)

- P178 — the surfacing instance: hard-block Fix Strategy left unreconciled under a superseding 2026-07-03 trace-based decision; reconciled manually in an AFK iter 2026-07-04.
- Commit `fcefe5d3` — "record human decisions from outstanding-questions drain (12 tickets)" — the drain commit that appended decisions without reconciling prior strategies.
- Ticket 136 — same co-occurrence pattern observed.
- P315 / P314 — build-on-then-rejected/superseded hazard class the stale strategy re-exposes.
