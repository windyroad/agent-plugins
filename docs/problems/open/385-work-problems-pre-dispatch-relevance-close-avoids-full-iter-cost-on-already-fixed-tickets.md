# Problem 385: work-problems re-dispatches already-fixed tickets at full iter cost; add a cheap pre-dispatch relevance-close

**Status**: Open
**Reported**: 2026-06-26
**Priority**: 8 (Medium) — Impact: 2 x Likelihood: 4
**Origin**: inbound-reported (#284)
**Effort**: M
**JTBD**: JTBD-001
**Persona**: plugin-developer

## Description

In an AFK `/wr-itil:work-problems` loop, a meaningful fraction of "open" tickets turn out to have been already fixed by later work but never transitioned (observed: 3 of 6 worked tickets in a single session). The orchestrator dispatches a full iteration subprocess per ticket (real time + cost) only to discover the fix already shipped, then transitions the ticket. The rediscovery is correct but expensive.

## Symptoms

- A work iter runs a full subprocess, finds the fix already shipped, and transitions the ticket — paying iter cost for a transition that a cheap check could have made.

## Workaround

None — the rediscovery is correct, just expensive.

## Impact Assessment

- **Who is affected**: anyone running AFK work-problems against a mature backlog.
- **Frequency**: proportional to the stale-but-open fraction of the backlog (observed ~50% in one session).
- **Severity**: wasted iteration time + token cost; no correctness impact.

## Root Cause Analysis

### Investigation Tasks

- [ ] Run a cheap pre-dispatch relevance / already-shipped check BEFORE dispatching a work iteration
- [ ] Reuse the `review-problems` Step 4.6 relevance-close evaluator (`wr-itil-evaluate-relevance`) or a lightweight already-shipped heuristic keyed on the ticket's cited tool/ADR/commit
- [ ] Transition or close stale tickets cheaply rather than rediscovering at full iter cost
- [ ] Composes with the existing Step 0c deferred-placeholder pre-flight
- [ ] Behavioural test: a ticket whose cited fix has shipped is transitioned without a full iter dispatch

## Dependencies

- **Blocks**: AFK work-problems cost efficiency on mature backlogs
- **Blocked by**: (none)
- **Composes with**: P344 (work-problems predicate-check cited JTBDs before dispatch — same pre-dispatch insertion point), P346/ADR-079 (Step 4.6 relevance-close evaluator — reused here)

## Related

- **Upstream**: windyroad/agent-plugins#284 — surfaced during an AFK work-problems session against a mature backlog; captured by the session-level retro.
- `packages/itil/skills/work-problems/SKILL.md` — Step 5 dispatch / Step 0c pre-flight is the insertion point.
- `packages/itil/scripts/evaluate-relevance.sh` (`wr-itil-evaluate-relevance` shim) — the reusable evaluator.
- **ADR-079** — Step 4.6 relevance-close evidence shapes.
