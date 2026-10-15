---
status: done
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

- [x] Actual interview turns ask one missing question at a time and wait,
  play back the SMART outcome and wait for explicit confirmation before
  executable planning; substantive goal changes require reconfirmation.
- [x] Now uses INVEST without introducing unnecessary story documents, and a
  substantive JTBD rejection blocks dependent work until resolved and reassessed.

- [x] When context leaves the outcome too vague, the skill elicits the desired
  change, beneficiary and completion evidence before implementation planning.

- [x] The canonical and generated skill separate the objective and completion
  evidence from the proposed means, with one detailed Now, provisional Next and
  high-level Later.
- [x] Actual model scenarios for both skill projections require architect, JTBD and
  risk assessment before dependent implementation, replan after invalidated
  assumptions or failed verification, and preserve authority when a reviewer is
  unavailable.
- [x] Scenarios stop when the overall objective is verified, discard unnecessary
  speculative work, and require fresh assessments for newly requested work.
- [x] Packed and isolated installed artifacts expose the new skill under the
  correct runtime names without unrelated mandatory hang-off delegation;
  existing skills retain their delegation behavior.
- [x] The stable npm artifact and fresh installation are verified after the
  implementation pipeline and separate cumulative release preparation pass.

## Driving problem trace

P557 records the absent published planning capability and the initial local-only
completion. Deliver the skill through ITIL's established distribution rather
than treating its personal source as publication evidence.

## JTBD trace

JTBD-008 supplies incremental delivery through the existing planning vehicle;
JTBD-005 supplies the architecture, JTBD and risk assessment checkpoints. The skill
composes with each adopter's governing planning and delivery requirements.

## Implementation notes

Reuse `packages/itil/skills/` and the Codex projector. Omit the projector's
capture-specific delegation only for this skill. Add metadata and README
discovery. Exercise the semantic scenarios against both projections, extend
packed installation checks, and qualify from outside the source checkout.
Implementation stays STAGED without a changeset until its exact CI passes;
then prepare the complete cumulative minor release separately.

## Dependencies

- **Blocks**: none.
- **Blocked by**: none; the existing map is ratified and the required reviews
  approve the bounded package and projection scope.

## Related

- Captured via the RFC-row and story workflows on the existing decompose activity.
- Architecture and risk assessments of the current confirmed-outcome plan cover the bounded source scope;
  actual changes and release preparation passed their separate checks.

## Delivery evidence

- Accepted on the ratified map before implementation. Implementation began
  with `d605e6c4` on 2026-10-15; this terminal receipt reconciles its forward
  lifecycle to done after publication and fresh installed verification.
- Published `@windyroad/itil@3.1.0` through PR #528 at `d1f4a081`; exact
  implementation CI, separate cumulative release preparation and publication
  passed. No product changes are introduced by this bookkeeping transition.
- 22 semantic scenarios passed across the canonical and Codex projections,
  including actual sequential interviews and substantive reviewer rejection.
  Nine targeted harness/pack/install checks passed, including preservation of
  existing capture delegation and its omission only for the new skill.
- Fresh native Claude Code and Codex invocations loaded the published installed
  skill, played back the SMART goal and waited for confirmation before planning.
  These smoke trials establish discovery and the initial confirmation gate;
  they do not prove live reviewer dispatch or existing-chat hot-reload.
- [P557](../../problems/closed/557-no-published-skill-supports-outcome-led-iterative-planning.md)
  and [the terminal plan receipt](../../plans/557-outcome-led-planning.md) retain
  publication, artifact integrity, runtime identifiers and evidence boundaries.

## History

- 2026-10-15 - Accepted under the existing ratified STORY-MAP-002 approval.
- 2026-10-15 - Implementation started at `d605e6c4`; delivered in ITIL 3.1.0.
- 2026-10-15 - Reconciled to done on verified publication and installed exercise.
  RFC-106 status is derived from its completed story; no new approval marker.
