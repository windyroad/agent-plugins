# Changesets

This directory holds queued [changesets](https://github.com/changesets/changesets) — version-bump declarations consumed by `changesets/action@v1` at release time to produce the Version Packages PR.

Each `*.md` file (excluding this `README.md`) is one changeset. The YAML frontmatter declares per-package bump classes; the body becomes the CHANGELOG entry.

## Release-preparation boundary

Ordinary implementation commits do not include changesets and remain `STAGED`. After the exact implementation pipeline passes and release preparation is intentional, inspect the cumulative package scope and create one complete changeset-only commit. Refresh the risk and scope assessment, run `push:watch`, then run `release:watch`. Never create speculative, placeholder, dormant-foundation, or “for later” changesets.

The cumulative changeset must name every package whose publishable behaviour changed. Renderer-only README regeneration needs only the renderer package; published `plugin.json` field changes need an entry for each affected package.

### Precedent

P0 hotfix `3cfa6fc` (2026-05-18, "restore plugin.json manifest validity") declared changeset entries for all 11 affected plugins, not the renderer alone. That commit is the canonical precedent for the per-package rule on `plugin.json` field shape changes.

### Why this matters

Separating integration from release preparation keeps implementation commits small and independently safe while preserving complete release metadata at the actual release boundary.

## Related

- ADR-021 — plugin manifest version sync mechanism (`.claude-plugin/plugin.json` is the published manifest)
- ADR-058 — semver classification (bump-class selection per change)
- ADR-390–393 — implementation-before-release-preparation policy
- P554 — retirement of commit-time changeset enforcement
- P278 — this clarification's tracking ticket
