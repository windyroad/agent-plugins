# Changesets

This directory holds queued [changesets](https://github.com/changesets/changesets) — version-bump declarations consumed by `changesets/action@v1` at release time to produce the Version Packages PR.

Each `*.md` file (excluding this `README.md`) is one changeset. The YAML frontmatter declares per-package bump classes; the body becomes the CHANGELOG entry.

## Per-package changesets vs renderer-package convention

The `itil-changeset-discipline.sh` hook (P141) requires a changeset entry for every `packages/<slug>/` source change that lands publishable code. The boundary between "the renderer's package suffices" and "every modified package needs its own entry" is content-based, not file-count-based.

### Rule

- **README content shifts** (e.g. rollup-renderer output regenerating `packages/<slug>/README.md` across N plugins) → **one changeset entry under the renderer's package suffices**. The renderer is the publishable change; the regenerated READMEs are the renderer's output, not independent source changes. The hook's `README.md` allow-list (`packages/<slug>/README.md` → continue) reflects this: README edits alone are not publishable source.

- **`plugin.json` field additions, removals, or value changes** (e.g. populate scripts writing a new `rollup_invocations_30d` field on every plugin root) → **each modified plugin gets its own changeset entry**. `.claude-plugin/plugin.json` is a published manifest read by the Claude Code marketplace at git HEAD (ADR-021); a field shape change is a per-package publishable change, not a renderer side-effect.

- **Source code changes** (anything under `packages/<slug>/` not allow-listed by the hook — `test/`, `hooks/test/`, `scripts/test/`, `README.md`, `docs/*.md` are allow-listed) → **per-package changeset entry**, identical to the `plugin.json` case.

### Precedent

P0 hotfix `3cfa6fc` (2026-05-18, "restore plugin.json manifest validity") declared changeset entries for all 11 affected plugins, not the renderer alone. That commit is the canonical precedent for the per-package rule on `plugin.json` field shape changes.

### Why this matters

Without the boundary rule, every populate or render rerun on multi-plugin field-shape changes repeats the changeset-iteration cycle: the agent proposes a single-package changeset, the P141 gate denies, the agent rewrites for all N packages. The rule above prevents the cycle by codifying intent up front.

## Related

- ADR-021 — plugin manifest version sync mechanism (`.claude-plugin/plugin.json` is the published manifest)
- ADR-058 — semver classification (bump-class selection per change)
- P141 — `itil-changeset-discipline.sh` hook (source-of-truth enforcement)
- P278 — this clarification's tracking ticket
