---
status: accepted
story-id: review-only-options-consistent-with-documented-desired-outcomes
reported: 2026-08-31
decision-makers: [Tom Howard]
problems: [P514]
jtbd: [JTBD-001]
rfcs: [RFC-085]
story-maps: [STORY-MAP-002]
estimated-effort: M
---

# STORY-079: Review only options consistent with documented desired outcomes

**Reported**: 2026-08-31
**Problems**: P514
**JTBD**: JTBD-001 (Enforce Governance Without Slowing Down)
**RFCs**: RFC-085
**Story Maps**: STORY-MAP-002 (Take a problem from noticed to resolved), activity `implement`
**Estimated effort**: M

## User value (required, INVEST Valuable)

In order to avoid reviewing options that already conflict with my documented desired outcomes, as a developer using AI agents, I want those agents to check recommendations against those outcomes before presenting them.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] Before presenting a user-facing capability recommendation or option set, the assistant invokes the JTBD reviewer.
- [ ] An option that contradicts or does not serve a documented desired outcome is withheld before the user sees it.
- [ ] An option set that is incomplete against documented desired outcomes is reported as incomplete before the user sees it.
- [ ] A recommendation aligned with the documented desired outcomes receives a pass without authorising an unrelated file edit.

## Driving problem trace (required — I6 invariant)

P514 records that the JTBD gate is bound to file edits, so recommendations and option sets can reach the user without review against documented desired outcomes.

## JTBD trace (required — I9 invariant)

- **JTBD-001**: recommendation review extends automatic governance to the decision path without adding a manual review step or weakening edit enforcement.

## Implementation notes (optional)

Extend the existing progressive-disclosure instruction and canonical JTBD reviewer contract. Keep recommendation verdict evidence separate from edit-review evidence so a recommendation pass cannot authorise a later file edit.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- P514
- RFC-085
