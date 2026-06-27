# Problem 394: Release publishes a new version of every package, not just the ones that changed

**Status**: Open
**Reported**: 2026-06-28
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-002
**Persona**: plugin-developer

## Description

When we cut a release, it appears that a new version of **every** `@windyroad/*` package gets published — not just the packages whose source actually changed in the release. The expectation is that changesets only bumps + publishes the packages named in the `.changeset/*.md` entries (and the genuinely-affected dependents); instead the version PR seems to bump the whole suite, flooding the adopter-facing version stream with no-op bumps and obscuring which package actually changed.

## Symptoms

- A release whose changesets name a single package (e.g. `@windyroad/itil` patch) ships a version PR / npm publish that bumps multiple — possibly all 13 — `@windyroad/*` packages.
- Adopters tracking specific packages see version churn with no corresponding source change.
- (To confirm at investigation: capture one release's version-PR diff and count which `package.json` versions bumped vs which packages had source changes in the same release window.)

## Workaround

(deferred to investigation)

## Impact Assessment

- **Who is affected**: plugin-developer (release hygiene) + adopters consuming `@windyroad/*` (noise in the update stream); JTBD-002 ship-with-confidence + JTBD-007 keep-plugins-current.
- **Frequency**: every release that carries internal-dependency-graph propagation (deferred — confirm).
- **Severity**: no functional break — packages still publish working versions — but version-stream noise + audit-trail dilution (can't tell what changed from the version bumps alone).
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

**Leading hypothesis (not yet confirmed — recorded at capture):** `.changeset/config.json` sets `"updateInternalDependencies": "patch"` with `"fixed": []` and `"linked": []`. So it is NOT a forced lockstep (`fixed`/`linked` would bump a named group together) — the cascade is **internal-dependency propagation**: changesets patch-bumps every package that internally depends (via `workspace:*` / `dependencies` / `peerDependencies`) on a package named in a changeset. With 13 inter-dependent `@windyroad/*` packages (several plausibly depending on a shared package such as `@windyroad/shared`, or on each other), a single-package changeset fans out a patch bump to its entire dependent closure — which can be most/all of the suite.

Candidate investigation directions (deferred):
- Confirm the symptom empirically: pick a recent release, diff the version PR, list bumped packages vs source-changed packages.
- Map the internal `@windyroad/*` dependency graph (who `dependencies`/`peerDependencies` whom) to see the propagation closure.
- Decide the desired contract: is cascading dependent bumps actually CORRECT (a dependent that pins `^x.y.z` of a changed dep should re-publish so adopters get the matching pair), or is it over-eager? `updateInternalDependencies: "patch"` vs `"minor"` vs removing internal deps / using a bundler (see P304) all change the blast radius.
- Cross-check P042 (changesets manifest-version sync) and P359 (held code ships with sibling release) — sibling release-mechanics tickets.

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Confirm the symptom from a real release's version-PR diff (bumped vs source-changed packages)
- [ ] Map the `@windyroad/*` internal dependency graph + the changesets propagation closure
- [ ] Decide desired contract (cascade-is-correct vs over-eager) and the `updateInternalDependencies` / dependency-shape remedy
- [ ] Create reproduction test

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P042 (changeset/manifest version sync), P304 (packages/shared duplicate-and-sync → bundler), P359 (held changeset ships with sibling release)

## Related

- `.changeset/config.json` — `updateInternalDependencies: "patch"`, `fixed: []`, `linked: []` (the configuration governing cross-package bump propagation).
- **P304** (`docs/problems/open/304-...`) — `packages/shared` duplicate-and-sync vs bundler approach; the shared-package shape is plausibly the propagation hub.
- **P042** / **P359** — sibling release-mechanics tickets (manifest-version sync; held-code-ships-with-sibling).
- (captured via /wr-itil:capture-problem; expand at next investigation)
