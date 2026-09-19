---
status: accepted
story-id: the-loop-i-left-running-is-still-running-when-i-get-back
reported: 2026-09-19
decision-makers: [Tom Howard]
problems: [P543]
jtbd: [JTBD-006]
rfcs: [RFC-099]
story-maps: [STORY-MAP-011]
estimated-effort: S
---

# STORY-098: The loop I left running is still running when I get back

**Reported**: 2026-09-19
**Problems**: P543
**JTBD**: JTBD-006
**RFCs**: RFC-099
**Story Maps**: STORY-MAP-011
**Estimated effort**: S — two contracts on an existing prose surface plus the eval case that holds them; no new detection and no new tooling

## User value (required, INVEST Valuable)

In order to get back to work that actually happened over the hours I was away, as a developer who starts the loop and then leaves, I want telling the loop I am going to bed to be the thing that keeps it working — and I want it to be unable to end the session by quietly not continuing.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] Asked what it does when the person who started the loop says they are going to bed, the orchestrator dispatches the next iteration. It does not read the announcement as permission to wrap up, and it does not ask whether it should carry on.
- [ ] Asked whether it may end its turn mid-loop having printed no ending, the orchestrator says it may not: it either names one of the loop's own endings or dispatches the next iteration, and there is no third state.
- [ ] A closing message that calls the drain parked, says it is ready when I am, or leaves me an instruction for restarting it is named as the defect rather than as an ending. The work of restarting the loop never becomes mine.
- [ ] The rule is stated where the loop is entered, not only where it ends, so an orchestrator that never reaches the ending gate is still covered by it. The ending it may name is the one the loop already publishes, not a second list that can drift from it.
- [ ] The rule speaks about the orchestrator's own session and leaves an iteration's endings alone.

## Driving problem trace (required — I6 invariant)

**P543** — the loop was invoked, ran its preflight, was interrupted for hours by unrelated direction, and was then read as finished when the maintainer said goodnight. Zero iterations ever dispatched. Every existing guard against a loop stopping early fires when the orchestrator is about to print its ending, so an orchestrator that stops by printing nothing passes all of them by reaching none. That is the gap this story closes.

## JTBD trace (required — I9 invariant)

**JTBD-006** (Progress the Backlog While I'm Away, developer) — the job whose whole subject is the hours the maintainer is not at the keyboard. The announcement of absence is the job's trigger; treating it as a stop defeats the job outright in the exact window it exists to use.

## Implementation notes (optional)

The surface is `packages/itil/skills/work-problems/SKILL.md` prose plus a case in its promptfoo eval. The contract for how long the loop stays live across an interruption is a separate, unrecorded decision and is deliberately not in this story — see Dependencies.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none) — for the two contracts above. The third contract P543 identifies, what the loop's state is when a user interrupts at the orchestrator level and redirects for hours, rests on an unrecorded decision about how long liveness survives a detour; it is out of this story's scope and needs its own ratified decision before any prose lands on it.

## Related

- **P543** — driving problem.
- **P390** — the closest sibling: the orchestrator stops while dispatchable backlog remains. Its fix guards the printed-ending path; this instance never reached that path.
- **ADR-094**, **ADR-128** — the external loop anchor, whose one-directional "forces continuation, never authorises a stop" property is what this failure needed, and the scope rule that keeps an orchestrator's endings distinct from an iteration's.
