---
status: in-progress
story-id: keep-problem-ranking-correct-after-a-status-transition
reported: 2026-08-14
decision-makers: [Tom Howard]
problems: [P498]
rfcs: [RFC-068]
jtbd: [JTBD-006, JTBD-001]
story-maps: [STORY-MAP-002]
estimated-effort: S
---

# STORY-062: Keep problem ranking correct after a status transition

## User value (INVEST Valuable)

In order to trust the problem backlog's choice of next work, as a developer using that ranking, I want a ticket's WSJF to use its current lifecycle status.

## Acceptance criteria (INVEST Testable)

- [x] Both automatic review flows transition an eligible Open problem to Known Error before calculating and persisting WSJF.
- [x] The WSJF calculation reads the multiplier from the status the ticket holds after the transition.
- [x] All three Open to Known Error checklists require the status multiplier to be re-rated alongside Effort.
- [x] Focused Promptfoo workflow evaluations fail if either review flow persists the pre-transition multiplier or a transition omits the multiplier re-rate.
- [x] Existing Claude Code and Codex skill packaging remains unchanged; this is shared skill prose and test behaviour.

## Driving problem trace

P498 records that both review flows persist the Open multiplier before changing the ticket to Known Error, while every transition checklist mentions only the Effort re-rate. This story corrects those existing surfaces without adding another command or runtime path.

## JTBD trace

- **JTBD-006**: correct ranking lets unattended backlog work select the intended next problem.
- **JTBD-001**: the governance calculation remains reliable without adding ceremony to each transition.

## Implementation notes

ADR-022 defines the lifecycle multiplier; ADR-010 requires the checklist copies to remain in lockstep; ADR-052 requires behavioural evaluation of the affected workflows. The rejected diagnostic command is unnecessary once the workflow ordering and its regression coverage are corrected.

## Dependencies

- **Blocks**: none.
- **Blocked by**: none.

## Related

- STORY-MAP-002 - Take a problem from noticed to resolved
- RFC-068 - Keep problem ranking correct across status transitions
- GitHub issue #413 and pull request #415
