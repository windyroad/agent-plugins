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
human-oversight: confirmed
oversight-confirmed-date: "2026-07-02 — ratified via AskUserQuestion (per-story ratification pass; reworked record→find-via-RCA before ratifying)"
---

# STORY-019: Find the root cause and a workaround → Known Error

**Story map:** [← STORY-MAP-002: Decompose a Fix Into Coordinated Changes](../../story-maps/draft/STORY-MAP-002-decompose-a-fix-into-coordinated-changes.html) · A2 (Release 1)
**Backbone:** [A1 capture](018-capture-the-problem-mid-flow.md) · A2 root cause · A3 decompose ([start map](020-start-the-jobs-story-map.md) …) · [A4 work the stories](014-author-first-work-problems-afk.md) · [A5 ship](023-ship-verify-and-close-with-a-real-trace.md)

## User value (INVEST Valuable)

In order to know what to actually fix — the *root cause*, not a symptom — and to mitigate the impact while that fix is built, as a developer, I want to use RCA techniques (like 5 Whys) to find a problem's root cause and a workaround, reaching Known Error.

## Acceptance criteria (INVEST Testable)

- [x] The ticket transitions `Open → Known Error` with a documented root cause + workaround (per ADR-022; the fix is *proposed* after) — shipped.
- [ ] The flow guides an **RCA technique** (e.g. 5 Whys) to find the *cause*, not a symptom — verify current behaviour (likely a refinement, not yet actively prompted).
- [x] A workaround is identified that mitigates impact while the root-cause fix is built.
- [x] No fix or RFC is required to reach Known Error (that's A3's job).

## Driving problem trace (I6)

**P170** — Known Error is the stable point from which a coordinated fix is decomposed.

## JTBD trace (I9)

**JTBD-008** — the decomposition (A3) fires on a Known Error.

## Related

- **STORY-MAP-002** A2 card. **ADR-022** — Known Error semantics. Shipped via `/wr-itil:manage-problem` + `transition-problem`.
