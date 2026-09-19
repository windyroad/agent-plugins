---
status: draft
story-id: when-i-come-back-i-can-see-what-is-held-who-owes-it-and-what-would-unstick-it
reported: 2026-09-19
decision-makers: [Tom Howard]
problems: [P441]
jtbd: [JTBD-006]
rfcs: [RFC-098]
story-maps: [STORY-MAP-011]
estimated-effort: S
---

# STORY-097: When I come back I can see what is held, who owes it, and what would unstick it

**Reported**: 2026-09-19
**Problems**: P441
**JTBD**: JTBD-006
**RFCs**: RFC-098
**Story Maps**: STORY-MAP-011
**Estimated effort**: S — summary shape and queue routing; no new detection, but the all-held ending is a distinct state the loop does not currently report

## User value (required, INVEST Valuable)

In order to read the loop's ending on my phone and know what it is waiting on without opening the repository, as a developer coming back to a loop I left running, I want every hold named with its owner and what would clear it — and my own checklist to carry only the things I can actually answer.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] The summary lists every held ticket grouped by who owes the hold — me, the loop, or upstream — each with what would clear it, in prose I can read from the message itself. Not a pointer to a file I cannot open, and not a bare class name standing in for the explanation.
- [ ] After a loop in which all four kinds of hold fired, my outstanding-questions queue carries the two that are mine and none of the other two, while all four still appear in the summary. What I can see and what I owe are different questions.
- [ ] A loop whose entire remaining backlog is held ends, rather than cycling — and says so in words that cannot be mistaken for an empty backlog. "Nothing left" and "everything left is waiting on someone" are opposite states.
- [ ] A held ticket still appears at its own position in the rankings I read, annotated as held.
- [ ] A hold recorded on one pass does not outlive the thing that clears it: the record is the last evaluation's result, not a suppression that lasts the session.

## Driving problem trace (required — I6 invariant)

**P441** — the reporting half of all three faces. The ticket's own constraint is that a held ticket must stop competing for a dispatch slot *without* being hidden from me and *without* its priority being silently dropped. The filtering is the other three stories; this one is the half that keeps the first constraint honest.

## JTBD trace (required — I9 invariant)

**JTBD-006** (Progress the Backlog While I'm Away, developer) — two outcomes meet here: that I can see what was worked, what was skipped and what remains, and that the loop stops gracefully when nothing actionable remains. An all-held backlog satisfies the second only if the first distinguishes it from an empty one. The persona's reading context — a phone, no filesystem, no memory of the session — is why the wording has to carry itself.

## Implementation notes (optional)

This story is what stops the queue-routing rule in the other three reading as suppression. A loop-owned or upstream-owned hold leaves my checklist; it never leaves the summary.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: human ratification of the recorded decision that dispatch eligibility is a separate axis from priority — `docs/decisions/132-dispatch-eligibility-is-a-separate-axis-from-priority.proposed.md`, born `human-oversight: unconfirmed` . Drawing this row and its cards left STORY-MAP-011's own approval intact — its oversight basis does not cover rows or cards — so the map is not a second gate. This story must also be accepted out of draft via `/wr-itil:manage-story` before it can be implemented.

## Related

- **P441** — driving problem, at Known Error.
- **STORY-094**, **STORY-095**, **STORY-096** — the three filtering stories whose holds this story reports.
- **STORY-059** (See why the loop did not work what I expected) — the existing return-surface contract for skips; this extends it to holds.
