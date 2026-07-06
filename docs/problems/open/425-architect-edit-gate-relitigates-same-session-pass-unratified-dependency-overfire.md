# Problem 425: wr-architect edit-gate re-litigates its own same-session PASS — [Unratified Dependency] over-fires on agent-prescribed born-proposed ADRs

**Status**: Open
**Reported**: 2026-07-06
**Priority**: 9 (Medium) — Impact: 3 × Likelihood: 3
**Origin**: inbound-reported (#342)
**Effort**: M. WSJF = (9 × 1.0) / 2 = 4.5.
**JTBD**: JTBD-101
**Persona**: plugin-developer

## Description

A `docs/decisions/` commit that the architect itself prescribed invalidates the drift-hash marker; the fresh stateless refresh review then re-flags the just-captured born-proposed ADR as an `[Unratified Dependency]` blocker. Under AFK, mid-loop ratification is structurally impossible, so the flag burns the iteration — a same-session PASS is re-litigated against its own output.

## Symptoms

- Architect prescribes an ADR capture mid-iter (PASS). The ADR lands born `human-oversight: unconfirmed`. The next architect edit-gate invocation (same session) re-reads the tree, finds the unratified ADR, and denies — deadlock in AFK.
- This is precisely the over-firing case that P318 (which added the `[Unratified Dependency]` guard) dismissed as "born-confirmed keeps the unratified set near zero."

## Impact Assessment

- **Who is affected**: AFK work-problems loops that touch architecture; the loop stalls on its own prescribed ADR.
- **Frequency**: any iter that captures a born-proposed ADR then needs a further gated edit.
- **Severity**: Medium — AFK deadlock; forces manual intervention.

## Root Cause Analysis

### Investigation Tasks

- [ ] Give the stateless refresh review a same-session sanction ledger, OR exempt agent-prescribed born-proposed ADRs from the unratified-dependency flag mid-session — without weakening P318's legitimate cases.

## Dependencies

- **Composes with**: P318 (closed — added the guard, dismissed this over-fire), P313 (verifying — edit-gate re-litigation / catch-22 family, different mechanism), P316 (unratified ADRs resurfacing).

## Related

- Inbound issue #342.
