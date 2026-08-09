---
status: draft
story-id: see-why-the-loop-did-not-work-what-i-expected
reported: 2026-08-09
decision-makers: [Tom Howard]
problems: [P487]
rfcs: [RFC-065]
jtbd: [JTBD-006, JTBD-002]
story-maps: [STORY-MAP-011]
estimated-effort: M
---

# STORY-059: See why the loop did not work what I expected

## User value (INVEST Valuable)

In order to find out why something I expected to be worked was not, as a developer surprised by the morning summary of a loop that chose for itself overnight, I want to see whether that ticket was outranked, skipped for a stated reason, or never considered at all — so I can tell an ordering I disagree with from one the loop never made.

## Acceptance criteria (INVEST Testable)

- [ ] Given a ticket I expected to see worked, the record tells me which of three things happened: it was outranked, it was skipped for a stated reason, or it was never considered. Those are indistinguishable today, and the third is the one that matters — a ticket the loop never saw will keep not being seen.
- [ ] Each iteration records what it chose between: the tier it worked, the tickets that were dispatchable at that moment, and where the winner sat among them. Recorded when the choice is made, not reconstructed afterwards — by then the ranking has been overwritten by the loop's own captures and transitions.
- [ ] A higher tier being passed over is visible. That is the error the tiering exists to prevent and there is precedent for it happening; the record has to make it findable rather than merely permit its reconstruction.
- [ ] The record answers the question without archiving state. A full backlog snapshot per iteration is noise nobody reads. Enough to see the choice was sound; no more.
- [ ] It survives the run. The evidence outlives the ranking table it came from, since that table is regenerated on every capture and transition.
- [ ] Behavioural test: a run that works a lower-tier ticket while a higher tier is non-empty produces a record that shows it. Both directions — a sound choice must not produce a warning, or the signal gets ignored.

## Notes

**This is a diagnostic, not a daily surface.** Nobody audits a run they are happy with. It earns its place the morning something is missing — and it is deliberately rated low for that reason.

The choice itself is not in question. Selection is a tier partition and a multi-key sort with no judgement in it, and the skill documents it fully — this story adds no discretion and removes none.

What it fixes is that the reasoning is legible only in the instant it happens. The pick is the top row of the rankings table at that moment, and the loop rewrites that table every time it captures or transitions anything. A night's work destroys the evidence for the night's decisions, one regeneration at a time.

The summary already explains **skips**, with a reason per skipped ticket. It has never explained **choices**, because a choice was never a judgement — it was a sort, and nobody records the state of a sort. That asymmetry is the whole gap: the things not done are accounted for, and the things done are not.

The card this backs sits in **"Decide what to do"** on STORY-MAP-011, the map named for trusting the loop's autonomous conduct. Authority to work unattended rests on the selection being defensible, and defensible-in-principle is a different property from inspectable-in-the-morning.

The precedent that makes the omission case concrete rather than theoretical: an inbound-reported ticket was once skipped entirely, and the loop gained a re-scan gate because of it. Nothing recorded which tier was non-empty at the time, so nothing would have shown it.
