---
status: accepted
story-id: a-fix-i-can-prove-works-gets-closed-without-me
reported: 2026-08-24
decision-makers: [Tom Howard]
problems: [P519]
jtbd: [JTBD-006, JTBD-001]
rfcs: [RFC-072]
story-maps: [STORY-MAP-002]
estimated-effort: M
---

# STORY-066: A fix I can prove works gets closed without me

**Reported**: 2026-08-24
**Problems**: P519
**JTBD**: JTBD-006 (Progress the Backlog While I'm Away), JTBD-001 (Enforce Governance Without Slowing Down)
**RFCs**: RFC-072 (release row on STORY-MAP-002 — a fix I can prove works gets closed without me)
**Story Maps**: STORY-MAP-002 (Take a problem from noticed to resolved), activity `land-release-verify`
**Estimated effort**: M

## User value (required, INVEST Valuable)

In order to stop being the only exit from a queue that never stops growing, as a developer whose backlog holds 153 tickets waiting on a confirmation only I can give, I want the agent to close a ticket when it can show me proof the fix works — and to leave the rest alone.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [x] A ticket whose fix the agent has just exercised, with something it can point at, gets closed by the agent — not queued for my return — and the closure says what it saw.
- [x] A ticket nobody exercised is not closed, however long it has been sitting there and however obviously the fix is on disk. Age is not proof.
- [x] The evidence that counts is something observed. A fix having been released does not count, because every ticket in this queue was released — that is why it is in the queue.
- [x] A ticket I have marked do-not-close stays closed to the agent even when the tests pass, and the reason it was left alone is reported rather than the ticket quietly vanishing from the candidate list.
- [x] Whether a ticket carries that marker is a mechanical check, not something the next agent has to happen to notice while reading.
- [x] Discussing the marker in a ticket body — quoting it, explaining it, shipping the check that detects it — does not accidentally block that ticket.
- [x] The unattended loop can reach the verification queue at all: an evidence-bearing ticket shows up in the loop's own dispatchability table, and the loop does not declare itself finished while one is sitting there.
- [x] Verification still does not compete with development for a priority slot — it drains in a pass of its own.
- [x] Closing a ticket that came from someone else's bug report does not close their issue. We told them we would wait for their confirmation; our own test passing is not their confirmation.
- [x] Every close reports how to undo it, in one command.

## Driving problem trace (required — I6 invariant)

P519 — four shipped skills reserved the Verification Pending to Closed transition for the maintainer, so an agent could run the test suite, watch the fix pass, and still decline to close the ticket. The queue had no exit path that did not route through one person: 153 tickets, exactly one carrying a populated evidence cell. Raised as a repeat correction on 2026-08-24 — *"If you have evidence of a problem being closed then you close it. This explains why we have so many unclosed problems."*

## JTBD trace (required — I9 invariant)

- **JTBD-006** (primary) — the job asks that the loop drain its queues so nothing silently accumulates, and that what needs my judgment be queued rather than guessed at. The reservation got both halves wrong at once: it queued for my judgment a class of thing that needs no judgment, and in doing so let a queue accumulate to 153. The narrowing this story lands keeps the second half intact — no evidence still means no close — while removing the first.
- **JTBD-001** (secondary) — two surfaces already closed on evidence and four refused to. A governance rule that contradicts itself is not enforcement, it is friction, and the surface the loop actually routes through was the refusing one.

## Implementation notes (optional)

The three-state shape is not new: `review-problems` Bucket 1/2/3 has shipped it since P186, reviewed. This propagates that template rather than inventing a policy, which is why no new decision record is owed.

Two things decide whether the change works rather than merely reads correctly. The loop's own backlog re-scan has to enumerate the verification queue — the prose can authorise all it likes, but a ticket that never appears in the scan can never be classified reachable. And the do-not-close marker has to become a predicate with an exit code, because a rule that lives only in prose erodes the first time someone is in a hurry.

The external-reporter carve-out is the part most likely to be lost: it is not about the local ticket at all, it is about not closing a stranger's issue on the strength of our own test run.
