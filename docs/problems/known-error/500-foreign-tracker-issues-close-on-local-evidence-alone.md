# Problem 500: Foreign tracker issues close on local evidence alone

**Status**: Known Error
**Reported**: 2026-08-17
**Priority**: 16 (High) - Impact: 4 x Likelihood: 4
**Origin**: internal
**Effort**: L
**WSJF**: 8 — (16 × 2.0) / 4 (2026-08-21 review: auto-transitioned Open → Known Error — root cause confirmed + workaround documented; Known Error multiplier 2.0)
**JTBD**: JTBD-301
**Persona**: plugin-user

## Description

The verification workflow can close an issue on another maintainer's tracker as soon as local session evidence closes the local problem. Local evidence establishes our state, not theirs.

## Symptoms

- A foreign issue can close on evidence observed only in this project.
- The other tracker's maintainer has not confirmed closure.
- Pull-request and issue authority can be conflated even though both are foreign tracker state.

## Workaround

Post the lifecycle comment but leave a foreign issue open when only local evidence exists. The upstream party's confirmation may authorize closure. Pull requests remain comment-only.

## Impact Assessment

- **Who is affected**: maintainers of repositories where this project filed an issue or pull request.
- **Frequency**: any foreign issue linked to an evidence-backed local close.
- **Severity**: High - premature closure writes our decision into another maintainer's tracker.

## Root Cause Analysis

The local evidence-based close and foreign issue close were coupled even though their authority boundaries differ. Local evidence can justify our lifecycle transition; only the upstream party's confirmation can supply the missing authority to close their issue.

### Investigation Tasks

- [x] Reproduce the foreign close from an evidence-based local verification transition.
- [x] Identify the outbound issue and pull-request close paths.
- [x] Ratify the authority boundary: local evidence comments but does not close a foreign issue; upstream confirmation may authorize issue closure; pull requests remain comment-only.
- [x] Add behavioural coverage for evidence-only, target-bound upstream-confirmed, and pull-request targets.

## Dependencies

- **Blocks**: a trustworthy reporter feedback loop.
- **Blocked by**: (none)
- **Composes with**: P450's separate verification-evidence persistence problem and ADR-044's framework-resolved local lifecycle actions.

## Related

- Pull request [#298](https://github.com/windyroad/agent-plugins/pull/298) carried the stale original capture.
- [P450](../known-error/450-vq-evidence-cells-have-no-write-path-from-subsequent-sessions-drain-starved.md) covers the distinct evidence-producer and drain-starvation defect.
- `packages/retrospective/skills/run-retro/SKILL.md` performs silent evidence-based local closure.
- `packages/itil/skills/update-upstream/SKILL.md` comments on foreign issues by default and closes only after target-bound upstream-party confirmation.
- `packages/itil/skills/manage-problem/SKILL.md` permits evidence-backed local closure while preserving the foreign-tracker authority boundary.
- ADR-121 records the ratified tracker-ownership and provenance rule.
