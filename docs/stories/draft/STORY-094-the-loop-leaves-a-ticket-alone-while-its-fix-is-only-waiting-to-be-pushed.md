---
status: draft
story-id: the-loop-leaves-a-ticket-alone-while-its-fix-is-only-waiting-to-be-pushed
reported: 2026-09-19
decision-makers: [Tom Howard]
problems: [P441]
jtbd: [JTBD-006]
rfcs: [RFC-098]
story-maps: [STORY-MAP-011]
estimated-effort: S
---

# STORY-094: The loop leaves a ticket alone while its fix is only waiting to be pushed

**Reported**: 2026-09-19
**Problems**: P441
**JTBD**: JTBD-006
**RFCs**: RFC-098
**Story Maps**: STORY-MAP-011
**Estimated effort**: S — one class of an existing predicate, derived from git with no new state; the invalidate-on-push clause is the part that needs care

## User value (required, INVEST Valuable)

In order to stop paying for the loop to rediscover work it finished minutes ago, as a developer running the loop while I am away, I want a ticket whose fix is already committed to sit out the next pass until the commit reaches `origin`.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] A Known Error with an unpushed fix-shaped commit referencing it is not dispatched, and the reason recorded names the hold as owed by the loop rather than by me.
- [ ] A commit that merely mentions the ticket does not hold it. A problem capture and a briefing refresh both name tickets in their subjects; neither is a fix, and neither holds.
- [ ] The hold clears once the commit reaches `origin`, within the same loop and with no action from me — including in a repository that has no release cadence at all.
- [ ] A repository with no upstream branch configured reads not-held rather than erroring.
- [ ] The hold never appears on my outstanding-questions queue, because it is not mine to answer.

## Driving problem trace (required — I6 invariant)

**P441** — face #312. A Known Error whose fix was committed this loop but not yet pushed stays top-of-WSJF and is re-selected; the existing relevance gate keys on *already-shipped*, so this transient state falls through it and the loop pays a full dispatch to rediscover its own work.

## JTBD trace (required — I9 invariant)

**JTBD-006** (Progress the Backlog While I'm Away, developer) — the job already promises the loop drains push and release queues between iterations so risk does not silently accumulate. This story is the selection-side consequence of that promise: while the drain is pending, the ticket it covers is not work, and treating it as work is what burns the iteration.

## Implementation notes (optional)

The signal is git, not a marker, so there is nothing to keep in sync. The care is in the match: it needs a conventional `fix` / `feat` / `refactor` / `perf` type or a `Refs:` / `Fixes:` trailer naming the ticket, and must exclude problem-capture and briefing-refresh subjects.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: human ratification of the recorded decision that dispatch eligibility is a separate axis from priority — `docs/decisions/132-dispatch-eligibility-is-a-separate-axis-from-priority.proposed.md`, born `human-oversight: unconfirmed` . Drawing this row and its cards left STORY-MAP-011's own approval intact — its oversight basis does not cover rows or cards — so the map is not a second gate. This story must also be accepted out of draft via `/wr-itil:manage-story` before it can be implemented.

## Related

- **P441** — driving problem, at Known Error.
- **STORY-097** — the return surface where this hold is reported without landing on my checklist.
