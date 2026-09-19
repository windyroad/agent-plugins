---
status: draft
story-id: the-loop-leaves-a-ticket-alone-while-it-is-waiting-on-my-answer
reported: 2026-09-19
decision-makers: [Tom Howard]
problems: [P441]
jtbd: [JTBD-006]
rfcs: [RFC-098]
story-maps: [STORY-MAP-011]
estimated-effort: M
---

# STORY-095: The loop leaves a ticket alone while it is waiting on my answer

**Reported**: 2026-09-19
**Problems**: P441
**JTBD**: JTBD-006
**RFCs**: RFC-098
**Story Maps**: STORY-MAP-011
**Estimated effort**: M — two classes, both reading prose, and the prose is where the false-positive risk lives; the corpus already contains the shapes that defeat a naive match

## User value (required, INVEST Valuable)

In order to stop the queue handing me the same blocked ticket every pass — one of mine sat at the top for two months, able only to re-confirm its own block — as a developer running the loop while I am away, I want a ticket that is waiting on my answer to stop competing for a dispatch slot while staying exactly where it is in my rankings.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] A ticket whose `- **Blocked by**:` line names a person-gated hold is not dispatched, and the reason names me as the one who owes it.
- [ ] A ticket whose fix path names a skill only an attended session can run is not dispatched, and it queues one question so it reaches me at the end of the loop rather than only in a record I may never open.
- [ ] A `Blocked by` value opening `(none`, `none` or `N/A`, or struck through, does not hold the ticket however many hold keywords its prose contains. Seven of the corpus's recorded lines say "none" and still carry one; several of those explicitly declare the ticket buildable now.
- [ ] A ticket carrying two `Blocked by` lines — one `(none — …)`, one a real hold — reads held in either order.
- [ ] A ticket blocked on another ticket rather than on a person stays dispatchable. A dependency is not a person-hold.
- [ ] The held ticket's score, tier and rankings row are byte-identical before and after a loop that filtered it.

## Driving problem trace (required — I6 invariant)

**P441** — face #318. The loop re-selects tickets carrying an open queued direction question, or whose fix path names an interaction-bound authoring skill, every pass as highest-WSJF. Transitioning such a ticket to Known Error raises its score on the status multiplier, so it re-selects *higher* while still unable to move: the ranking rewards it for being stuck.

## JTBD trace (required — I9 invariant)

**JTBD-006** (Progress the Backlog While I'm Away, developer) — the job promises that problems requiring my judgment are queued for my return, not guessed at. Today they are queued *and* re-dispatched, which is the worst of both. The rank-invariance criterion is what keeps this from becoming the parking the job's own workaround section rejects: a ticket waiting on me is not worth less.

## Implementation notes (optional)

The interaction-bound class must not double-queue a question the existing ratification predicate already raised, or my return table carries the same row twice.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: human ratification of the recorded decision that dispatch eligibility is a separate axis from priority — `docs/decisions/132-dispatch-eligibility-is-a-separate-axis-from-priority.proposed.md`, born `human-oversight: unconfirmed` . Drawing this row and its cards left STORY-MAP-011's own approval intact — its oversight basis does not cover rows or cards — so the map is not a second gate. This story must also be accepted out of draft via `/wr-itil:manage-story` before it can be implemented.

## Related

- **P441** — driving problem, at Known Error.
- **STORY-097** — the return surface these two classes report through.
