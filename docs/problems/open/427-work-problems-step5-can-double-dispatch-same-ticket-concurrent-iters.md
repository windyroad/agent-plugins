# Problem 427: work-problems Step 5 can double-dispatch the same ticket to concurrent iters — no per-ticket lock / liveness / dirty-tree preflight

**Status**: Open
**Reported**: 2026-07-06
**Priority**: 6 (Medium) — Impact: 3 × Likelihood: 2
**Origin**: inbound-reported (#343)
**Effort**: M. WSJF = (6 × 1.0) / 2 = 3.0.
**JTBD**: JTBD-006
**Persona**: plugin-developer

## Description

The `/wr-itil:work-problems` orchestrator can dispatch the same ticket to two concurrent iter subprocesses — there is no per-ticket advisory lock, no liveness check on an in-flight iter, and no working-tree-dirty preflight abort before a second dispatch. Two iters then race on the same ticket's files/commits.

## Symptoms

- Orchestrator selects ticket P<NNN>, dispatches iter A; before A's transition lands, the next loop re-selects P<NNN> (still top of WSJF) and dispatches iter B. Both edit the same ticket / compete on commit.

## Impact Assessment

- **Who is affected**: AFK loops; wasted iters + potential conflicting commits.
- **Frequency**: whenever an iter runs longer than one loop cycle without transitioning.
- **Severity**: Medium — wasted work + race hazard; not data-losing if commits serialise.

## Root Cause Analysis

### Investigation Tasks

- [ ] Add a per-ticket advisory lock + working-tree-dirty preflight abort before Step 5 dispatch; skip a ticket with a live in-flight iter.

## Dependencies

- **Composes with**: P333 (stale iter-error markers — adjacent Step-0 state, distinct mechanism).

## Related

- Inbound issue #343.
