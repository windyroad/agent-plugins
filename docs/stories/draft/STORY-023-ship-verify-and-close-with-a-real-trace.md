---
status: done
story-id: ship-verify-and-close-with-a-real-trace
reported: 2026-07-02
decision-makers: [Tom Howard]
problems: [P170]
jtbd: [JTBD-008, JTBD-001]
adrs: [ADR-022]
story-maps: [STORY-MAP-002]
estimated-effort: M
human-oversight: unconfirmed
---

# STORY-023: Ship → verify → problem closes with a real trace; adopter gets the fix

**Story map:** [← STORY-MAP-002: Decompose a Fix Into Coordinated Changes](../../story-maps/draft/STORY-MAP-002-decompose-a-fix-into-coordinated-changes.html) · A5 (Release 1)
**Backbone:** [A1 capture](018-capture-the-problem-mid-flow.md) · [A2 root cause](019-record-root-cause-and-workaround.md) · A3 decompose ([start map](020-start-the-jobs-story-map.md) …) · [A4 work the stories](014-author-first-work-problems-afk.md) · A5 ship

## User value (INVEST Valuable)

As the developer (and the adopter who hit the problem), I want the coordinated fix to land, release, and verify — so the problem closes with a durable trace from problem → RFC → change, and the adopter gets the fix in a published release.

## Acceptance criteria (INVEST Testable) — SHIPPED

- [x] The fix is released; the ticket transitions `Known Error → Verifying → Closed` on real evidence (per ADR-022).
- [x] The reverse-trace (problem ↔ RFC ↔ stories) re-derives cleanly — every fix is traced (reinforced by ADR-089: every RFC has ≥1 story).
- [x] The adopter receives the fix in a published `@windyroad/*` release.

## Driving problem trace (I6)

**P170** — the journey's end: a coordinated fix shipped with a first-class trace above the commit level.

## JTBD trace (I9)

**JTBD-008** (the journey completes) · **JTBD-001** (governance trace holds end-to-end).

## Related

- **STORY-MAP-002** A5 card. **ADR-022** — verification lifecycle. Shipped via the release + `transition-problem` close flow.
