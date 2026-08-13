# Problem 497: An upstream pull-request diff is not scored against the upstream's conventions

**Status**: Open
**Reported**: 2026-08-14
**Priority**: 9 (Medium) - Impact: 3 x Likelihood: 3
**Origin**: internal
**Effort**: L
**WSJF**: 2.25 - (9 x 1.0) / 4
**JTBD**: JTBD-001, JTBD-010
**Persona**: developer

## Description

ADR-117 makes a pull request the preferred upstream report when a defensible fix is available. The skill explicitly sends its title and body through the external-communications evaluators, while the command hook enforces the body review. No scorer evaluates the diff against the upstream repository's contribution policy, conventions, or risk appetite.

## Symptoms

- A contribution can be opened after prose review without policy-aware diff review.
- The local pipeline scorer applies this repository's policy, not the upstream's.
- There is no assessment action for a contribution to a repository the user does not own.

## Workaround

In interactive sessions, display and review the full diff and the upstream's `CONTRIBUTING.md`, pull-request template, lint configuration, and CI workflow before `gh pr create`. ADR-117 forbids AFK sessions from opening the pull request.

## Impact Assessment

- **Who is affected**: upstream maintainers, the contributor's reputation, and downstream adopters of the proposed change.
- **Frequency**: every interactive pull request opened through ADR-117.
- **Severity**: Medium - the likely harm is a rejected or regretted contribution rather than a local package regression.

## Root Cause Analysis

The risk model assumes that diffs land in the current repository and can be judged against its local `RISK-POLICY.md`. A contribution crosses that boundary without an equivalent machine-readable upstream policy.

### Investigation Tasks

- [ ] Decide whether contribution review needs a new scorer action or a mode on the existing pipeline scorer.
- [ ] Determine which upstream convention files are reliable inputs.
- [ ] Define appetite for a repository the user does not own.
- [ ] Use evidence from the first real ADR-117 contribution before selecting the mechanism.

## Dependencies

- **Blocks**: none; ADR-117 requires human diff review and forbids AFK publication.
- **Blocked by**: evidence from a real upstream contribution.
- **Composes with**: ADR-015, ADR-028, ADR-117, and `RISK-POLICY.md`.

## Related

- [ADR-117](../../decisions/117-prefer-an-upstream-pull-request-over-an-issue.proposed.md)
- GitHub issue [#416](https://github.com/windyroad/agent-plugins/issues/416) tracks the original observation.
