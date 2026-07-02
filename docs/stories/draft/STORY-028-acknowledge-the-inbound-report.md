---
status: draft
story-id: acknowledge-the-inbound-report
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

# STORY-028: Acknowledge the report on capture

**Story map:** [← STORY-MAP-002: Decompose a Fix Into Coordinated Changes](../../story-maps/draft/STORY-MAP-002-decompose-a-fix-into-coordinated-changes.html) · A1 (Release 1) — inbound touchpoint
**Backbone (inbound thread):** [A1 capture-inbound](027-capture-a-problem-from-an-inbound-channel.md) · A1 acknowledge · [A2 share workaround](029-share-the-workaround-with-the-reporter.md) · [A3/A4 fix underway](030-tell-the-reporter-a-fix-is-underway.md) · [A5 released → verify → close](031-tell-the-reporter-released-and-close-the-loop.md)

## User value (INVEST Valuable)

In order that the person who reported the problem knows they were heard and it's being handled — instead of wondering whether it vanished into the void — as a maintainer, I want the inbound channel updated to acknowledge the report when it's captured.

## Acceptance criteria (INVEST Testable)

- [ ] When an inbound report is triaged into a ticket ([STORY-027](027-capture-a-problem-from-an-inbound-channel.md)), the channel gets an acknowledgement (received + triaged, with the ticket reference).
- [ ] The acknowledgement is respectful and sets expectations without over-promising a timeline.
- [ ] No confidential internal detail leaks to the external channel (per the external-comms discipline).

## Driving problem trace (I6)

**P170** — a reported problem that gets silently swallowed erodes trust; acknowledging keeps the reporter engaged. **ADR-062** — inbound-report handling.

## JTBD trace (I9)

**JTBD-301** — the plugin-user reporter is heard. **JTBD-008** — the inbound thread of the fix journey.

## Related

- **STORY-MAP-002** A1 inbound-acknowledge card. First of the per-beat inbound touchpoints. To build.
