---
status: "proposed"
date: 2026-04-15
decision-makers: [Tom Howard]
consulted: [wr-architect:agent]
informed: [Windy Road plugin users]
reassessment-date: 2027-04-15
---

# Rename `wr-problem` Plugin to `wr-itil`

## Context and Problem Statement

The `wr-problem` plugin implements an ITIL-aligned problem management process. The current name reflects its only skill (`update-ticket`, which creates/updates problem tickets) rather than the framework it implements.

As the plugin matures, natural next steps are peer ITIL skills — incident management, change management, continual improvement — all of which share the same domain model (tickets, lifecycle, prioritisation). The current name forecloses that expansion or forces a later rename.

Tracked as P010 (`docs/problems/010-rename-wr-problem-to-wr-itil.open.md`).

## Decision Drivers

- **Framework alignment**: the plugin is ITIL-shaped, not problem-shaped. The name should say so.
- **Room for expansion**: future ITIL-aligned skills (incident, change) should fit under the same plugin without another rename.
- **Pre-1.0 surface**: the plugin suite is pre-release. Renames are cheap now; expensive after adoption grows.
- **Rename precedent**: ADR-006 (`cross-repo-signal → connect`) established the pattern — hard rename, no deprecation shim, no traces of the old name.
- **Dependency coordination**: `@windyroad/retrospective` depends on `@windyroad/problem`. Any rename must bump both together.

## Considered Options

### Option 1: Hard rename to `wr-itil` (chosen)

- npm package: `@windyroad/problem` → `@windyroad/itil`
- Plugin name: `wr-problem` → `wr-itil`
- Directory: `packages/problem/` → `packages/itil/`
- Skill command: `/wr-problem:update-ticket` → `/wr-itil:manage-problem`
- Skill directory: `skills/update-ticket/` → `skills/manage-problem/`
- Bump `@windyroad/retrospective` to depend on `@windyroad/itil`
- `npm deprecate @windyroad/problem "Renamed to @windyroad/itil"` on any already-published versions
- No shim package published

### Option 2: Keep `wr-problem`, add new plugin per ITIL skill

Leave `wr-problem` alone. Create `@windyroad/incident`, `@windyroad/change`, etc. as separate plugins when needed.

### Option 3: Rename to broader non-ITIL name (e.g. `wr-ops`, `wr-process`)

Pick a neutral label that admits ITIL skills plus other process tooling (retrospectives, post-mortems, etc.).

### Option 4: Defer — keep `wr-problem` until a second ITIL skill is actually needed

Don't rename speculatively. Pay the rename cost only when the second skill forces the issue.

## Decision Outcome

**Chosen option: Option 1 — hard rename to `wr-itil`.**

The plugin already *is* an ITIL implementation. The current name is misleading today, independent of future expansion. Renaming is a cosmetic fix that becomes materially more expensive with every release, published dependency, and external reference. Pre-1.0 is the right time.

No shim package: the `cross-repo-signal → connect` precedent is clean, and there are no known external consumers. The only internal consumer (`@windyroad/retrospective`) is bumped in the same changeset. For published versions, `npm deprecate` provides a tombstone without a shim.

## Scope

### Rename mapping

| From | To |
|------|-----|
| `@windyroad/problem` (npm) | `@windyroad/itil` |
| `wr-problem` (plugin name) | `wr-itil` |
| `packages/problem/` | `packages/itil/` |
| `/wr-problem:update-ticket` | `/wr-itil:manage-problem` |
| `packages/problem/skills/update-ticket/` | `packages/itil/skills/manage-problem/` |

### Files to update

- `packages/problem/package.json` → name, bin
- `packages/problem/.claude-plugin/plugin.json` → plugin name
- `packages/problem/skills/update-ticket/SKILL.md` → rename to `manage-problem` + update frontmatter
- `packages/problem/hooks/` — any references
- `packages/problem/agents/` — any references
- `packages/problem/README.md`
- `packages/retrospective/package.json` → dependency bump
- `packages/retrospective/skills/*` — references to the old command
- `.claude-plugin/marketplace.json` — entry rename
- `packages/agent-plugins/bin/install.mjs` — PLUGINS array
- `README.md` (root) and `docs/BRIEFING.md` — any mentions
- `docs/decisions/002-monorepo-per-plugin-packages.proposed.md` — update package inventory (lines 95-98, 124-125) to reflect `itil/` / `@windyroad/itil`
- BATS tests — grep for `wr-problem`, `@windyroad/problem`, `update-ticket`, `update_ticket`
- `docs/problems/010-...` — mark fix strategy ADR number as ADR-010

### Out of scope

- Adding incident/change/other ITIL skills — this ADR makes room for them but does not add them.
- Changing the ticket format or lifecycle — unchanged.
- Migrating historical problem docs — `docs/problems/` structure is unchanged.

## Scope Signalling

This rename signals **room for expansion**, not commitment to it. Additional ITIL skills (incident, change) are not in scope here. If a second skill is added, reuse the `/wr-itil:<verb>-<object>` naming pattern (`manage-problem`, `manage-incident`, `manage-change`).

## Migration Path for Users

- Any user who installed `wr-problem` via the marketplace will silently stop receiving updates after this rename.
- Release notes and the plugin README must document:
  - The rename
  - The new install command (`npx @windyroad/itil` or marketplace re-install)
  - The new skill command (`/wr-itil:manage-problem`)
- `npm deprecate @windyroad/problem "Renamed to @windyroad/itil — install @windyroad/itil instead"` after the new package publishes.

## Consequences

### Good

- Plugin name matches framework scope
- Room for peer ITIL skills without a second rename
- One-and-done rename while pre-1.0

### Neutral

- Naming pattern (`/wr-itil:manage-problem`) establishes a template for future skills — no binding commitment, just a suggestion
- ADR-002 package inventory updated in the same change

### Bad

- External users who installed `@windyroad/problem` / `wr-problem` must re-install under the new name
- Documentation and tutorials that reference the old name become stale
- Git blame churn across multiple packages

## Confirmation

- [ ] `grep -rn "wr-problem\|@windyroad/problem\|packages/problem/\|update-ticket" --exclude-dir=node_modules --exclude-dir=.git` returns only intentional references (e.g. in this ADR and P010)
- [ ] `@windyroad/retrospective` package.json updated to depend on `@windyroad/itil`
- [ ] `.claude-plugin/marketplace.json` entry renamed
- [ ] `packages/agent-plugins/bin/install.mjs` PLUGINS array updated
- [ ] ADR-002 inventory and dependency graph updated
- [ ] All BATS tests pass
- [ ] `npm deprecate @windyroad/problem` executed for any previously published versions
- [ ] Changesets: `@windyroad/itil` new package, `@windyroad/retrospective` minor bump, release notes call out migration

## Reassessment Criteria

- **Expansion confirmed**: if a second ITIL skill (incident, change, or similar) is added within 12 months, the `wr-itil` framing was right — no action.
- **No expansion**: if no peer ITIL skill is added within 12 months, the rename may have been premature. Reassess whether `wr-itil` is still the best framing or whether a narrower name (reverting to `wr-problem`) or broader name (`wr-ops`) would be clearer.
- **External adoption signals**: if users ask for non-ITIL process tooling (post-mortems, OKR tracking) that naturally would live here, reconsider the `itil` framing.

## Related

- P010 (`docs/problems/010-rename-wr-problem-to-wr-itil.open.md`) — the problem this ADR resolves
- ADR-002 (monorepo structure) — package inventory needs updating as part of this change
- ADR-006 (connect plugin) — rename precedent (`cross-repo-signal → connect`)
