---
status: accepted
story-id: a-reviewer-catches-first-match-binding-when-the-key-is-not-unique
reported: 2026-08-31
decision-makers: [Tom Howard]
problems: [P426]
jtbd: [JTBD-001]
rfcs: [RFC-084]
story-maps: [STORY-MAP-011]
estimated-effort: S
---

# STORY-078: A reviewer catches first-match binding when the key is not unique

**Reported**: 2026-08-31
**Problems**: P426
**JTBD**: JTBD-001 (Enforce Governance Without Slowing Down)
**RFCs**: RFC-084
**Story Maps**: STORY-MAP-011 (Trust the AFK loop's autonomous conduct), activity `decide`
**Estimated effort**: S

## User value (required, INVEST Valuable)

In order to trust AI-assisted architecture review to catch silent wrong-entity binding, as a developer, I want the reviewer to flag first-match selection when the identity, authorization, or data-binding key is not unique within the collection.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] A proposed change that selects the first match from a collection on a non-unique key and uses it for identity, authorization, or data binding receives an `ISSUES FOUND` verdict with a `[First-Match Footgun]` finding.
- [ ] The finding requires a unique key, explicit handling of multiple matches, or a cited uniqueness invariant.
- [ ] A unique-by-construction lookup used for the same decisions receives `PASS` without a `[First-Match Footgun]` finding.
- [ ] Paired behavioural evaluator fixtures prove the positive and over-fire cases.

## Driving problem trace (required — I6 invariant)

P426 records that the architecture reviewer has no standing heuristic for first-match selection from a non-unique collection, so silent wrong-entity binding can pass review.

## JTBD trace (required — I9 invariant)

- **JTBD-001**: the automatic architecture gate catches this security-relevant defect class without adding a manual review step.

## Implementation notes (optional)

Add the heuristic to `packages/architect/agents/agent.md` and paired positive/over-fire fixtures to `packages/architect/agents/eval/promptfooconfig.yaml`. Add no runtime dependency or new review abstraction.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- Inbound issue #169.
