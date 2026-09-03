---
status: accepted
story-id: merge-guard-distinguishes-the-release-pr-from-an-ordinary-one
reported: 2026-09-03
decision-makers: [Tom Howard]
problems: [P435]
jtbd: [JTBD-012]
rfcs: [RFC-062]
story-maps: [STORY-MAP-008]
estimated-effort: S
---

# STORY-084: Land an ordinary pull request without running a release

**Reported**: 2026-09-03
**Problems**: P435
**JTBD**: JTBD-012
**RFCs**: RFC-062
**Story Maps**: STORY-MAP-008
**Estimated effort**: S

## User value (required, INVEST Valuable)

In order to merge a green pull request that has nothing to do with publishing — so that a
finished branch can land instead of sitting behind a guard built for something else — as a
developer whose branch is reviewed and passing, I want the merge guard to recognise that my
branch is not the release branch, so it stands between me and the release pull request and
nowhere else.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] Merging the changesets release pull request is still denied, and still names
  `npm run release:watch` as the way to do it.
- [ ] Merging a pull request whose head is an ordinary feature or worktree branch is allowed.
- [ ] The no-argument shape — merging the branch you are standing on — resolves that branch's
  pull request rather than falling to a denial. This is the shape that produced the report.
- [ ] A branch whose name merely begins like the release branch is not swept into the denial.
- [ ] When the head branch cannot be determined at all, the guard denies, falling through to
  the existing denial text rather than emitting new prose.
- [ ] The branch lookup is bounded by `timeout 10s` guarded by `command -v timeout`, and its
  exit status is captured so `set -euo pipefail` cannot pre-empt the fail-closed path.
- [ ] Behavioural bats in `packages/risk-scorer/hooks/test/git-push-gate.bats` cover all five
  cases above against a stubbed `gh` on PATH, and the three pre-existing denial cases still
  assert their existing strings.
- [ ] The stale comment in `packages/itil/hooks/pre-publish-intake-gate.sh` asserting that
  `git-push-gate` denies all `gh pr merge` is corrected in the same change.
- [ ] A `.changeset/*.md` bumps `@windyroad/risk-scorer` — the gate's behaviour changes for
  every adopter.

## Driving problem trace (required — I7 invariant)

- **P435** — the risk-scorer gates are hardcoded to the home-repo shape, and the push-gate
  half over-fires. The blanket `gh pr merge` denial is that over-fire in its sharpest form:
  a session finished a feature branch, got it green, and had no way to land it, because the
  guard named a release command as the way out of a merge that was not a release.

## JTBD trace (accepted-gate — I8 invariant)

Serves JTBD-012 (know what my push did without leaving the terminal). Its outcome "branches
the pipeline owns are not something I have to remember not to touch" is the only grounding
this denial has, and that outcome is scoped to pipeline-owned branches. Denying a merge the
pipeline does not own is outside what the job authorises. Secondary JTBD-003 — a guardrail
that blocks work it was never meant to govern is the composability friction the `developer`
persona is documented as intolerant of.
