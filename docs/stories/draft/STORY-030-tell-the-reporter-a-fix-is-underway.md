---
status: draft
story-id: tell-the-reporter-a-fix-is-underway
reported: 2026-07-02
decision-makers: [Tom Howard]
problems: [P170]
jtbd: [JTBD-008, JTBD-301]
adrs: [ADR-062]
story-maps: [STORY-MAP-002]
estimated-effort: S
human-oversight: confirmed
oversight-confirmed-date: "2026-07-02 — ratified via AskUserQuestion (per-story pass, inbound thread)"
---

# STORY-030: Tell the reporter a fix is underway

**Story map:** [← STORY-MAP-002: Decompose a Fix Into Coordinated Changes](../../story-maps/draft/STORY-MAP-002-decompose-a-fix-into-coordinated-changes.html) · A3/A4 (Release 1) — inbound touchpoint
**Backbone (inbound thread):** [A1 capture-inbound](027-capture-a-problem-from-an-inbound-channel.md) · [A1 acknowledge](028-acknowledge-the-inbound-report.md) · [A2 share workaround](029-share-the-workaround-with-the-reporter.md) · A3/A4 fix underway · [A5 released → verify → close](031-tell-the-reporter-released-and-close-the-loop.md)

## User value (INVEST Valuable)

In order that the reporter knows the fix is really being worked — not stalled or forgotten, so they stay engaged instead of escalating or re-reporting — as a maintainer, I want the channel updated when a fix is underway (an RFC is accepted / implementation has started).

## Acceptance criteria (INVEST Testable)

- [ ] When an inbound-origin ticket gets an accepted RFC / enters implementation, the reporter's channel is updated that a fix is underway (with a link to the RFC/tracking where appropriate).
- [ ] No over-promise of a delivery date; no confidential internal detail leaked.
- [ ] Mirrors the `update-upstream` machinery (external-party progress update).

## Driving problem trace (I6)

**P170** — silence during the build erodes reporter trust; a progress update keeps them engaged. **ADR-062** — inbound handling.

## JTBD trace (I9)

**JTBD-301** — the reporter stays informed. **JTBD-008** — the inbound thread.

## Related

- **STORY-MAP-002** A3/A4 inbound card. **Precedent to mirror:** `update-upstream`. Lowest-priority of the inbound touchpoints (the acknowledge / workaround / released updates matter more). To build.
