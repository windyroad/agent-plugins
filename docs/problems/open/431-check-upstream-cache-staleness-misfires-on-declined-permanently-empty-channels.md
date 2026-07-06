# Problem 431: check-upstream-cache-staleness helper misfires on a declined-permanently (empty channels) config

**Status**: Open
**Reported**: 2026-07-06
**Priority**: 6 (Medium) — Impact: 2 × Likelihood: 3
**Origin**: inbound-reported (#341)
**Effort**: S. WSJF = (6 × 1.0) / 1 = 6.0.
**JTBD**: JTBD-101
**Persona**: plugin-developer

## Description

`wr-itil-check-upstream-cache-staleness` treats a present-but-empty channels config the same as first-run (cache absent): `review-problems` short-circuits, the cache is never written, so every subsequent loop re-dispatches a guaranteed no-op upstream-discovery pre-flight.

## Symptoms

- A repo that has explicitly declined upstream channels (empty channels list) gets a redundant review-problems pre-flight dispatched every work-problems loop, because the staleness helper never sees a written cache.

## Impact Assessment

- **Who is affected**: adopters who declined upstream channels; wasted per-loop dispatch.
- **Frequency**: every work-problems loop in such a repo.
- **Severity**: Medium — wasted cost, no incorrect action.

## Root Cause Analysis

### Investigation Tasks

- [ ] Distinguish empty-channels (declined → silent-pass / no-channels-config) from first-run-cache-absent; short-circuit without re-dispatching when channels are explicitly empty.

## Dependencies

- **Composes with**: P406 (discussions channel HTTP 410 — adjacent upstream-channel robustness), P373.

## Related

- Inbound issue #341.
