---
status: draft
story-id: every-conversion-tells-the-reporter-it-landed
reported: 2026-09-19
decision-makers: [Tom Howard]
problems: [P432]
jtbd: [JTBD-301, JTBD-006]
rfcs: [RFC-097]
story-maps: [STORY-MAP-004]
estimated-effort: M
---

# STORY-093: Every conversion tells the reporter it landed

**Reported**: 2026-09-19
**Problems**: P432
**JTBD**: JTBD-301, JTBD-006
**RFCs**: RFC-097
**Story Maps**: STORY-MAP-004
**Estimated effort**: M — the acknowledgement itself already exists and already has a gate chain; the work is moving it from one branch of the discovery pipeline to the conversion event, and giving the conversion somewhere to record which channel the report came from.

## User value (required, INVEST Valuable)

In order to know my report was received and is being handled — rather than watching something I filed sit silent for months — as someone who reported a problem, I want the project to answer me when my report becomes a ticket, whichever way I sent it.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] Converting an inbound report into a ticket records where the report came from in a form that names the channel as well as the entry, so a later step can reach it without reconstructing it from a cache that can be regenerated.
- [ ] The same conversion marks the source entry as converted and carries the new ticket's reference, on the channel the reporter used.
- [ ] The reporter gets the accepted-into-backlog acknowledgement at conversion time, composed through the existing external-comms and voice-tone gates, with nothing in the body that only a maintainer would understand.
- [ ] This happens on every route that turns an inbound report into a ticket, not only the discovery pipeline's own branch.
- [ ] Resolution is fail-closed: zero matches, more than one match, or a repository mismatch records the conversion and queues the acknowledgement, and changes nothing on any external system.
- [ ] A channel with no adapter yet records the conversion and queues the acknowledgement rather than failing the conversion.
- [ ] The count P432's Reproduction section prints reads zero for conversions made after this ships.

## Driving problem trace (required — I6 invariant)

**P432** — the acknowledgement lives in one branch of the GitHub discovery pipeline, so the other conversion routes skip it in silence; no route writes the source entry's own state; and the ticket's `**Origin**` field is a bare number that cannot name a channel, so nothing can dispatch to one. Measured on the live tracker: 41 of 53 converted reports have never received a comment, issue #347 among them.

## JTBD trace (required — I9 invariant)

**JTBD-301** (Report a Problem Without Pre-Classifying It, plugin-user) — the desired outcome is that submitted reports receive a *predictable* acknowledgement. An acknowledgement that only fires on one branch is not predictable, which is what criteria 2-4 close. Criterion 3 carries the persona's "low context on repo internals" constraint onto the outbound leg: the reporter should not have to decode a status name or a ticket number to learn they were heard.

**JTBD-006** (Progress the Backlog While I'm Away, developer) — criteria 5 and 6 are the unattended-loop half. A conversion that cannot prove which external entry it is looking at must queue rather than guess, and a channel nobody has written an adapter for must not take the conversion down with it.

## Implementation notes (optional)

**Blocked on a decision that is not ours to make.** The acknowledgement leg is covered by decisions already ratified — ADR-062 decides that a conversion-time acknowledgement carrying the ticket reference goes out through the ADR-028 gate chain, so extending it to every route repairs an implementation gap rather than choosing anything new. The first criterion is different: recording the channel on the ticket changes the `**Origin**` vocabulary that ADR-076 ratified, and it touches the provenance rule ADR-121 fixed (an inbound mutation must resolve to exactly one committed cache record, or it does nothing). That needs a new decision superseding ADR-076 in part, and it is queued for the maintainer. Implementation waits for it.

**Relationship to STORY-028** (Acknowledge the report on capture, RFC-061): STORY-028 is the single-channel instance — it acknowledges on the inbound channel at capture, and RFC-061 keeps it. This story is the generalisation: the same promise on every conversion route and every channel, with the channel recorded so a non-GitHub source can be reached at all. If STORY-093 ships first, STORY-028's criteria are satisfied by it.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: the pending decision on how a conversion records its source channel (queued for the maintainer; supersedes ADR-076 in part, and carries the ADR-121 provenance-authority question with it).

## Related

- **P432** — driving problem, at Known Error.
- **STORY-028** — the single-channel instance this story generalises.
- **ADR-062**, **ADR-028**, **ADR-121** — the decisions the acknowledgement leg leans on.
