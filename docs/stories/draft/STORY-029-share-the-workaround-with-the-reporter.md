---
status: draft
story-id: share-the-workaround-with-the-reporter
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

# STORY-029: Share the workaround with the reporter

**Story map:** [← STORY-MAP-002: Decompose a Fix Into Coordinated Changes](../../story-maps/draft/STORY-MAP-002-decompose-a-fix-into-coordinated-changes.html) · A2 (Release 1) — inbound touchpoint
**Backbone (inbound thread):** [A1 capture-inbound](027-capture-a-problem-from-an-inbound-channel.md) · [A1 acknowledge](028-acknowledge-the-inbound-report.md) · A2 share workaround · [A3/A4 fix underway](030-tell-the-reporter-a-fix-is-underway.md) · [A5 released → verify → close](031-tell-the-reporter-released-and-close-the-loop.md)

## User value (INVEST Valuable)

In order that the person hitting the problem can unblock themselves now — rather than waiting idle for the full fix — as a maintainer, I want the documented workaround posted back to the reporter's channel once we reach Known Error.

## Acceptance criteria (INVEST Testable)

- [ ] When a ticket with an inbound origin reaches Known Error (workaround documented — [STORY-019](019-record-root-cause-and-workaround.md)), the workaround is posted to the reporter's channel.
- [ ] The post is scrubbed of confidential internal detail (external-comms discipline).
- [ ] Mirrors the existing `update-upstream` machinery (same "post an update to an external party's channel," aimed at the inbound reporter instead of an upstream dependency).

## Driving problem trace (I6)

**P170** — a reporter blocked by the problem shouldn't wait idle when a workaround already exists. **ADR-062** — inbound handling.

## JTBD trace (I9)

**JTBD-301** — the plugin-user reporter gets unblocked. **JTBD-008** — the inbound thread.

## Related

- **STORY-MAP-002** A2 inbound card. **Precedent to mirror:** `report-upstream` / `update-upstream` / `check-upstream-responses` (the upstream direction of the same pattern). To build.
