---
status: done
story-id: capture-the-problem-mid-flow
reported: 2026-07-02
decision-makers: [Tom Howard]
problems: [P155]
jtbd: [JTBD-008, JTBD-006]
story-maps: [STORY-MAP-002]
estimated-effort: M
human-oversight: unconfirmed
---

# STORY-018: Capture the problem in seconds, mid-flow

**Story map:** [← STORY-MAP-002: Decompose a Fix Into Coordinated Changes](../../story-maps/draft/STORY-MAP-002-decompose-a-fix-into-coordinated-changes.html) · A1 (Release 1)
**Backbone:** A1 capture · [A2 root cause](019-record-root-cause-and-workaround.md) · A3 decompose ([start map](020-start-the-jobs-story-map.md) …) · [A4 work the stories](014-author-first-work-problems-afk.md) · [A5 ship](023-ship-verify-and-close-with-a-real-trace.md)

## User value (INVEST Valuable)

In order to keep a problem from being lost when I hit it mid-flow, as a developer, I want to capture it in seconds — with a real trace — without breaking my current task.

## Acceptance criteria (INVEST Testable) — SHIPPED

- [x] `/wr-itil:capture-problem` files a ticket from a one-line description without the full intake ceremony.
- [x] Persona + JTBD are derived (or elicited), not shoehorned (P401).
- [x] The capture rides the lightweight aside path; the loop/flow continues.

## Driving problem trace (I6)

**P155** — ship the lightweight capture skill (the foreground aside). This is the journey's entry point, already shipped.

## JTBD trace (I9)

**JTBD-008** (the fix journey begins at capture) · **JTBD-006** (AFK captures without breaking cadence).

## Related

- **STORY-MAP-002** A1 card. Shipped via `/wr-itil:capture-problem`.
