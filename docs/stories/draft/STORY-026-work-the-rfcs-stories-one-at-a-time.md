---
status: done
story-id: work-the-rfcs-stories-one-at-a-time
reported: 2026-07-02
decision-makers: [Tom Howard]
problems: [P170]
jtbd: [JTBD-008, JTBD-006]
rfcs: [RFC-005]
story-maps: [STORY-MAP-002]
estimated-effort: M
human-oversight: unconfirmed
---

# STORY-026: Work the RFC's stories one at a time

**Story map:** [← STORY-MAP-002: Decompose a Fix Into Coordinated Changes](../../story-maps/draft/STORY-MAP-002-decompose-a-fix-into-coordinated-changes.html) · A4 (Release 1)
**Backbone:** [A1 capture](018-capture-the-problem-mid-flow.md) · [A2 root cause](019-record-root-cause-and-workaround.md) · A3 decompose ([start map](020-start-the-jobs-story-map.md) …) · A4 work · [A5 ship](023-ship-verify-and-close-with-a-real-trace.md)

## User value (INVEST Valuable)

In order to make safe, steady progress I can trust — catching a mistake while it's small and cheap instead of untangling one giant half-finished change — as a developer implementing a decomposed fix, I want to work the RFC's stories one at a time.

## Acceptance criteria (INVEST Testable) — SHIPPED (traversal)

- [x] The working-the-problem traversal reads the RFC's ordered `stories:` and dispatches the next actionable story per iteration.
- [x] Interactive and AFK (`work-problem` / `work-problems`) both traverse story-by-story.
- [ ] (P404) The empty-stories fallback is removed — with ADR-089, there is always ≥1 story to dispatch, so the per-RFC-blob fallback path goes away.

## Driving problem trace (I6)

**P170** — the traversal turns "implement the fix" into concrete, story-by-story dispatch. The core traversal shipped (STORY-005 on STORY-MAP-001); the ADR-089 fallback-removal is tracked in **P404**.

## JTBD trace (I9)

**JTBD-008** (implement the coordinated changes) · **JTBD-006** (AFK dispatch, one story per iter).

## Related

- **STORY-MAP-002** A4 card. Implemented by the work-the-problem traversal (STORY-005, MAP-001); ADR-089 fallback-removal in P404.
