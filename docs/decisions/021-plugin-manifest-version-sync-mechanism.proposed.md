---
status: "proposed"
date: 2026-04-19
decision-makers: [tomhoward]
consulted: [wr-architect:agent]
informed: [Windy Road plugin users]
reassessment-date: 2026-10-19
revised: 2026-04-19  # P052 — release.yml `version:` input added; Confirmation strengthened
---

# Plugin manifest version sync mechanism

## Context and Problem Statement

The release pipeline uses `changesets/action@v1` with `publish: npm run release` (which is `changeset publish`). Changesets bumps `packages/<plugin>/package.json` `version` fields based on queued changesets, then publishes to npm. Changesets knows nothing about `packages/<plugin>/.claude-plugin/plugin.json`.

The Claude Code marketplace reads `.claude-plugin/plugin.json` at git HEAD when serving the plugin catalogue. `claude plugin update` reports the stale manifest version as "latest" even though npm has newer code — silently shipping old code to every consumer of the Windy Road marketplace.

Discovered 2026-04-18 (P042): 11/11 plugin manifests were drifted. Three were behind by minor versions (e.g. `@windyroad/itil` was at manifest 0.1.0 / npm 0.4.0). The immediate drift was corrected in commit `51eec23`, but the systemic gap remained — the next release would drift again.

This ADR decides the sync mechanism to prevent recurrence.

## Decision Drivers

- **ADR-002 (Monorepo with Independently Installable Per-Plugin Packages)**: each plugin is independently versioned. The sync mechanism must preserve that independence — no cross-plugin coupling.
- **ADR-014 (Governance skills commit their own work) + ADR-018 (Inter-iteration release cadence)**: the lean release principle is undermined by drift. What "released" means must equal what the marketplace serves.
- **Reproducibility**: the sync must be part of the versioning pipeline, not a manual step prone to being forgotten.
- **Reviewability**: version bumps should remain visible in a single PR (the Changesets "Version Packages" PR), so reviewers can see the coordinated bump in one diff.
- **CI guardability**: even if the sync step fails for any reason, a drift must be caught before release lands on main.
- **Cross-platform**: the sync runs in GitHub Actions (Linux) and locally (macOS/Linux). Bash pattern matching suffices, but a Node script is equally portable and is easier to test against edge cases.
- **P042**: the open problem this ADR resolves.

## Considered Options

1. **Pre-publish sync script** — a script runs before `changeset publish` and copies `package.json` `version` into the sibling `plugin.json` for every plugin.
2. **Pre-commit hook (husky or similar)** — every commit that bumps a `package.json` `version` must also bump the matching `plugin.json`.
3. **Single source of truth (generate plugin.json at build time)** — `plugin.json` becomes an output artefact of a generator.
4. **Changesets `version` script hook (chosen)** — override the `npm run version` script so it runs `changeset version` followed by a sync step. Changesets/action runs `npm run version` if present (falling back to `changeset version` otherwise) before creating the "Version Packages" PR. The sync lands in the same PR as the version bump.

## Decision Outcome

Chosen option: **"Changesets `version` script hook"**. Wire the sync into `npm run version` so the Changesets action picks it up automatically when it creates or updates the Version Packages PR. The sync runs on the same working tree as `changeset version` and the Changesets action commits everything together, producing a single coordinated diff.

**Mechanism**:

1. Add `scripts/sync-plugin-manifests.mjs` (Node, cross-platform). It walks `packages/*/package.json`, copies `version` into `packages/<pkg>/.claude-plugin/plugin.json` when the manifest exists, and preserves all other manifest fields. Skips packages without a sibling manifest (e.g. `packages/shared/`, `packages/agent-plugins/`).
2. The script supports a `--check` flag: exits non-zero if any `plugin.json` `version` does not match its sibling `package.json`. Prints drifted paths in machine-readable form.
3. Root `package.json` gains:
   - `"version": "changeset version && node scripts/sync-plugin-manifests.mjs"` — the Changesets-action extension point.
   - `"sync:plugin-manifests": "node scripts/sync-plugin-manifests.mjs"` — manual invocation for local dev.
   - `"check:plugin-manifests": "node scripts/sync-plugin-manifests.mjs --check"` — used by CI.
4. A bats test (`packages/shared/test/plugin-manifest-sync.bats`) asserts the `--check` mode returns OK on the current working tree, and that the script flags drift on a mutated temp workspace. Mirrors the `sync-install-utils.bats` pattern.
5. The CI workflow (`.github/workflows/ci.yml`) gains a step: `npm run check:plugin-manifests`. A PR that edits `package.json` without the matching `plugin.json` update fails before merge.

### Fallback: pre-publish sync script

If the Changesets action removes the `version` script hook in a future version, or if a Changesets API change makes the hook unreliable, fall back to **Option 1 (pre-publish sync script)**:

- Add a step in `.github/workflows/release.yml` that runs `node scripts/sync-plugin-manifests.mjs` immediately before the Changesets action step.
- The same Node script serves both flows — the difference is only the trigger.
- The fallback sacrifices single-PR reviewability (the sync lands in a separate commit or is absorbed into the release commit), but the CI guard in step 5 still catches drift pre-merge.

No code change is required to enable the fallback — it is a workflow-level switch.

### Rejected options

- **Option 2 (pre-commit hook)** rejected as too invasive for normal dev work. A developer editing a plugin's source should not be forced to hand-edit the manifest on every commit. Drift only matters at release time.
- **Option 3 (generate plugin.json at build time)** rejected because Claude Code's marketplace reads `plugin.json` directly from git HEAD; there is no build step between commit and marketplace serve. A generator would either produce a committed file (back to square one sync-wise) or require marketplace-side support that does not exist.

## Consequences

### Good

- Sync happens automatically in the same PR as the version bump. Reviewers see a coordinated diff.
- No friction during normal development. The only time sync is relevant is when `changeset version` runs.
- CI guard catches drift pre-merge, even if the `version` script hook fails for any reason.
- The same Node script serves local, CI, and release workflows — one implementation, three triggers.
- The `--check` mode mirrors `sync-install-utils.sh --check`, so contributors already know the pattern.

### Neutral

- Introduces a new Node script to the release path. Adds one file to maintain. Cross-platform by construction (Node is already a build dep).
- The `version` script override takes precedence over the default `changeset version`. Any future Changesets feature that assumes the default is not overridden could be affected; mitigated by the fallback option.

### Bad

- Adds an implicit ordering dependency between the two commands in `npm run version` (`changeset version` must run first so `package.json` is bumped before sync runs). A typo or script edit that reverses the order would silently copy stale versions into manifests — CI guard catches this but only at PR time.

## Confirmation

Compliance is verified by:

1. **Source review**:
   - `scripts/sync-plugin-manifests.mjs` exists and supports `--check`.
   - Root `package.json` `scripts.version` runs `changeset version` then the sync script.
   - **`.github/workflows/release.yml` passes `version: npm run version` to `changesets/action@v1`** (added 2026-04-19 after P052). Without this explicit input, the action defaults to invoking `changeset version` directly and bypasses the `npm run version` hook entirely — observed on ADR-021's first production exercise (Release run 24618590442), which produced a Version PR with drifted plugin.json files.
   - `.github/workflows/ci.yml` runs `npm run check:plugin-manifests`.
2. **Test**: `packages/shared/test/plugin-manifest-sync.bats` asserts:
   - `--check` returns OK on the current working tree.
   - `--check` returns non-zero with a `DIVERGED:` line when any manifest is out of sync with its sibling `package.json`.
   - **`.github/workflows/release.yml` contains the explicit `version: npm run version` input** (added after P052). Regression guard against silently dropping the input.
3. **Behavioural**: the first Changesets "Version Packages" PR produced after this ADR ships MUST include both `packages/*/package.json` AND `packages/*/.claude-plugin/plugin.json` updates in a single diff. Verifiable by `gh pr diff <N>` on the Version PR. If only `package.json` + `CHANGELOG.md` appear and `plugin.json` is absent, the wiring is broken — P052 is the canonical evidence of this failure mode and its resolution.

## Reassessment Criteria

Revisit this decision if:

- Changesets drops or changes the `npm run version` script hook (trigger fallback Option 1).
- Claude Code's marketplace adds support for reading the version from `package.json` directly (would supersede the sync entirely).
- A plugin requires version divergence between `package.json` and `plugin.json` for legitimate reasons (breaking assumption of 1:1 sync).
- The number of plugins grows to where the sync step adds meaningful latency (currently 11 plugins sync in <100ms).

## Related

- ADR-002: `docs/decisions/002-monorepo-per-plugin-packages.proposed.md` — monorepo per-plugin versioning; this ADR extends it to cover manifest sync
- ADR-014: `docs/decisions/014-governance-skills-commit-their-own-work.proposed.md` — lean release principle (undermined by drift)
- ADR-018: `docs/decisions/018-inter-iteration-release-cadence-for-afk-loops.proposed.md` — inter-iteration release cadence (meaningless if manifests drift)
- P042: `docs/problems/042-changesets-does-not-sync-plugin-manifest-version.known-error.md` — the problem ticket this ADR resolves
- P052: `docs/problems/052-adr-021-release-yml-missing-version-input.open.md` — first-production-exercise drift; drove the 2026-04-19 revision adding the explicit `version: npm run version` input and the corresponding Confirmation / bats criteria
- P028: `docs/problems/028-governance-skills-should-auto-release-and-install.known-error.md` — auto-release flow (meaningless if marketplace serves stale manifests)
- Commit 51eec23 — the one-off corrective sync that brought all 11 manifests current as of 2026-04-18
- `packages/shared/test/sync-install-utils.bats` — precedent for the drift-guard test pattern
- `scripts/sync-install-utils.sh` — precedent for the `--check` mode semantics
