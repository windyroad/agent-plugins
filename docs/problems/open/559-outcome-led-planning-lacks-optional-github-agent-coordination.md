# Problem 559: Outcome-led planning lacks optional GitHub agent coordination

**Status**: Open
**Reported**: 2026-10-16
**Priority**: 6 (Medium) - Impact: 2 × Likelihood: 3
**Origin**: internal
**Effort**: M
**JTBD**: JTBD-008, JTBD-004, JTBD-003
**Persona**: developer

## Description

The published planning skill confirms outcomes and replans increments, but does not offer GitHub Issues as a shared planning vehicle. Contributors lack a reusable outcome → increment with horizon → task protocol for ownership, overlap checks, shared discussion, dependency handoffs and outcome-owner replanning. The user requested this optional capability and its release. Existing local planning must remain usable.

## Symptoms

The planning entrypoint and its package contain no GitHub coordination protocol. A project-specific adaptation exists, but its project rules are not suitable for copying into the public reusable skill.

## Workaround

Agree on coordination manually or maintain a project-specific skill adaptation.

## Impact Assessment

- **Who is affected**: developers coordinating multiple agents, including agents using different GitHub accounts.
- **Frequency**: recurring when shared outcome work spans sessions or contributors; qualitative estimate, no usage measurement.
- **Severity**: Impact 2, Likelihood 3 reflects avoidable duplicate work and missed handoffs without evidence of service interruption.
- **Effort**: M estimate for conditional guidance, compatibility packaging, behavioral qualification and documentation through existing release tooling.

## Root Cause Analysis

The original published workflow defines iterative planning but leaves the shared tracking and contribution protocol unspecified. This is a capability gap, not an interruption of a previously working service.

### Investigation Tasks

- [x] Confirm the user-requested hierarchy, ownership and cross-agent handoff requirements from prior conversation evidence.
- [x] Verify existing package synchronization and runtime projection can carry a conditional reference.
- [ ] Qualify optional tracking, scoped contributions and replanning through actual behavioral runs.
- [ ] Verify stable registry artifacts, fresh runtime installations and public documentation.

Plan G18 repairs existing planning boundaries exposed by the first actual Claude campaign. Exact G13 CI `38982728285` at `2935c7e1d0642c5f2e7f55f5cb447428bb2ed65f` retains 44 passes, four failures and zero errors. Both missing-JTBD responses improperly proceed on generic go-ahead. A goal playback adds implementation questions and invents an inconsistent date. Independent oracle review finds the fourth row's immediate-planning rationale stronger than its “only after confirmation may” rubric; its unnecessary local tracking question still exposes an existing-default ambiguity. Preserve all failed results and original 48 scenarios/rubrics without rescoring or waiver.

The personal SKILL is clarified first, preserving the pending G16 reference, mode and picker. Canonical/ITIL bodies then synchronize. Clarifications hold dependent implementation for a missing required independent review, preserve stated timing, avoid a design interview during sufficient goal playback, and retain local tracking without evidence of shared coordination value. Existing STORY-108 qualification scope carries this bounded repair; historical P557 completion and broad P459 Known Error remain unchanged. G16's unfinished Codex campaign stopped at exit 130 when trunk failed and receives no qualification credit; its complete source slice remains recoverable. Fresh 48-case Codex and exact-CI Claude qualification are required before restoring later refinements. Patch changesets can combine with the subsequent qualified minor release; no premature stable merge or documentation activation.

G18's fresh Codex campaign retains 47 passes, one failure and zero errors (exit 100). The earlier four boundary cases pass. Independent oracle review confirms that the remaining initial-plan response names inspection targets but explicitly defers discovery's own effort assessment until evidence arrives; its missing qualitative discovery bound fails the existing INVEST requirement. The grader overstates the absence of scope, so no numerical duration or invented estimate is required. G18a clarifies a finite inspection pass, concrete output and stopping condition, with a grounded qualitative effort assessment before execution and later implementation uncertainty kept separate. Preserve the failed execution and every original scenario/rubric. Fresh complete qualification remains required.

## Dependencies

- **Blocks**: shared optional GitHub planning capability.
- **Blocked by**: none; normal repository review and delivery gates apply.
- **Composes with**: independently installed planning reviewers.

## Related

- P557 / RFC-106 / STORY-106 delivered the original planning capability; preserve their historical completion.
- Capture duplicate check used title keywords outcome, GitHub and coordination. No matching open capability ticket was found.
- Fresh-context hang-off review returned PROCEED_NEW: P070, P207, P220 and P413 share JTBD-004 but concern upstream reporting, labels or polling rather than outcome planning.
- Plan G3: optional GitHub reference, local skill first, standalone/compatibility synchronization, explicit Codex subject/grader, substantive behavior and package checks, stable release, then public documentation activation. Architecture, JTBD and plan risk PASS; forecast residual 4/25. Concrete pipeline assessments remain required.
## RFCs

- RFC-108: Coordinate shared outcomes with optional GitHub Issues, release row on [the developer journey](../../story-maps/draft/STORY-MAP-002-take-a-problem-from-noticed-to-resolved.html), with STORY-108.


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-108 | STORY-108: Coordinate shared outcomes with optional GitHub Issues | in-progress |
