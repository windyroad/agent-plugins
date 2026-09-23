---
status: accepted
story-id: pin-agent-eval-and-grader-models
reported: 2026-09-23
decision-makers: [Tom Howard]
problems: [P459]
jtbd: [JTBD-006]
rfcs: [RFC-102]
story-maps: [STORY-MAP-002]
estimated-effort: S
---

# STORY-101: Trust agent-prose CI across model updates

**Reported**: 2026-09-23
**Problems**: P459
**JTBD**: JTBD-006 (Progress the Backlog While I'm Away)
**RFCs**: RFC-102
**Story Maps**: STORY-MAP-002 (Take a problem from noticed to resolved), activity `implement`
**Estimated effort**: S

## User value (required, INVEST Valuable)

In order to trust agent-prose CI results across runs, as a developer using AI agents, I want the evaluated agent and semantic grader to use explicit, stable model versions instead of a changing CLI default.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] Every Claude agent-prose runner passes the exact `claude-sonnet-5` model ID.
- [ ] Every Claude semantic-rubric grader passes the exact `claude-opus-5-5` model ID.
- [ ] The CI availability probe uses the same Sonnet model as the evaluated agents.
- [ ] A runnable contract test fails if a runner, grader, or probe loses or swaps its model role.
- [ ] Existing sandbox, output, and bounded-retry behaviour remains unchanged.

## Driving problem trace (required — I6 invariant)

P459 identifies an unpinned judge model as part of the agent-prose CI flake class. The current harness also leaves the evaluated agent model to Claude Code's mutable default, so identical source can be exercised by different models across runs.

## JTBD trace (required — I9 invariant)

JTBD-006 requires unattended work to leave a trustworthy audit trail; stable model roles make a CI result attributable to the source under test instead of an unrecorded default-model change.

## Implementation notes (optional)

Use role-specific environment variables so CI declares the two model IDs once. Preserve exact full IDs rather than convenience aliases.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- ADR-075
- RFC-102 release row on STORY-MAP-002
