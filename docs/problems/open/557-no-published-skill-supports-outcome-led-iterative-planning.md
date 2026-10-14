# Problem 557: No published skill supports outcome-led iterative planning

**Status**: Open
**Reported**: 2026-10-15
**Priority**: 10 (High) - Impact 2 × Likelihood 5. The development workflow cannot be reused through the published plugin because the capability is absent from its package.
**Origin**: internal
**Effort**: M - reuse the ITIL distribution path, qualify both skill projections, then publish and verify installation.
**WSJF**: 5 - (10 × Open multiplier 1.0) / 2
**JTBD**: JTBD-008, JTBD-005
**Persona**: developer

## Description

Developers want an agent to keep a clear result objective, execute one detailed
Now release increment, retain provisional Next increments and high-level Later
direction, then verify, learn, replan and obtain architecture and risk assessment
of each revised plan until the objective is achieved.

The reusable contract was created and tested as a personal skill. Reporting that
local artifact as the completed delivery omitted the expected repository,
publication and installed-plugin stages. The published ITIL package does not
contain the capability, so other installations cannot discover or invoke it.

## Symptoms

- The planning workflow must be re-explained in individual chats.
- A local skill passes format and scenario checks but is absent from npm.
- Local creation is mistaken for completion of the expected plugin delivery.

## Workaround

Provide the objective and Now/Next/Later cycle explicitly in a chat, or use the
maintainer's local skill while publication is completed. This does not provide
the capability to other plugin installations.

## Impact Assessment

- **Who is affected**: developers seeking reusable, adaptive delivery planning.
- **Frequency**: every installation of the current package lacks this skill;
  demand beyond the observed request has not been measured.
- **Severity**: development-workflow capability gap; no prior service regression,
  data loss or credential exposure observed.
- **Analytics**: one directly observed delivery request and correction.

## Root Cause Analysis

The initial delivery selected a personal skill directory as its endpoint rather
than completing the repository's established plugin distribution workflow.
There is no canonical ITIL skill source or release vehicle for this capability.
The Codex projector also adds a capture-specific delegation instruction to every
skill, which must not be introduced into the new planning contract.

### Investigation Tasks

- [x] Identify the missing published surface and compare local and package scope.
- [x] Confirm ITIL ownership and the existing ratified story-map journey.
- [x] Capture the problem-traced release row and delivery story before implementation.
- [ ] Qualify canonical and generated behavior, packing and isolated installation.
- [ ] Verify publication and the installed skill from the exact released artifact.

## Close criteria

The stable npm package contains the canonical and Codex skill projections;
fresh installation exposes the new invocation; behavioral trials exercise the
planning/replanning and completion boundaries without unrelated delegation.
Local checks, implementation CI, publication and installed exercise must be
reported as distinct evidence.

## Dependencies

- **Blocks**: reusable plugin distribution of outcome-led planning.
- **Blocked by**: required release-row/story capture and qualification.
- **Composes with**: P554's implementation-first, release-preparation-later boundary.

## Related

- JTBD-008 (Decompose a Fix Into Coordinated Changes).
- JTBD-005 (Invoke Governance Assessments On Demand).
- Captured through the ITIL problem flow. Title and path searches found no
  existing ticket covering this absent skill; general skill-testing and
  story-map-rendering tickets describe different capabilities.

## RFCs

- RFC-106: Plan toward a verified outcome, on [the existing developer journey](../../story-maps/draft/STORY-MAP-002-take-a-problem-from-noticed-to-resolved.html).


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-106 | STORY-106: Keep my objective clear while I deliver, learn and replan | accepted |
