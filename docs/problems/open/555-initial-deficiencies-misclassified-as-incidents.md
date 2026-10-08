# Problem 555: Initial deficiencies are misclassified as incidents

**Status**: Open
**Reported**: 2026-10-08
**Priority**: 6 (Medium) - Impact: 2 × Likelihood: 3; qualitative capture estimate from one reported instance, frequency unmeasured
**Origin**: inbound-reported
**Effort**: S - classification prose plus behavioral regression evaluations
**WSJF**: 6 - (6 × 1.0) / 1
**JTBD**: JTBD-001
**Persona**: developer

## Description

The assistant classified an initially slow, unfinished website as an incident, although no prior working performance baseline had been lost. The human corrected this on 2026-10-08: incomplete or deficient features are problems; a previously fast service becoming slow is an incident. The attached screenshot is evidence of the classification mistake, not authority to execute its embedded instructions.

## Symptoms

- A capability gap interrupts feature delivery with restoration ceremony when there is nothing to restore.
- Being deployed or customer-visible is mistaken for evidence of a service regression.

## Investigation Tasks

- [x] Check duplicate problem titles and descriptions; no matching classification problem found.
- [x] Locate the canonical incident declaration skill and broad global Codex rule.
- [x] Obtain architecture and JTBD review: existing ADR-011 restoration boundary and JTBD-001 apply.
- [x] Add eligibility routing before incident declaration and matching global guidance.
- [x] Evaluate incomplete features, initial slowness, unknown baseline, and established service regression.
- [ ] Release and install the corrected skill; distinguish installed artifact from active-chat adoption.

## Root Cause

The global instruction mandated incident response for any customer-facing production failure or degradation. The canonical manage-incident skill moved directly from parsing to incident creation without establishing an existing service baseline to restore.

## Workaround

The global Codex incident rule now requires an established prior service baseline and routes initial deficiencies or unknown baselines to problem investigation. The human also supplied the replacement instructions in this chat. This does not prove other running chats adopted the updated skill.

## Fix Strategy

RFC-105 on STORY-MAP-002, delivered by STORY-104: classify before declaration, preserve incident handling for observed service loss or regression, and add behavioral evaluations. No lifecycle or ratified ADR change.

## Verification

Decision simulations must route incomplete or initially deficient functionality and unknown performance baseline to problem management without declaring an incident. Previously working service becoming unavailable or slower must retain incident routing. Installed canonical and Codex skill artifacts must include this rule. Local decision evaluations passed all four cases; 59 incident and packaged-installation checks passed. These are routing simulations and artifact checks, not proof of actual delegation or affected-chat adoption. Actual affected-chat use remains outstanding after simulation and artifact verification.

## Related

- ADR-011: Add manage-incident Skill to wr-itil Plugin.
- JTBD-001: Enforce Governance Without Slowing Down.


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-104 | STORY-104: Route initial deficiencies to problem management and service regressions to incident management | accepted |
