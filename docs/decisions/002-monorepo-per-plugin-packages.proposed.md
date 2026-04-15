---
status: "proposed"
date: 2026-04-08
decision-makers: [Tom Howard]
consulted: [Claude Code plugin docs, npm workspaces docs, ADR-001]
informed: [Windy Road plugin users]
reassessment-date: 2026-07-08
---

# Monorepo with Independently Installable Per-Plugin Packages

## Context and Problem Statement

ADR-001 introduced a unified installer (`npx @windyroad/agent-plugins`) that installs all 10 plugins and 11 skills in one command. This solves the two-command problem but introduces a new one: users must install everything even if they only want a subset.

A user who wants architecture governance and TDD enforcement has no reason to install voice-and-tone or style-guide hooks. The C4 and Wardley diagram skills are general-purpose tools useful to anyone, not just governance suite users. Forcing an all-or-nothing install:

- Adds unnecessary hooks that fire on every prompt/edit
- Clutters the skill autocomplete with unneeded commands
- Makes the suite feel heavyweight when the user only needs two or three plugins

Each plugin is already architecturally independent (own agent, own hooks, own skill). The distribution model should reflect that.

## Decision Drivers

- **User choice**: Different teams need different subsets. Architecture + TDD is a common combo; voice-tone + style-guide is another. Users should compose what they need.
- **Standalone value**: C4, Wardley, and the meta-installer are useful outside the governance context.
- **Cohesion**: Some plugins have skills that belong together (architect + adr skill, risk-scorer + risk-policy skill). These should ship as one unit.
- **Dependency management**: wr-itil depends on wr-risk-scorer; wr-retrospective depends on both. Per-package installs must handle this.
- **Maintainability**: All plugins share conventions, hook patterns, and the shared `check-deps.sh` library. A single repo is easier to maintain than 11 separate repos.
- **Release coordination**: The marketplace and skills must stay in sync. A monorepo with npm workspaces gives atomic commits across all packages.

## Considered Options

### Option 1: npm Workspaces Monorepo with Per-Plugin Packages

Restructure the repo into npm workspaces. Each plugin becomes a publishable `@windyroad/*` package with its own `package.json`. The meta-installer (`@windyroad/agent-plugins`) remains as the "install everything" entry point.

### Option 2: Separate Repositories Per Plugin

Split each plugin into its own GitHub repo. Each publishes independently.

### Option 3: Keep Single Package, Add `--plugin` Flag

Keep the current structure. The installer's `--plugin` flag (from ADR-001) handles selective install. No new packages.

## Decision Outcome

**Chosen option: Option 1 — npm Workspaces Monorepo**

This is the only option that gives users independent installability while keeping development in a single repo with atomic commits and shared tooling.

## Monorepo Structure

```
agent-plugins/
├── package.json                  (workspaces root)
├── .claude-plugin/
│   └── marketplace.json          (unchanged — marketplace still serves all plugins)
├── shared/
│   └── check-deps.sh
├── packages/
│   ├── agent-plugins/            @windyroad/agent-plugins (meta-installer)
│   │   ├── package.json
│   │   └── bin/install.mjs
│   ├── architect/                @windyroad/architect
│   │   ├── package.json
│   │   ├── agents/agent.md
│   │   ├── hooks/
│   │   └── skills/wr:adr/SKILL.md
│   ├── risk-scorer/              @windyroad/risk-scorer
│   │   ├── package.json
│   │   ├── agents/
│   │   ├── hooks/
│   │   └── skills/wr:risk-policy/SKILL.md
│   ├── tdd/                      @windyroad/tdd
│   │   ├── package.json
│   │   ├── hooks/
│   │   └── skills/wr:tdd/SKILL.md
│   ├── voice-tone/               @windyroad/voice-tone
│   │   ├── package.json
│   │   ├── agents/
│   │   ├── hooks/
│   │   └── skills/wr:voice-tone/SKILL.md
│   ├── style-guide/              @windyroad/style-guide
│   │   ├── package.json
│   │   ├── agents/
│   │   ├── hooks/
│   │   └── skills/wr:style-guide/SKILL.md
│   ├── jtbd/                     @windyroad/jtbd
│   │   ├── package.json
│   │   ├── agents/
│   │   ├── hooks/
│   │   └── skills/wr:jtbd/SKILL.md
│   ├── itil/                     @windyroad/itil
│   │   ├── package.json
│   │   ├── hooks/
│   │   └── skills/manage-problem/SKILL.md
│   ├── retrospective/            @windyroad/retrospective
│   │   ├── package.json
│   │   ├── hooks/
│   │   └── skills/wr:retrospective/SKILL.md
│   ├── c4/                       @windyroad/c4
│   │   ├── package.json
│   │   └── skills/
│   │       ├── wr:c4/SKILL.md + scripts/
│   │       └── wr:c4-check/SKILL.md + scripts/
│   └── wardley/                  @windyroad/wardley
│       ├── package.json
│       └── skills/wr:wardley/SKILL.md + owm-to-svg.mjs
└── plugins/                      (symlinks or build output pointing to packages/*)
```

## Package Dependency Graph

```
@windyroad/agent-plugins (meta-installer)
  ├── @windyroad/architect        (standalone)
  ├── @windyroad/risk-scorer      (standalone)
  ├── @windyroad/tdd              (standalone)
  ├── @windyroad/voice-tone       (standalone)
  ├── @windyroad/style-guide      (standalone)
  ├── @windyroad/jtbd             (standalone)
  ├── @windyroad/itil             (requires: @windyroad/risk-scorer)
  ├── @windyroad/retrospective    (requires: @windyroad/itil, @windyroad/risk-scorer)
  ├── @windyroad/c4               (standalone)
  └── @windyroad/wardley          (standalone)
```

## Install UX

```bash
# Everything
npx @windyroad/agent-plugins

# Just what you need
npx @windyroad/architect
npx @windyroad/tdd
npx @windyroad/c4

# Selective via meta-installer
npx @windyroad/agent-plugins --plugin architect risk-scorer tdd

# Update one package
npx @windyroad/architect --update
```

Each per-plugin package would have its own bin script that:
1. Adds the marketplace (if not already added)
2. Installs that plugin via `claude plugin install`
3. Installs that plugin's skills via `npx skills add`
4. Warns if dependencies are missing (e.g., installing problem without risk-scorer)

## Consequences

### Good

- Users install only what they need
- C4 and Wardley are discoverable as standalone tools on npm
- Each package can have its own README, keywords, and npm discoverability
- Single repo means atomic commits, shared CI, consistent conventions
- npm workspaces is lightweight — no extra tooling (turborepo/nx) needed at this scale
- The marketplace continues to work unchanged alongside the npm packages
- Per-plugin bin scripts handle the dual-install problem (marketplace + skills) at the individual level

### Neutral

- 12 packages to version and publish (can be automated with changesets or similar)
- `plugins/` directory needs to map to `packages/*/` for the marketplace — either symlinks or a build step
- The marketplace `source` paths in `marketplace.json` need updating

### Bad

- More complex release process than a single package
- Users who want everything still run one command, but the meta-installer must coordinate 11 sub-installs
- Per-plugin bin scripts duplicate some logic (marketplace add, skills add) — mitigated by shared utility code in the workspace

## Confirmation

- Each `@windyroad/*` package can be installed independently with `npx @windyroad/<name>`
- `npx @windyroad/agent-plugins` still installs everything (backward compatible with ADR-001)
- `npx @windyroad/agent-plugins --plugin architect tdd` installs only those two
- `npx @windyroad/c4` installs C4 skills without any governance hooks
- Installing `@windyroad/itil` warns that `@windyroad/risk-scorer` is required
- The marketplace still works: `claude plugin install wr-architect@windyroad`
- Skills autocomplete works for individually installed packages

## Pros and Cons of the Options

### Option 1: npm Workspaces Monorepo

- Good: Users choose exactly what they need
- Good: Standalone packages are discoverable on npm
- Good: Single repo — atomic commits, shared tooling, one CI pipeline
- Good: npm workspaces is zero-config at this scale
- Bad: 12 packages to version and publish
- Bad: Marketplace source paths need remapping
- Bad: Per-plugin bin scripts duplicate some orchestration logic

### Option 2: Separate Repositories

- Good: Maximum independence — each plugin has its own issues, releases, CI
- Good: Contributors can work on one plugin without cloning everything
- Bad: Massive overhead for 11 repos — 11 CI configs, 11 READMEs, 11 release pipelines
- Bad: Cross-cutting changes (shared conventions, hook patterns) require coordinated PRs
- Bad: Dependency plugins (problem, retrospective) are harder to test in isolation
- Bad: The marketplace needs a separate repo or must aggregate from 11 sources

### Option 3: Single Package with `--plugin` Flag

- Good: Simplest — no structural changes needed
- Good: Already implemented in ADR-001
- Bad: No npm discoverability for individual plugins
- Bad: C4/Wardley can't be found or installed independently
- Bad: Users must know plugin names upfront — no browsing on npm
- Bad: The whole package must be downloaded even for one plugin

## Reassessment Criteria

- **Plugin count grows significantly**: If the suite grows beyond ~15 plugins, consider whether the monorepo tooling needs upgrading (e.g., changesets, turborepo).
- **Codex/Copilot support**: When adding support for other AI coding tools, the per-plugin package structure should extend naturally — each package adds its tool-specific install logic.
- **anthropics/claude-code#35641 is fixed**: Per-plugin packages could then bundle skills directly, eliminating the need for the separate `npx skills add` step in each bin script.
- **Community contributions**: If external contributors want to add plugins, the monorepo structure should accommodate third-party packages or a plugin template.
