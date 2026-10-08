# Problem 555: Initial deficiencies are misclassified as incidents

**Status**: Verification Pending
**Reported**: 2026-10-08
**Priority**: 6 (Medium) - Impact: 2 × Likelihood: 3; qualitative capture estimate from one reported instance, frequency unmeasured
**Origin**: inbound-reported
**Effort**: S - classification prose plus behavioral regression evaluations
**WSJF**: 0 - (6 × 0.0) / 1; released fix awaiting affected-chat verification
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
- [x] Release and install the corrected skill; distinguish installed artifact from active-chat adoption.

## Root Cause Analysis

The canonical manage-incident skill moved directly from parsing to incident creation without establishing an existing service baseline to restore. A global instruction also mandated incident response for any customer-facing production failure or degradation. These are confirmed contract gaps; the affected chat's exact loaded instruction path has not been established.

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
| STORY-104 | STORY-104: Route initial deficiencies to problem management and service regressions to incident management | done |

## Reproduction evidence

The human screenshot records an incident declaration for initial slowness in an unfinished website, without evidence of a previous performance baseline. The four eligibility decision evaluations cover that boundary and its counterexamples. Standalone old-skill simulations chose the correct workflows; they did not reproduce a deterministic failing baseline. The observed screenshot failure and missing contract are the repair evidence.

## Fix Released

**Released**: 2026-10-08
**Version**: @windyroad/itil 3.0.1
**Implementation**: 4db9ddba
**Release preparation**: f2ac589a
**Release merge**: e35ab02f0131a6ff00d190142747c07e9a507251 (PR526)

- Implementation CI37733511252, preparation CI37734674013, release PR CI37734776162 and final merge CI37736254156 passed Quality Gates and Agent-Prose Behavioural Evals. The new eligibility step ran and passed four cases in implementation CI.
- Release37736254238 succeeded; npm latest is 3.0.1.
- Supported installers updated Codex plus the existing Claude user and primary-project registrations to enabled 3.0.1. Codex canonical and generated incident skills match the published tarball; the Claude incident skill matches reviewed release source.
- Local routing evaluations passed 4/4; the scoped incident and packaged-installation suite passed 59/59. These establish decision and artifact behavior, not affected-chat recovery.
- Actual use of the corrected eligibility boundary in the affected running chat remains unverified. No restart or other-chat message was requested.
