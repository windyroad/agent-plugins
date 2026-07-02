---
status: done
story-id: record-root-cause-and-workaround
reported: 2026-07-02
decision-makers: [Tom Howard]
problems: [P170]
jtbd: [JTBD-008]
adrs: [ADR-022]
story-maps: [STORY-MAP-002]
estimated-effort: M
human-oversight: unconfirmed
---

# STORY-019: Record root cause + workaround → Known Error

**Story map:** [← STORY-MAP-002: Decompose a Fix Into Coordinated Changes](../../story-maps/draft/STORY-MAP-002-decompose-a-fix-into-coordinated-changes.html) · A2 (Release 1)
**Backbone:** [A1 capture](018-capture-the-problem-mid-flow.md) · A2 root cause · A3 decompose ([start map](020-start-the-jobs-story-map.md) …) · [A4 work the stories](014-author-first-work-problems-afk.md) · [A5 ship](023-ship-verify-and-close-with-a-real-trace.md)

## User value (INVEST Valuable)

In order that the fix targets the real cause instead of a symptom — and users aren't left blocked while it's built — as a developer, I want to record a problem's root cause and a documented workaround and move the ticket to Known Error.

## Acceptance criteria (INVEST Testable) — SHIPPED

- [x] Root cause analysis + a documented workaround are recorded on the ticket.
- [x] The ticket transitions `Open → Known Error` (per ADR-022 — Known Error = root cause + workaround; the fix is *proposed* after).
- [x] No fix or RFC is required to reach Known Error (that's A3's job).

## Driving problem trace (I6)

**P170** — Known Error is the stable point from which a coordinated fix is decomposed.

## JTBD trace (I9)

**JTBD-008** — the decomposition (A3) fires on a Known Error.

## Related

- **STORY-MAP-002** A2 card. **ADR-022** — Known Error semantics. Shipped via `/wr-itil:manage-problem` + `transition-problem`.
