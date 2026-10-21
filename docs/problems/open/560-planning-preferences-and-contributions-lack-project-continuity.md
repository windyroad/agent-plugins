# Problem 560: Planning preferences and contributions lack project continuity

**Status**: Open
**Reported**: 2026-10-21
**Priority**: 6 (Medium) - Impact: 2 × Likelihood: 3
**Origin**: internal
**Effort**: M
**WSJF**: 3.0 - (6 × 1.0) / 2
**JTBD**: JTBD-001, JTBD-003, JTBD-004, JTBD-008, JTBD-101
**Persona**: developer

## Description

The published planning skill supports optional GitHub tracking but records its choice only with the current plan. It has no shared project configuration contract for future sessions or a reusable contribute entrypoint. The user requested both skills reuse one saved GitHub Issues or local choice instead of repeatedly asking. They also require planners to leave risk treatments to the risk scorer and expose useful task opportunities for other contributors rather than reserving all work.

## Symptoms

A new session has no canonical project preference to read. A contribution adaptation exists outside the published package, and the generic planning brief does not explicitly require contribution opportunities or prohibit speculative mitigation tasks.

## Workaround

State the tracking choice and contribution rules in each session or maintain project-specific guidance.

## Impact Assessment

- **Who is affected**: developers and agents continuing the same project across sessions.
- **Frequency**: recurring at new sessions and contribution handoffs; qualitative estimate rather than measured usage.
- **Severity**: Impact 2 and Likelihood 3 reflect avoidable repeated decisions, duplicate work and speculative work; no service outage is established.
- **Effort**: Medium for one shared configuration contract, bounded skill extraction, runtime packaging, behavior qualification and existing release/docs workflows.

## Root Cause Analysis

Tracking choice is presently scoped to a plan/session rather than declarative project configuration. The published package exposes planning only; the independent contribution workflow and current task-allocation rules have not been generalized into it. This is a capability gap, not a regression of an established persistent backend.

### Investigation Tasks

- [x] Inspect the current published skill and supplied project adaptation without copying project identities or settings.
- [x] Confirm the shared reference and runtime packaging boundary with independent architecture, JTBD and risk review.
- [ ] Verify one-time choice, saved reuse, explicit changes and preservation of unrelated configuration across actual fresh sessions and both skills.
- [ ] Verify contribution opportunities, current Now ownership and absence of speculative mitigation tasks through behavioral cases.
- [ ] Publish qualified packages and verify fresh installs, discovery, native behavior and public documentation.

## Acceptance criteria

- [ ] Ask one tracking question when unset, wait, save and verify the answer in project configuration; reuse either saved backend across sessions and both skills.
- [ ] Preserve existing settings and explicit user changes. Local mode requires no GitHub setup. Configuration grants no access or operational authority.
- [ ] Publish independently invokable planning and contribute skills while preserving the existing personal planning installation and ITIL planning compatibility.
- [ ] Planning MUST NOT add speculative risk-mitigation tasks. The risk scorer identifies necessary controls from the applicable risk policy and register; explicit user constraints, mandatory checks and concrete observed risks remain respected.
- [ ] Planning considers bounded tasks within Now and exposes useful contribution opportunities without claiming every task, taking others' work or inventing availability, delegation or messaging authority.
- [ ] Documentation and verified released behavior match, including actual persistence, installation and discovery evidence.

## Dependencies

- **Blocked by**: none; normal repository reviews and delivery gates apply.
- **Blocks**: reusable project-persistent planning and contributions.
- **Composes with**: independently available architecture, JTBD and risk reviewers.

## RFCs

- RFC-110: Remember project tracking choices and share increment work (STORY-110 on STORY-MAP-002).

## Related

- P559 delivered original optional GitHub coordination; preserve its completed scope.
- Fresh-context hang-off review returned PROCEED_NEW because the completed original planning tickets contain no deferred project-persistence or separate contribution entrypoint scope.
- Confirmed user deadline: by lunchtime on 2026-10-21, Australia/Sydney. This record makes no publication or runtime-verification claim before those stages complete.


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-110 | STORY-110: Remember project tracking choices and share increment work | accepted |
