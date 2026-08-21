---
status: draft
story-id: a-ticket-that-only-names-a-decision-as-background-stays-open
reported: 2026-08-21
decision-makers: [Tom Howard]
problems: [P463]
jtbd: [JTBD-006, JTBD-001]
rfcs: [RFC-070]
story-maps: [STORY-MAP-011]
estimated-effort: M
---

# STORY-064: A ticket that only names a decision as background stays open

**Reported**: 2026-08-21
**Problems**: P463
**JTBD**: JTBD-006 (Progress the Backlog While I'm Away), JTBD-001 (Enforce Governance Without Slowing Down)
**RFCs**: RFC-070 (release row on STORY-MAP-011 — a close rests on evidence the fix shipped, not on a decision the ticket names)
**Story Maps**: STORY-MAP-011 (Trust the AFK loop's autonomous conduct), activity `close`
**Estimated effort**: M

## User value (required, INVEST Valuable)

In order to come back to a backlog where nothing still outstanding was closed behind me, as a developer running the loop while I am away, I want a close to rest on evidence the fix shipped rather than on the ticket naming a decision.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] A ticket that names a ratified decision only where it gives background — its description, its dependencies, its related-work list — does not come back as a close candidate.
- [ ] A ticket that names an existing skill file only where it describes the problem does not come back as a close candidate.
- [ ] A ticket that names the same ratified decision where it records the fix landing still comes back as a close candidate, so the signal is narrowed rather than switched off.
- [ ] A verdict names where in the ticket its evidence was found, so the verdict can be checked without re-reading the ticket.
- [ ] Two scenarios run against the evaluator and assert on the verdict it emits: a ticket citing a ratified decision from its related-work list comes back KEEP, and the same ticket with that citation moved under a fix-released heading comes back a close candidate.

## Driving problem trace (required — I6 invariant)

P463 — the relevance-close evaluator's `ADR-shipped-confirmed` and `named-skill-or-feature-exists` shapes search the whole ticket body, so naming a ratified decision or an existing skill path anywhere in a ticket reads as proof that ticket's fix shipped. Measured 2026-08-21: 81% of 135 open and known-error tickets returned a close verdict against a documented ~4.2% expectation; seven were clean verdicts, which the unattended pass closes with no prompt, and all seven were live. This story narrows where the two shapes look.

## JTBD trace (required — I9 invariant)

- **JTBD-006** (primary) — its 2026-07-26 amendment reads "verification is untouched — the loop still never decides that a fix works". A clean close verdict drawn from a ratified-decision citation is the loop deciding a fix works from evidence that only proves a decision was agreed. This story restores that boundary.
- **JTBD-001** (secondary) — an 81% verdict rate against a ~4.2% expectation forces the maintainer to hand-check every verdict, which defeats the job's "reviews complete in under 60 seconds so they don't break flow" outcome.

## Implementation notes (optional)

Held pending a ratified decision. Narrowing the two shapes' search region changes the mechanical check ADR-079 records, and ADR-079 is ratified, so under ADR-116 it changes only by supersession. Under ADR-103 implementation is refused while the proposal needs an unratified ADR. The option set is recorded on P463 and queued for the maintainer.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: the superseding decision for ADR-079's shape-2 and shape-3 mechanical checks (not yet recorded — queued on P463).

## Related

- Captured via `/wr-itil:capture-story` during a `/wr-itil:work-problems` iteration on P463.
- Sibling on the same map activity: STORY-052 (before a close lands, the still-open siblings in the same family are surfaced), under release row RFC-056.
