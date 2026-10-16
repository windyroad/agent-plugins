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

## Dependencies

- **Blocks**: shared optional GitHub planning capability.
- **Blocked by**: none; normal repository review and delivery gates apply.
- **Composes with**: independently installed planning reviewers.

## Related

- P557 / RFC-106 / STORY-106 delivered the original planning capability; preserve their historical completion.
- Capture duplicate check used title keywords outcome, GitHub and coordination. No matching open capability ticket was found.
- Fresh-context hang-off review returned PROCEED_NEW: P070, P207, P220 and P413 share JTBD-004 but concern upstream reporting, labels or polling rather than outcome planning.
- Plan G2: optional GitHub reference, local skill first, standalone/compatibility synchronization, substantive behavior and package checks, stable release, then public documentation activation. Architecture, JTBD and plan risk PASS; forecast residual 4/25. Concrete pipeline assessments remain required.
