# Problem 435: wr-risk-scorer gates hardcoded to home-repo shape — push-gate over-fires on non-npm repos, external-comms under-fires on static-site/deck content

**Status**: Open
**Reported**: 2026-07-06
**Priority**: 9 (Medium) — Impact: 3 × Likelihood: 3
**Origin**: inbound-reported (#235, #253)
**Effort**: M. WSJF = (9 × 1.0) / 2 = 4.5.
**WSJF**: 4.5 — (9 × 1.0) / 2 (added 2026-07-26 review)
**JTBD**: JTBD-101
**Persona**: plugin-developer

## Description

Two faces of one class — `wr-risk-scorer` gate scope is hardcoded to the home-repo (`windyroad/windyroad`) shape:
- **Over-fire (#235)**: `git-push-gate.sh` blocks bare `git push` telling the user to run `npm run push:watch`, which doesn't exist outside the home repo; the deny message cites pipeline/changeset/Netlify concepts absent in adopter repos — a gate with no path through it.
- **Under-fire (#253)**: `external-comms` scopes "external-facing prose" to gh issue/PR/advisory + npm + `.changeset/*.md`, missing static-site / deck content (`**/pages/**/*.astro`, `**/content/**/*.md(x)`), so factual claims shipped to a public site/deck go ungated (a credential overstatement shipped across ~8 commits).

## Symptoms

- Adopter without a pipeline: bare `git push` blocked with no actionable path.
- Adopter shipping a public site/deck: factual-claim edits never reach the external-comms gate.

## Impact Assessment

- **Who is affected**: adopters whose repo shape differs from the home repo (most).
- **Frequency**: push-gate every push; external-comms every site/deck edit.
- **Severity**: Medium — over-fire blocks a common action; under-fire leaks factual-claim risk.

## Root Cause Analysis

### Investigation Tasks

- [ ] push-gate: detect absence of a pipeline (`npm run push:watch` / changeset config) and pass-through with adopter-appropriate guidance instead of a home-repo-shaped deny.
- [ ] external-comms: extend the surface globs to static-site/deck content (file-pattern option A; content-classifier option B).

## Dependencies

- **Composes with**: P208 (CI-status check on push — assumes home-repo push:watch), P276 (external-comms over-fires on PASS-class edits — the opposite direction).

## Related

- Inbound issues #235 (over-fire), #253 (under-fire). Kept as one ticket: same root class (gate scope hardcoded to home-repo shape).


## Story Maps

| ID | Title | Status |
|----|-------|--------|
| STORY-MAP-008 | STORY-MAP-008: Have a plugin behave like a guest in my repository | draft |
