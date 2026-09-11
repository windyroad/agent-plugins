---
status: done
story-id: capture-a-problem-when-its-index-is-missing
reported: 2026-09-11
decision-makers: [Tom Howard]
problems: [P538]
jtbd: [JTBD-001]
rfcs: [RFC-092]
story-maps: [STORY-MAP-002]
estimated-effort: M
---

# STORY-088: Capture a problem when its index is missing

**Reported**: 2026-09-11
**Problems**: P538
**JTBD**: JTBD-001 (Enforce Governance Without Slowing Down)
**RFCs**: RFC-092
**Story Maps**: STORY-MAP-002 (Take a problem from noticed to resolved), activity `implement`
**Estimated effort**: M

## User value (required, INVEST Valuable)

In order to preserve a defect when governance state is incomplete, as a developer using problem-management skills, I want a missing or stale derived problem index to be repaired during capture instead of blocking the source report.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [x] `capture-problem` creates the ticket and canonical index in one commit when the index is absent.
- [x] The new-problem branch of `manage-problem` does the same, while existing-problem operations retain strict reconciliation.
- [x] Parseable drift repairs generated sections without replacing README narrative.
- [x] An existing malformed README still halts before content can be overwritten.
- [x] The published plugin passes the exact missing-index creation journey in a temporary adopter repository.

## Driving problem trace (required - I6 invariant)

P538 records that both creation entry points run strict problem-index reconciliation before preserving a report, so an absent index can prevent the recovery ticket from being created.

## JTBD trace (required - I9 invariant)

- **JTBD-001**: governance remains enforced automatically without turning an incomplete derived index into a blocking manual recovery loop.

## Implementation notes (optional)

Keep the reconciler and non-creation callers strict. Change only the two creation contracts, reuse their existing same-commit index refresh, and cover both surfaces with behavioral skill evaluations.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- ADR-123 (Problem reports precede derived index repair)
- STORY-MAP-002 (Take a problem from noticed to resolved)
