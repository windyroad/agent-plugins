# P554: Commit-time changeset enforcement forces premature release metadata

**Status**: Known Error
**Reported**: 2026-09-28
**Severity**: 20 (Very High)
**Priority**: 20 (Very High) — Impact: 4 × Likelihood: 5 — the installed hook blocks ordinary implementation commits whenever package source changes without release metadata
**Origin**: internal
**Effort**: M — retire the hook and align its direct workflow, documentation, manifest, and behavioural-test consumers
**JTBD**: JTBD-001
**Persona**: developer

## Description

The installed ITIL commit hook refuses an ordinary implementation commit when package source is staged without a changeset. That inverts the release boundary: release metadata becomes a prerequisite for integrating implementation rather than a later, intentional release-preparation step.

The failure is reproducible in an adopter repository whose package path is unrelated to Windy Road. The hook classifies the staged package-shaped path as release work and denies the commit even though the implementation is only being integrated as `STAGED`.

## Root Cause

`itil-changeset-discipline.sh` applies a commit-time changeset requirement to staged package-source paths. Its classifier cannot know whether a commit is intentionally preparing a release, so it treats implementation integration as release preparation.

Narrowing the classifier would preserve the same incorrect timing rule and move the false positive. The root-cause repair is to retire the commit-time hook and retain changeset enforcement at the intentional release boundary.

## Known Error and Workaround

The reliable workaround is to disable the installed commit-time changeset hook for the implementation commit, then create one complete cumulative changeset only when intentionally preparing the release. Do not create placeholder or speculative changesets to satisfy the hook.

Reproduction is retained in `packages/itil/hooks/test/itil-changeset-discipline.bats`; the repair replaces that deny-oriented contract with registered-hook behavioural coverage proving commits without release metadata are permitted.

## Governing Decisions

- ADR-390 — create release changesets only at intentional release preparation.
- ADR-391 — cover every selected package's cumulative unreleased changes.
- ADR-392 — determine baselines from successful publish history.
- ADR-393 — revalidate release scope without locking main.

## Investigation Tasks

- [x] Reproduce the installed commit denial with staged package source and no changeset.
- [x] Confirm the governing release decision with the Voder General Manager.
- [x] Rule out narrowing the package classifier as a root-cause repair.
- [ ] Retire the hook and its direct consumers.
- [ ] Verify ordinary implementation commits pass while the release boundary still requires complete cumulative metadata.

## RFCs

- RFC-103 — Release metadata starts at intentional preparation (STORY-MAP-008)

## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-102 | STORY-102: Commit implementation before preparing its release metadata | accepted |

## History

- 2026-09-28 — Captured after the installed commit hook blocked an ordinary implementation commit in an adopter repository.
- 2026-09-28 — Transitioned to Known Error after reproducing the denial and identifying the release-boundary inversion.
- 2026-09-28 — Fresh-context hang-off arbitration returned `PROCEED_NEW`: P173 concerns bypass-message accuracy, P177 held changesets, P268 README-hook command detection, and P272 changeset-hook command detection; none covers release-metadata timing.
