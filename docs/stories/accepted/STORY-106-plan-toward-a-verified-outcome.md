---
status: accepted
story-id: plan-toward-a-verified-outcome
reported: 2026-10-15
decision-makers: [Tom Howard]
problems: [P557]
jtbd: [JTBD-008, JTBD-005]
rfcs: [RFC-106]
story-maps: [STORY-MAP-002]
estimated-effort: M
---

# STORY-106: Keep my objective clear while I deliver, learn and replan

**Reported**: 2026-10-15
**Problems**: P557
**JTBD**: JTBD-008, JTBD-005
**RFCs**: RFC-106
**Story Maps**: STORY-MAP-002
**Estimated effort**: M - one canonical skill, bounded projection correction,
behavioral evaluation, package qualification and the existing release workflow.

## User value

In order to reach a verified result while learning from delivery, as a developer,
I want the agent to keep one detailed Now increment, provisional Next increments
and high-level Later direction, reassessing the plan after each delivery.

## Acceptance criteria

- [ ] The canonical and generated skill separate the objective and completion
  evidence from the proposed means, with one detailed Now, provisional Next and
  high-level Later.
- [ ] Actual model scenarios for both skill projections require architect and
  risk assessment before dependent implementation, replan after invalidated
  assumptions or failed verification, and preserve authority when a reviewer is
  unavailable.
- [ ] Scenarios stop when the overall objective is verified, discard unnecessary
  speculative work, and require fresh assessments for newly requested work.
- [ ] Packed and isolated installed artifacts expose the new skill under the
  correct runtime names without unrelated mandatory hang-off delegation;
  existing skills retain their delegation behavior.
- [ ] The stable npm artifact and fresh installation are verified after the
  implementation pipeline and separate cumulative release preparation pass.

## Driving problem trace

P557 records the absent published planning capability and the initial local-only
completion. Deliver the skill through ITIL's established distribution rather
than treating its personal source as publication evidence.

## JTBD trace

JTBD-008 supplies incremental delivery through the existing planning vehicle;
JTBD-005 supplies the architecture and risk assessment checkpoints. The skill
composes with each adopter's governing planning and delivery requirements.

## Implementation notes

Reuse `packages/itil/skills/` and the Codex projector. Omit the projector's
capture-specific delegation only for this skill. Add metadata and README
discovery. Exercise six semantic scenarios against both projections, extend
packed installation checks, and qualify from outside the source checkout.
Implementation stays STAGED without a changeset until its exact CI passes;
then prepare the complete cumulative minor release separately.

## Dependencies

- **Blocks**: none.
- **Blocked by**: none; the existing map is ratified and the required reviews
  approve the bounded package and projection scope.

## Related

- Captured via the RFC-row and story workflows on the existing decompose activity.
- Architecture and risk assessments of plan P4 cover the bounded source scope;
  actual changes and release preparation still require their own checks.
