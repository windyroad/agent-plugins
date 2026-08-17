# Problem 500: External reporter issues close before reporter confirmation or the promised quiet period

**Status**: Open
**Reported**: 2026-08-17
**Priority**: 16 (High) - Impact: 4 x Likelihood: 4
**Origin**: internal
**Effort**: L
**WSJF**: 4 - (16 x 1.0) / 4
**JTBD**: JTBD-301
**Persona**: plugin-user

## Description

The verification workflow can close an external reporter's GitHub issue as soon as internal session evidence closes the local problem. That contradicts the release comment's promise to close only after reporter confirmation or a 14-day quiet period.

## Symptoms

- A reporter's issue can close before the reporter confirms the fix.
- Internal session evidence can trigger an external lifecycle change without checking the promised quiet period.
- `manage-problem` requires explicit user confirmation, while `run-retro` and `update-upstream` permit silent evidence-based closure.

## Workaround

Do not close a linked external issue unless the reporter has confirmed the fix or the promised quiet period has elapsed. Keep the external issue open when only internal verification evidence exists.

## Impact Assessment

- **Who is affected**: plugin users who report problems through a linked external issue.
- **Frequency**: any externally linked problem closed through the evidence-based verification path.
- **Severity**: High - premature closure breaks the published reporter contract and can suppress unresolved feedback.

## Root Cause Analysis

The local evidence-based close and the external issue close are coupled, but their trust boundaries differ. Local evidence can justify an internal lifecycle transition; it does not establish reporter confirmation or elapsed quiet time.

### Investigation Tasks

- [ ] Reproduce the external close from an evidence-based local verification transition.
- [ ] Identify every inbound-report path that can close a linked external issue.
- [ ] Decide whether local and external closure must be decoupled.
- [ ] Add a behavioural test for reporter confirmation and quiet-period enforcement.
- [ ] Record and ratify a decision superseding ADR-024's relevant closure rule before implementation.

## Dependencies

- **Blocks**: a trustworthy reporter feedback loop.
- **Blocked by**: a ratified decision superseding ADR-024's external closure rule before implementation.
- **Composes with**: P450's separate verification-evidence persistence problem and ADR-044's framework-resolved local lifecycle actions.

## Related

- Pull request [#298](https://github.com/windyroad/agent-plugins/pull/298) carried the stale original capture.
- [P450](../known-error/450-vq-evidence-cells-have-no-write-path-from-subsequent-sessions-drain-starved.md) covers the distinct evidence-producer and drain-starvation defect.
- `packages/retrospective/skills/run-retro/SKILL.md` performs silent evidence-based local closure.
- `packages/itil/skills/update-upstream/SKILL.md` closes the linked external issue when the local problem closes.
- `packages/itil/skills/manage-problem/SKILL.md` still requires explicit user confirmation before closure.
- Architecture review: capture is compliant as a separate problem; implementation requires a new ratified decision superseding ADR-024's relevant rule.
