# Problem 429: manage-problem commit-message examples fail @commitlint/config-conventional subject-case in adopter projects

**Status**: Open
**Reported**: 2026-07-06
**Priority**: 8 (Medium) — Impact: 2 × Likelihood: 4
**Origin**: inbound-reported (#137)
**Effort**: S. WSJF = (8 × 1.0) / 1 = 8.0.
**WSJF**: 8 — (8 × 1.0) / 1 (added 2026-07-26 review)
**JTBD**: JTBD-101
**Persona**: plugin-developer

## Description

The `manage-problem` (and sibling) SKILL commit-message examples use a `P<NNN> <verb>` subject shape whose leading pascal-case token is rejected by `@commitlint/config-conventional`'s `subject-case` rule in adopter projects that run commitlint. The documented convention hard-fails on first use.

## Symptoms

- An adopter following the SKILL's commit-message example (`fix(itil): P<NNN> ...`) hits a commitlint `subject-case` failure. Every new adopter running commitlint trips on their first governance commit.

## Impact Assessment

- **Who is affected**: adopters with commitlint (a common conventional-commits setup).
- **Frequency**: first governance commit in any such repo.
- **Severity**: Medium — blocks the documented flow; easy workaround once diagnosed.

## Root Cause Analysis

### Investigation Tasks

- [ ] Flip the SKILL examples to `<verb> ... (P<NNN>)` / `<verb> P<NNN>` so the subject starts lowercase; sweep all commit-message example blocks across the itil SKILLs.

## Dependencies

- **Composes with**: (distinct from P082/P360/P365 — those gate on commit-msg content; this is the SKILL example shape).

## Related

- Inbound issue #137.
