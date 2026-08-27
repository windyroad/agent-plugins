---
status: "proposed"
date: 2026-08-28
human-oversight: unconfirmed
decision-makers: [Tom Howard]
consulted: [wr-architect:agent]
informed: [Windy Road plugin users, Windy Road plugin developers]
reassessment-date: 2026-11-28
---

# npm releases authenticate through one OIDC trusted-publishing workflow

> Captured via /wr-architect:capture-adr (foreground-lightweight aside-invocation per the governance-skill invocation rule, derived-substance amendment 2026-07-06 / the full-substance capture implementation design). Section content was derived by the capturing agent from the in-session decision context; human-oversight: unconfirmed until ratified at the /wr-architect:review-decisions drain.

## Context and Problem Statement

The repository publishes stable and preview versions of thirteen `@windyroad/*` packages from separate GitHub Actions workflows using a long-lived npm token. The token expired on 2026-08-22, and the next stable release failed with npm's masked E404 authentication response, leaving committed package versions ahead of the registry. npm Trusted Publishing removes the rotating secret, but npm permits only one trusted publisher workflow per package.

## Decision Drivers

- Remove the recurring expiry and 2FA-bypass failure mode of long-lived npm publish tokens.
- Preserve both stable and preview publication.
- Bind publish authority to the exact public repository and workflow.
- Keep all independently published monorepo packages on one auditable release path.
- Meet npm's OIDC runtime requirements and retain automated provenance.

## Considered Options

1. **Consolidate stable and preview publication in `release.yml` (chosen)** — authorize one GitHub Actions workflow for all thirteen packages and route both publish modes through it.
2. **Authorize stable publication only** — remove preview publication and trust only the existing stable workflow.
3. **Keep a token for previews** — use OIDC for stable releases while retaining an expiring token for the separate preview workflow.

## Decision Outcome

Chosen option: **"Consolidate stable and preview publication in `release.yml`"**, because it preserves the existing release capabilities while eliminating persistent npm publish credentials and satisfying npm's one-trusted-workflow constraint.

## Consequences

### Good

- npm publish access uses short-lived workflow-bound OIDC credentials instead of a reusable secret.
- Stable and preview packages continue to publish from one reviewed workflow.
- Public releases receive npm provenance automatically.
- One workflow filename is configured consistently across every package.

### Neutral

- Stable and preview jobs share a workflow file but remain separately triggered and conditionally executed.
- Every published package requires the same npm-side trusted-publisher configuration.

### Bad

- The release workflow must use Node 22.14 or newer and npm 11.5.1 or newer even if other CI remains on Node 20.
- A workflow rename or repository transfer requires coordinated updates across all thirteen npm packages.
- npm-side configuration cannot be validated until an actual publish attempt exchanges the OIDC token.

## Confirmation

- `.github/workflows/release.yml` is the only workflow containing npm publish commands, grants `id-token: write`, uses Node 24 and npm 11.5.1 or newer, and contains no `NPM_TOKEN` or `NODE_AUTH_TOKEN` publish credential.
- `.github/workflows/release-preview.yml` is absent, while stable and changed-package preview paths are both covered by a focused executable regression test.
- All thirteen npm packages trust GitHub owner `windyroad`, repository `agent-plugins`, workflow `release.yml`, with `npm publish` allowed and no environment restriction.
- A preview and stable release both publish successfully and show npm provenance.
- After successful OIDC publication, package settings disallow traditional publish tokens and the obsolete GitHub/npm publish tokens are removed.

## Pros and Cons of the Options

### Consolidate stable and preview publication in `release.yml`

- Good, because it removes persistent publish credentials without dropping either release mode.
- Bad, because it combines two trigger paths in one workflow and requires coordinated npm configuration for every package.

### Authorize stable publication only

- Good, because it produces the smallest stable-release workflow change.
- Bad, because it removes preview releases that currently provide pre-release verification.

### Keep a token for previews

- Good, because it avoids consolidating the two workflows.
- Bad, because the expiry, rotation, and credential-exposure failure class remains active.

## Reassessment Criteria

Reassess if npm supports multiple trusted workflows per package, preview publication moves to npm staged publishing, the repository moves away from GitHub-hosted runners, or operational evidence shows the consolidated workflow cannot isolate stable and preview failures safely.

## Related

- ADR-018 — inter-iteration release cadence.
- ADR-020 — governance skills auto-release when changesets are queued.
- ADR-021 — plugin manifest version synchronization.
- P284 — npm authentication failure masked as scoped-package E404.
