---
status: done
story-id: commit-implementation-before-preparing-release-metadata
reported: 2026-09-28
decision-makers: [Tom Howard]
problems: [P554]
jtbd: [JTBD-001]
rfcs: [RFC-103]
story-maps: [STORY-MAP-008]
estimated-effort: M
---

# STORY-102: Commit implementation before preparing its release metadata

**Reported**: 2026-09-28
**Problems**: P554
**JTBD**: JTBD-001 (Enforce Governance Without Slowing Down)
**RFCs**: RFC-103
**Story Maps**: STORY-MAP-008 (Have a plugin behave like a guest in my repository), activity `collide`
**Estimated effort**: M — retire one installed commit gate and align its direct workflow, documentation, manifest, generated, and behavioural-test consumers

## User value (required, INVEST Valuable)

In order to integrate reviewed, tested implementation without inventing release metadata before its cumulative release scope is known, as a developer using an installed governance plugin, I want ordinary implementation commits to proceed without a changeset, while the release boundary still requires one complete changeset when I intentionally prepare the release.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [x] With Windy Road package source staged and no changeset, an actual `git commit` PreToolUse payload sent through every registered ITIL Bash hook receives no changeset-related denial.
- [x] The same composite registered-hook test permits an adopter-shaped `packages/core/src/push-and-watch.test.ts` implementation commit without a changeset.
- [x] When implementation is ready to integrate but its exact pipeline is not yet green, the problem-work workflow commits and runs `push:watch` without creating a changeset or running `release:watch`.
- [x] After exact implementation CI is green and release is intentionally requested, the workflow inspects cumulative package scope, authors one complete changeset-only commit, refreshes cumulative risk evidence, runs `push:watch`, and then runs `release:watch`.
- [x] Dormant, incomplete, placeholder, or speculative implementation creates no release metadata.
- [x] Existing `release:watch` behavior still refuses when no release pull request exists.
- [x] The obsolete commit-time hook, helper, registration, manifest entry, and deny-oriented test contract are absent from shipped plugin surfaces.

## Driving problem trace (required — I6 invariant)

P554 identifies the release-boundary inversion: the installed hook treats release metadata as an implementation-commit prerequisite, so it blocks the small governed integrations the release process is meant to enable.

## JTBD trace (required — I9 invariant)

JTBD-001 requires governance to protect delivery without turning routine work into avoidable ceremony. Retiring the commit-time changeset gate removes a premature block while preserving complete metadata and verification at the intentional release boundary.

## Implementation notes (optional)

Retire the commit gate rather than narrowing its package classifier or replacing it with another adopter-wide hook. Reuse the existing release boundary; do not add a generic package-diff inference engine.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: story-map ratification

## Related

- P141 — original commit-time changeset-discipline hook
- ADR-390 through ADR-393 — intentional release preparation, cumulative scope, publish baselines, and scope revalidation
