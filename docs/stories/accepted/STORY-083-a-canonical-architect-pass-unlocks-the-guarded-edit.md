---
status: accepted
story-id: a-canonical-architect-pass-unlocks-the-guarded-edit
reported: 2026-08-31
decision-makers: [Tom Howard]
problems: [P468]
jtbd: [JTBD-001]
rfcs: [RFC-089]
story-maps: [STORY-MAP-002]
estimated-effort: S
---

# STORY-083: A canonical architect PASS unlocks the guarded edit

**Reported**: 2026-08-31
**Problems**: P468
**JTBD**: JTBD-001 (Enforce Governance Without Slowing Down)
**RFCs**: RFC-089
**Story Maps**: STORY-MAP-002 (Take a problem from noticed to resolved), activity `implement`
**Estimated effort**: S

## User value (required, INVEST Valuable)

In order to continue a governed change without manual marker recovery, as a developer using AI agents, I want the architect completion hook to recognize the first canonical bold or H2 verdict line and fail closed on ambiguous output.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] Canonical bold and H2 PASS verdicts create review, hash, and plan markers.
- [ ] ISSUES FOUND, malformed, quoted, narrative, NEEDS DIRECTION, and conflicting verdict output create no review, hash, or plan markers.
- [ ] The existing generated transport binds each Codex-native completion to its parent session.

## Driving problem trace (required — I6 invariant)

P468 records that the shared architect marker writer rejects a genuine H2 PASS and can approve conflicting output when a later PASS appears after ISSUES FOUND.

## JTBD trace (required — I9 invariant)

- **JTBD-001**: recognizing one unambiguous canonical verdict restores automatic governance without manual marker recovery or weaker review authority.

## Implementation notes (optional)

Change only the shared verdict parser. Preserve the existing Claude and generated Codex completion callers, and keep unknown or conflicting output fail closed.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- P468
- RFC-089
- ADR-009
- ADR-103
