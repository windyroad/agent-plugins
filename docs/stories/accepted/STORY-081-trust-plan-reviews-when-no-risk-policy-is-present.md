---
status: accepted
story-id: trust-plan-reviews-when-no-risk-policy-is-present
reported: 2026-08-31
decision-makers: [Tom Howard]
problems: [P459]
jtbd: [JTBD-001]
rfcs: [RFC-087]
story-maps: [STORY-MAP-002]
estimated-effort: S
---

# STORY-081: Trust plan reviews when no risk policy is present

**Reported**: 2026-08-31
**Problems**: P459
**JTBD**: JTBD-001 (Enforce Governance Without Slowing Down)
**RFCs**: RFC-087
**Story Maps**: STORY-MAP-002 (Take a problem from noticed to resolved), activity `implement`
**Estimated effort**: S

## User value (required, INVEST Valuable)

In order to trust automated plan-risk reviews, as a developer using AI agents, I want the plan scorer to use the documented default appetite and apply the boundary consistently when a policy omits the Risk Appetite section, so unrelated releases are not blocked by inconsistent verdicts.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [x] Given no Risk Appetite section and authoritative supplied scores, the actual plan agent returns PASS at 5/25 and FAIL when projected release risk is 6/25.
- [x] The agent source and its generated native Codex surface both define the same default-appetite and strict-boundary behaviour.
- [ ] Published risk-scorer release notes describe the corrected plan-review behaviour.

## Driving problem trace (required — I6 invariant)

P459 records that the plan-agent boundary case can red-line unrelated CI runs because the agent source did not define the documented default appetite when the policy section is absent.

## JTBD trace (required — I9 invariant)

JTBD-001 requires automatic governance that preserves safety without avoidable review friction; a deterministic documented boundary keeps that automation trustworthy.

## Implementation notes (optional)

Reuse ADR-086's default appetite of 5 and the existing actual-agent boundary fixtures. Do not move the boundary, weaken the assertion, reduce trial counts, or retry until a wrong value passes.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- ADR-052, ADR-075, ADR-086
- `packages/risk-scorer/agents/eval/promptfooconfig.yaml`
