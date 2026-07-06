# Problem 426: wr-architect review agent lacks a "first-match on a non-unique collection" review heuristic (identity/auth/data-binding footgun)

**Status**: Open
**Reported**: 2026-07-06
**Priority**: 12 (High) — Impact: 4 × Likelihood: 3
**Origin**: inbound-reported (#169)
**Effort**: S. WSJF = (12 × 1.0) / 1 = 12.0.
**JTBD**: JTBD-101
**Persona**: plugin-developer

## Description

The `wr-architect:agent` reviewer has no standing heuristic to flag first-match selection (`.limit(1)`, array `[0]`, `.find()`, `.pop()`) on a non-unique collection that backs an identity / authorization / data-binding decision. Two production defects already slipped review this way (one bound a workspace to the wrong org).

## Symptoms

- Code selects the first element of a collection that is not guaranteed unique, and uses it for an identity/authz/data-binding decision; review passes it. Under real data with >1 match, the wrong entity is chosen.

## Impact Assessment

- **Who is affected**: adopters relying on the architect reviewer to catch structural footguns; the reviewer misses a whole defect class.
- **Frequency**: whenever such code is reviewed (has already slipped ≥2 times).
- **Severity**: High — silent wrong-entity binding (auth/identity) is a serious class.

## Root Cause Analysis

### Investigation Tasks

- [ ] Add the heuristic to the wr-architect agent checklist (cover `.limit(1)`, `[0]`, `.find()`, `.pop()` on non-unique collections backing identity/authz/data-binding); require a disambiguating key or an explicit multi-element error/selection step.
- [ ] Back it with a behavioural eval per P081 (behavioural over structural).

## Dependencies

- **Composes with**: (none — no existing review-heuristic ticket).

## Related

- Inbound issue #169.
