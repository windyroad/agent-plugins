# Problem 325: CI actions pin Node-20 versions (`checkout@v4`, `setup-node@v4`) — GitHub deprecates Node 20 on runners; bump before the forced 2026-06 migration

**Status**: Open
**Reported**: 2026-05-28
**Priority**: 4 (Low-Med) — Impact: 2 x Likelihood: 2 (deferred — re-rate at next /wr-itil:review-problems; time-bounded, see below)
**Effort**: S (deferred — re-rate at next /wr-itil:review-problems)
**Type**: technical

## Description

The CI workflows pin `actions/checkout@v4` and `actions/setup-node@v4`, which run on **Node 20**. GitHub is deprecating Node 20 on Actions runners:

- **2026-06-02**: runners force JavaScript actions to **Node 24** by default (opt-out temporarily via `ACTIONS_ALLOW_USE_UNSECURE_NODE_VERSION=true`).
- **2026-09-16**: Node 20 is **removed** from the runner image.

Surfaced as a deprecation **annotation** on the **Quality Gates** + **Release** workflows during the 2026-05-28 `npm run push:watch` run (ref: https://github.blog/changelog/2025-09-19-deprecation-of-node-20-on-github-actions-runners/).

**Fix**: bump the pinned actions to versions that ship on Node 24 — `actions/checkout@v5`, `actions/setup-node@v5`, and any other `@vN` actions — across all `.github/workflows/*.yml`. Do it before the 2026-06-02 default flip so CI neither emits the warning nor risks a silent break at the 2026-09-16 removal.

## Symptoms

- Deprecation annotation on every CI run: *"Node.js 20 actions are deprecated… actions/checkout@v4, actions/setup-node@v4… forced to Node.js 24 by default starting June 2nd, 2026… Node.js 20 will be removed from the runner on September 16th, 2026."*

## Workaround

None needed yet — the actions still run on Node 20 until 2026-06-02. The annotation is advisory until then.

## Impact Assessment

- **Who is affected**: CI for this repo (maintainer-facing); no adopter/runtime impact.
- **Frequency**: every CI run emits the annotation; hard break only if left past the 2026-09-16 Node-20 removal.
- **Severity**: low now, escalating — **time-bounded**: trivial bump now, vs a broken pipeline if forgotten past September 2026.

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems (note the time-bound — Likelihood rises as 2026-06-02 / 2026-09-16 approach).
- [ ] Enumerate all `@vN` action pins across `.github/workflows/*.yml` (checkout, setup-node, and any others); confirm which run on Node 20.
- [ ] Bump each to a Node-24-supporting major (checkout@v5, setup-node@v5, etc.); verify CI green on the bump.

## Dependencies

- **Blocks**: (none — but the 2026-06-02 / 2026-09-16 GitHub dates bound when this must land.)
- **Composes with**: (none)

## Related

- captured via /wr-itil:capture-problem 2026-05-28 — surfaced by the push:watch CI annotation during the RFC-011 release push; captured immediately rather than surfaced as a session-wrap recommendation (P148 recurrence corrected — see P148).
