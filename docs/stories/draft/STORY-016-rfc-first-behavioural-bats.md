---
status: draft
story-id: rfc-first-behavioural-bats
reported: 2026-06-29
decision-makers: [Tom Howard]
problems: [P251]
jtbd: [JTBD-008]
rfcs: [RFC-005]
story-maps: [STORY-MAP-002]
estimated-effort: S
---

# STORY-016: Every step is regression-proven

**Status**: draft
**Reported**: 2026-06-29
**Problems**: P251
**JTBD**: JTBD-008
**RFCs**: RFC-005
**Estimated effort**: S

## User value (INVEST Valuable)

As a maintainer, I want behavioural bats (ADR-052 behavioural-only) that prove the RFC-first gate actually behaves correctly — so the invariant is regression-protected, not just documented.

## Acceptance criteria (INVEST Testable)

- [ ] Implementation on an RFC-less Known Error is **refused / routed to RFC-authoring** at every effort level (S/M/L/XL — no carve-out).
- [ ] A fix whose approach-choice is **uncovered** by existing ADRs **blocks for a new ratified ADR**.
- [ ] A fix whose approach-choice **is covered** by existing ADRs **proceeds** (RFC cites the ADRs, no new ADR).
- [ ] Retained assertions: no-duplicate (RFC already traces → no-op) + ADR-060 I2 uniformity (behaviour identical regardless of `type:`).
- [ ] Behavioural-only (no structural grep on SKILL/ADR prose); the predicate-half bats are rewritten under STORY-012.

## Driving problem trace (I6)

**P251.** The shipped bats assert auto-create-fires (repudiated behaviour). This story rewrites them to assert refuse/route + escalate-uncovered + proceed-covered. Supersedes RFC-005 B6 (rework slice B16). The author-first / escalate SKILL-orchestration half is discharged by the STORY-015 dogfood (harness-gap recorded honestly, no silent cap).

## JTBD trace (I9)

**JTBD-008** — Decompose a Fix Into Coordinated Changes; the bats are the regression floor that keeps the decomposition discipline enforced.

## Dependencies

- **Blocks**: RFC-005 B10 (held-changeset graduation gated on green bats).
- **Blocked by**: STORY-012, STORY-013, STORY-014 (the behaviours under test).

## Related

- RFC-005 B16; supersedes B6. ADR-052 (behavioural-only), ADR-051 (load-bearing predicate).
