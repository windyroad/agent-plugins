---
status: draft
story-id: record-oversight-evidence-only-for-the-confirming-session
reported: 2026-08-29
decision-makers: [Tom Howard]
problems: [P368]
jtbd: [JTBD-001, JTBD-006]
rfcs: [RFC-078]
story-maps: [STORY-MAP-002]
estimated-effort: M
---

# STORY-072: Record oversight evidence only for the confirming session

**Reported**: 2026-08-29
**Problems**: P368
**JTBD**: JTBD-001, JTBD-006
**RFCs**: RFC-078
**Story Maps**: STORY-MAP-002
**Estimated effort**: M

## User value (required, INVEST Valuable)

In order to trust that ratification evidence cannot be reused by another session, as a plugin developer, I want oversight confirmation to authorise only the session that received my answer.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] A successful standalone oversight-helper event writes one marker for that event's session and document, and no marker for unrelated sessions.
- [ ] A live session can write its marker without a recent announce marker; a missing session id writes no marker and reports the failure.
- [ ] Architect and JTBD confirmation flows use the same exact-event contract, with behavioural coverage against failed and non-exact commands.

## Driving problem trace (required — I6 invariant)

P368 records that candidate-session enumeration both misses the caller after its announce marker ages out and grants every unrelated in-window session oversight evidence.

## JTBD trace (required — I9 invariant)

JTBD-001 requires governance to remain automatic without weakening its safety boundary; JTBD-006 requires unattended work to leave an exact, trustworthy audit trail.

## Implementation notes (optional)

Reuse each package's existing PostToolUse Bash hook so the successful helper command, document path, and runtime session id are observed together.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- P368 — oversight marker warm-path control defeat
- RFC-078 — Keep ratification evidence with the session that confirmed it
