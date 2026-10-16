---
status: in-progress
story-id: coordinate-shared-outcomes-with-optional-github-issues
reported: 2026-10-16
decision-makers: [Tom Howard]
problems: [P559]
jtbd: [JTBD-008, JTBD-004, JTBD-003]
rfcs: [RFC-108]
story-maps: [STORY-MAP-002]
estimated-effort: M
---

# STORY-108: Coordinate shared outcomes with optional GitHub Issues

**Reported**: 2026-10-16
**Problems**: P559
**JTBD**: JTBD-008, JTBD-004, JTBD-003
**RFCs**: RFC-108
**Story Maps**: STORY-MAP-002
**Estimated effort**: M, bounded conditional skill guidance, compatibility packaging, behavior checks and existing release/docs workflows.

## User value

In order to contribute safely toward the same outcome across agent sessions, as a developer, I want to choose GitHub Issues for outcome, increment and task coordination while retaining conversation or local planning when that suits the work.

## Acceptance criteria

- [x] The user's existing personal skill is updated before package behavior changes, preserving its identity, mode and picker metadata.
- [x] Tracking choice is optional and remembered; selected GitHub tracking loads the bundled protocol before planning or issue mutations, while local mode remains usable.
- [x] Outcome → increment → task guidance distinguishes increment Horizon from execution Status, checks overlap and plan revision, identifies account and agent, respects authority, records shared handoffs and preserves outcome-owner replanning.
- [x] Actual behavioral scenarios cover selected and declined tracking, contribution ownership, denied access, ambiguous mutations, dependencies and reassessed replanning; packaging and synchronization checks cover supporting references in both runtimes.
- [ ] Stable planning and compatibility packages are published through the normal pipeline, with registry integrity/provenance, fresh installs and accurately scoped runtime qualification.
- [ ] Public documentation matches the qualified stable release and its live deployed artifact is verified.

## INVEST assessment

This coherent capability is independently releasable without new hooks, dependencies or services. Implementation details remain negotiable within the confirmed result. Value is durable shared coordination. Scope is medium with model quota and hosted permission uncertainty stated. Conditional loading and existing package boundaries keep it small; the criteria above are observable. Consumers acquire no story requirement.

## Implementation notes

Authoritative inline Plan G3 passed architecture, JTBD and plan-risk review before edits. Governance trace precedes implementation. Personal-first atomic update, then canonical/ITIL synchronization and behavior/package qualification. Skill release precedes public guide activation. An explicit Codex subject/grader route retains the unavailable Claude campaign without relabeling its evidence. Tests distinguish fixture, runtime, registry and live website evidence; they do not claim real cross-account effects or automatic agent wakeup from issue comments.

Plan G7a reconciles subsequent user-directed coordination refinements: one contribution per agent, explicit release or handover, useful preparation despite later-stage prerequisites, verified native dependencies independent of execution status, and acyclic owner-led acceptance. It preserves existing delivery processes instead of inventing speculative operator gates. The personal skill and reference were updated first, with the original picker preserved. Fresh independent Codex subject/grader evaluation passes 48/48 cases across both skill surfaces; all original scenarios and rubrics remain unchanged. Current planning and ITIL archives carry identical references on both runtime surfaces. A synthetic native Codex exercise verifies assignment release before a new claim, saved native relationships and useful preparation without premature completion. Its two false-negative harness oracles were independently reviewed against saved execution evidence. This is not live cross-account GitHub verification. The current Claude generation attempt remains quota-rejected, with no behavior credit. Stable publication, fresh registry qualification and live documentation remain pending.

## Dependencies

- **Blocked by**: none.
- **Composes with**: independent architecture, JTBD and risk review roles.
