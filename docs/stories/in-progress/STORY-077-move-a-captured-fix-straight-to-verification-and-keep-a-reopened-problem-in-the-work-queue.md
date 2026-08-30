---
status: in-progress
story-id: move-a-captured-fix-straight-to-verification-and-keep-a-reopened-problem-in-the-work-queue
reported: 2026-08-30
decision-makers: [Tom Howard]
problems: [P512]
jtbd: [JTBD-001, JTBD-006]
rfcs: [RFC-083]
story-maps: [STORY-MAP-002]
estimated-effort: M
---

<!-- A story carries no oversight marker. Approval is inherited from the
     confirmed story map named above. -->

# STORY-077: Move a captured fix straight to verification and keep a reopened problem in the work queue

**Reported**: 2026-08-30
**Problems**: P512
**JTBD**: JTBD-001, JTBD-006
**RFCs**: RFC-083
**Story Maps**: STORY-MAP-002
**Estimated effort**: M

## User value (required, INVEST Valuable)

In order to keep each problem in the state that matches what happened, as a developer moving a captured fix or reopening a problem, I want supported transitions to move the captured fix to Verification Pending and keep the reopened Known Error in the work queue.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [x] Open to Verification Pending is valid only when the existing Open to Known Error checks, the existing release checks, and an objective populated `## Fix Released` section all pass.
- [x] The run-retro recovery wording is re-checked against the now-shipped one-command recovery and a focused cross-skill test proves the named recovery is accepted by transition-problem.
- [x] A Known Error ticket with a `## Reopened <date>` section later than its derived release date is not emitted by the post-release Known Error to Verification Pending enumerator.
- [x] The reopened-ticket guard applies whether the release vehicle came from the ticket body or the co-commit fallback.
- [x] The two backward lifecycle pairings shipped through P519 are not reimplemented.

## Driving problem trace (required — I6 invariant)

P512 records that the transition lifecycle rejects the confirmed ADR-022 fix-on-capture route, while stale release evidence can immediately remove a reopened problem from the development queue.

## JTBD trace (required — I9 invariant)

- **JTBD-001**: lifecycle governance stays fast and reliable because supported routes retain their pre-flights, README refresh, and commit audit trail.
- **JTBD-006**: an unattended backlog loop keeps reopened work in the development queue instead of auto-transitioning it from stale release evidence.

## Implementation notes (optional)

Reuse the existing transition checklists and post-release enumerator. Add no new lifecycle abstraction and do not touch the P519 backward pairings.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- STORY-MAP-002 — Take a problem from noticed to resolved
- ADR-014 — governance skills commit their own completed work
- ADR-022 — Verification Pending lifecycle and folded Open to Verification Pending route
