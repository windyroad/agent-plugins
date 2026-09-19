---
status: draft
story-id: the-loop-leaves-a-ticket-alone-while-it-is-waiting-on-someone-upstream
reported: 2026-09-19
decision-makers: [Tom Howard]
problems: [P441]
jtbd: [JTBD-006]
rfcs: [RFC-098]
story-maps: [STORY-MAP-011]
estimated-effort: S
---

# STORY-096: The loop leaves a ticket alone while it is waiting on someone upstream

**Reported**: 2026-09-19
**Problems**: P441
**JTBD**: JTBD-006
**RFCs**: RFC-098
**Story Maps**: STORY-MAP-011
**Estimated effort**: S — the markers already exist and one gate already reads them; the work is reading them one step earlier and closing the misfire collision in both places

## User value (required, INVEST Valuable)

In order to stop most of the loop's iterations going to tickets nobody here can move — five of six in one measured run — as a developer running the loop while I am away, I want an upstream-blocked ticket recognised before a dispatch is spent on it, without it dropping out of my view.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] A ticket carrying an upstream-report section or a pending-upstream-report marker is not dispatched, and the reason names the hold as owed upstream rather than by me.
- [ ] A ticket whose external-root-cause detection misfired — recorded through the documented recovery path, which reuses the real marker's own prefix — stays dispatchable. Holding it would strand every misfire-recovered ticket.
- [ ] The pre-dispatch check and the loop's end-of-run backlog check agree on that ticket. Two surfaces disagreeing is the divergence this work exists to remove, so the agreement is asserted rather than assumed.
- [ ] The hold never appears on my outstanding-questions queue — no answer of mine would change anything — but it does appear in the loop's summary.

## Driving problem trace (required — I6 invariant)

**P441** — face #315. Upstream-blocked tickets cycle back to the top of the queue because the ranking has no signal for placement authority, and each pass pays the full verify-and-skip cost. The reporter framed it as a ranking-signal gap; the settled mechanism is a pre-dispatch filter, which is what keeps the rank intact.

## JTBD trace (required — I9 invariant)

**JTBD-006** (Progress the Backlog While I'm Away, developer) — the job's audit-trail constraint is the load-bearing one here. The markers this reads are already the audit trail of what was reported upstream; reading them before dispatch rather than after costs nothing and saves the iteration.

## Implementation notes (optional)

P441 itself hit the misfire collision during its own capture: writing the canonical marker would have made the ticket non-dispatchable to the very gate it exists to fix. That is the fixture this story needs.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: human ratification of the recorded decision that dispatch eligibility is a separate axis from priority — `docs/decisions/132-dispatch-eligibility-is-a-separate-axis-from-priority.proposed.md`, born `human-oversight: unconfirmed` . Drawing this row and its cards left STORY-MAP-011's own approval intact — its oversight basis does not cover rows or cards — so the map is not a second gate. This story must also be accepted out of draft via `/wr-itil:manage-story` before it can be implemented.

## Related

- **P441** — driving problem, at Known Error.
- **STORY-097** — the return surface where an upstream hold is visible without being on my checklist.
