---
status: draft
story-id: tell-the-reporter-released-and-close-the-loop
reported: 2026-07-02
decision-makers: [Tom Howard]
problems: [P170]
jtbd: [JTBD-008, JTBD-301]
adrs: [ADR-062, ADR-022]
story-maps: [STORY-MAP-002]
estimated-effort: M
human-oversight: confirmed
oversight-confirmed-date: "2026-07-02 — ratified via AskUserQuestion (per-story pass, inbound thread)"
---

# STORY-031: Tell the reporter it's released → verify → close the loop

**Story map:** [← STORY-MAP-002: Decompose a Fix Into Coordinated Changes](../../story-maps/draft/STORY-MAP-002-decompose-a-fix-into-coordinated-changes.html) · A5 (Release 1) — inbound touchpoint
**Backbone (inbound thread):** [A1 capture-inbound](027-capture-a-problem-from-an-inbound-channel.md) · [A1 acknowledge](028-acknowledge-the-inbound-report.md) · [A2 share workaround](029-share-the-workaround-with-the-reporter.md) · [A3/A4 fix underway](030-tell-the-reporter-a-fix-is-underway.md) · A5 released → verify → close

## User value (INVEST Valuable)

In order that the person who reported the problem gets the resolution — knows the fix shipped, can confirm it works for them, and sees the loop closed rather than left hanging — as a maintainer, I want to tell them it's released and close the channel on their confirmation.

## Acceptance criteria (INVEST Testable)

- [ ] When an inbound-origin ticket's fix is released (its problem reaches Verifying — [STORY-023](023-ship-verify-and-close-with-a-real-trace.md)), the reporter's channel is told which release contains the fix, with a request to verify.
- [ ] On the reporter's confirmation, the channel is closed (loop closed); the problem's verification close (ADR-022) and the channel close are consistent.
- [ ] No confidential internal detail leaked; the message is respectful and complete.
- [ ] Mirrors the `update-upstream` / `check-upstream-responses` machinery (external-party close-the-loop).

## Driving problem trace (I6)

**P170** — a reported problem left un-closed for the reporter (even after it's fixed internally) reads as ignored; closing the loop is the resolution *they* experience. **ADR-022** — the internal verification-close this mirrors externally.

## JTBD trace (I9)

**JTBD-301** — the reporter gets and confirms the resolution. **JTBD-008** — the inbound thread's end, paired with [STORY-023](023-ship-verify-and-close-with-a-real-trace.md).

## Related

- **STORY-MAP-002** A5 inbound card. **Precedent to mirror:** `update-upstream` + `check-upstream-responses`. The external-facing pair of STORY-023 (internal ship/verify/close). To build.
