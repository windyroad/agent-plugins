# @windyroad/wardley

## 0.1.5

### Patch Changes

- d33bb7d: P087 Phase 3 — retroactive maturity rollout across all 11 `@windyroad/*` plugins. Each plugin's `plugin.json` now carries a populated `maturity:` field per top-level surface (skills, agents, hooks, commands) plus a `{schema_version, band}` rollup on the plugin root entry per ADR-063 §plugin.json field schema. Each plugin's README now carries a prose-woven rollup badge (`*Maturity: <Band>.*`) in the value-framing lead prose line per ADR-051 anti-pattern + ADR-063 §README badge rendering format.

  Mechanical activation of Phase 3a (`wr-itil-plugin-maturity-populate`) and Phase 3b (`wr-itil-plugin-maturity-render`) against the live monorepo. Bootstrapping window active (suite-oldest surface 39 days shipped, less than 60-day threshold per ADR-053 §Bootstrapping clause); most surfaces land at Experimental with one Alpha bootstrapping surface (`wr-architect:agent` — meets the ≥100 invocations + ≥14 days criterion). Plugin root rollups all resolve to Experimental per the worst-case granularity contract (ADR-053 §granularity contract).

  Drift detector (`wr-retrospective-check-plugin-maturity-drift`) reports 0 drift instances across all 12 packages — rendered badges match canonical records. Anti-pattern absence verified: no standalone `## Maturity` section, no shields.io URL, no compound bootstrapping rendering in per-skill cells (compound stays at rollup per ADR-063).

  Closes the P087 Phase 3 retroactive mechanical rollout investigation task (P087 line 133). Activates the four Phase 3d JTBD outcome amendments shipped in P240: JTBD-302 maturity-band visibility, JTBD-007 maturity-band currency, JTBD-101 promotion-criteria visibility, JTBD-003 at-glance stability.

## 0.1.4

### Patch Changes

- 8a15336: Fix `--update` flag failing with "Plugin not found" (P025). The `updatePlugin` command was missing the `@windyroad` marketplace suffix and `--scope project`, causing all `npx @windyroad/<pkg> --update` invocations to fail. The correct command is now used: `claude plugin update "<name>@windyroad" --scope project`.

## 0.1.3

### Patch Changes

- 7ee97ba: Add README.md to every package and rewrite the root README with better engagement, problem statement, and project-scoped install documentation.

## 0.1.2

### Patch Changes

- eda2a15: Fix release preview to use pre-release versions (e.g., 0.1.2-preview.42) instead of exact release versions, preventing version collision with changeset publish.

## 0.1.1

### Patch Changes

- 3833199: Fix: bundle shared install utilities into each package so bin scripts work when installed via npx.
