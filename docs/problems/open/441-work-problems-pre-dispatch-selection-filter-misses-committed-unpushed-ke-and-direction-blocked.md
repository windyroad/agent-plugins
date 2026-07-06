# Problem 441: work-problems pre-dispatch selection filter misses committed-but-unpushed KE (#312) and direction-blocked / interactive-only-skill (#318) states

**Status**: Open
**Reported**: 2026-07-06
**Priority**: 9 (Medium) — Impact: 3 × Likelihood: 3
**Origin**: inbound-reported (#312, #318)
**Effort**: M. WSJF = (9 × 1.0) / 2 = 4.5.
**JTBD**: JTBD-006
**Persona**: plugin-developer

## Description

Two adjacent gaps in the `/wr-itil:work-problems` pre-dispatch selection machinery (the P385 relevance-close + P344 predicate-check both already live but scoped narrowly):
- **#312**: a Known-Error ticket whose fix was implemented-and-committed *this loop* but not yet pushed (below the Step 6.5 drain threshold) stays top-of-WSJF and is re-selected; P385's relevance-close keys on *already-shipped/released*, missing this transient committed-but-unpushed sub-state.
- **#318**: the orchestrator re-selects tickets that are not AFK-actionable — those carrying an open queued cat-1 direction question, or whose Fix Strategy names an interactive-only skill (`/wr-architect:create-adr`, `/wr-jtbd:update-guide`, any AskUserQuestion-bound authoring surface) — every loop as highest-WSJF (no-op skips).

## Symptoms

- The loop burns iterations re-selecting a ticket it just worked (unpushed) or one it structurally cannot progress AFK (direction-blocked / interactive-only).

## Impact Assessment

- **Who is affected**: AFK loops; wasted iterations on no-op re-selections.
- **Frequency**: every loop with a committed-unpushed KE or a direction-blocked top ticket.
- **Severity**: Medium — wasted cost; the loop appears busy but makes no progress.

## Root Cause Analysis

### Investigation Tasks

- [ ] Extend the P385 Step 3.6 relevance-close to also skip a KE whose fix is committed-but-unpushed this loop (#312).
- [ ] Generalise the P344 Step 3.5 predicate into a broad "AFK-actionability" filter covering direction-blocked + interactive-only-skill-dependent tickets (#318).

## Dependencies

- **Composes with**: P385 (verifying — pre-dispatch relevance-close), P344 (verifying — pre-dispatch predicate-check), P352 (runtime queue-and-continue).

## Related

- Inbound issues #312, #318. Kept as one ticket: both extend the same pre-dispatch selection filter.
