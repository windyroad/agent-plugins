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

- [ ] The user's existing personal skill is updated before package behavior changes, preserving its identity, mode and picker metadata.
- [ ] Tracking choice is optional and remembered; selected GitHub tracking loads the bundled protocol before planning or issue mutations, while local mode remains usable.
- [ ] Outcome → increment → task guidance distinguishes increment Horizon from execution Status, checks overlap and plan revision, identifies account and agent, respects authority, records shared handoffs and preserves outcome-owner replanning.
- [ ] Actual behavioral scenarios cover selected and declined tracking, contribution ownership, denied access, ambiguous mutations, dependencies and reassessed replanning; packaging and synchronization checks cover supporting references in both runtimes.
- [ ] Stable planning and compatibility packages are published through the normal pipeline, with registry integrity/provenance, fresh installs and accurately scoped runtime qualification.
- [ ] Public documentation matches the qualified stable release and its live deployed artifact is verified.

## INVEST assessment

This coherent capability is independently releasable without new hooks, dependencies or services. Implementation details remain negotiable within the confirmed result. Value is durable shared coordination. Scope is medium with model quota and hosted permission uncertainty stated. Conditional loading and existing package boundaries keep it small; the criteria above are observable. Consumers acquire no story requirement.

## Implementation notes

Authoritative inline Plan G3 passed architecture, JTBD and plan-risk review before edits. Governance trace precedes implementation. Personal-first atomic update, then canonical/ITIL synchronization and behavior/package qualification. Skill release precedes public guide activation. An explicit Codex subject/grader route retains the unavailable Claude campaign without relabeling its evidence. Tests distinguish fixture, runtime, registry and live website evidence; they do not claim real cross-account effects or automatic agent wakeup from issue comments.

## Dependencies

- **Blocked by**: none.
- **Composes with**: independent architecture, JTBD and risk review roles.
