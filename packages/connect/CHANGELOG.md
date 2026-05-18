# @windyroad/connect

## 0.3.8

### Patch Changes

- 7ca47ef: P087 Phase 3 (P269) — amend `packages/itil/scripts/plugin-maturity-populate.sh` rollup-emission to write `rollup_invocations_30d` (sum of non-null per-surface `invocations_30d`; null when all-null) and `bootstrapping` (populate-time snapshot of the bootstrapping-window state) onto the plugin root `maturity:` rollup. Restores compliance with ADR-053 §Bootstrapping clause Phase 3 rendering requirement — the renderer's compound-form predicate at `plugin-maturity-render.sh` line 144-147 is AND-gated on both fields, so pre-amendment all 11 plugins fell through to bare-band during the bootstrapping window even though the band derivation correctly applied the bootstrapping rule.

  Schema additions are **additive-within-2.0** per ADR-058 §Confirmation #8 — no schema_version bump. Contrast with the §Amendment 2026-05-18 P0 hotfix which bumped `"1.0" → "2.0"` because that amendment was non-additive (path move). The P269 amendment strictly adds two new keys to the rollup dict; old consumers reading `{schema_version, band}` continue to work unchanged.

  Changes:

  - `packages/itil/scripts/plugin-maturity-populate.sh` rollup-emission block: collects per-surface `invocations_30d` during the surface walk; emits `rollup_invocations_30d` as sum-of-non-null (or null when all-null per the hook-only honesty contract); emits `bootstrapping` copied from the existing module-scope `bootstrapping_active` flag.
  - `docs/decisions/063-plugin-maturity-presentation-layer.proposed.md` — new dated amendment block §Amendment 2026-05-18 (P269 — rollup compound-evidence write); rollup schema example updated; P0 hotfix corrected-schema example updated with the two new fields and a forward-reference to the P269 amendment.
  - `packages/itil/scripts/test/plugin-maturity-populate.bats` — 5 new behavioural tests (sum-of-non-null, null-when-all-hook, bootstrapping-true-during-window, bootstrapping-false-post-sunset) + amended existing rollup-shape test for the new fields. Now 22 tests (up from 17).
  - `packages/itil/scripts/test/plugin-maturity-render.bats` — 2 new behavioural tests covering the AND-gated predicate edge cases (`bootstrapping=true + null-invocations → bare-band`, `bootstrapping=false + integer → bare-band`). Now 19 tests (up from 17).
  - `packages/itil/scripts/test/plugin-maturity-doc-lint.bats` — 2 new shape-when-present tests covering `rollup_invocations_30d: int | null` and `bootstrapping: bool` shapes. Now 13 tests (up from 11).
  - `docs/problems/open/269-...md` — Description amendment per architect Adjustment E naming both fields with the AND-gated predicate citation.
  - Retroactive rollout (separate commit per architect Adjustment C): re-ran populate + render against the live monorepo. All 11 plugins' `plugin.json` now carry the two new rollup fields (additive-within-2.0); 7 plugins' README compound-rendering activated; 4 plugins unchanged (already at the rendered shape).

  Architect verdict (P269 implementation pre-edit 2026-05-18) PASS with 5 adjustments folded in (in-place amendment over new ADR; additive-within-2.0; two-commit shape; behavioural tests; both fields in scope). JTBD verdict PASS — restores the JTBD-302 honesty signal (bootstrapping-window evidence is the load-bearing calibration anchor).

  Single multi-package patch changeset per ADR-021 — declares all 11 monorepo plugins because the populate rerun adds the two new rollup fields to every plugin.json (additive, but per-package source change per P141 changeset-discipline-hook precedent set by the §Amendment 2026-05-18 P0 hotfix `3cfa6fc`).

  Closes P269 — restores compound rendering across all bootstrapping-window plugins. P087 closure path advances: this was the last named outstanding-question on P087.

## 0.3.7

### Patch Changes

- 3cfa6fc: **P0 hotfix**: Phase 3 retroactive rollout (d33bb7d, shipped as @windyroad/itil@0.35.1 + 10 sibling plugins) wrote per-surface maturity records at top-level `plugin.json` keys (`skills:` / `agents:` / `hooks:` / `commands:`). Claude Code's plugin manifest validator rejects that shape with `Validation errors: hooks: Invalid input, skills: Invalid input`. All 11 plugins were unparseable by `claude plugin install`.

  **Fix** (ADR-063 Amendment 2026-05-18): per-surface maturity records nest UNDER the top-level `maturity:` key at `plugin_doc.maturity.<kind>.<name>`. Schema version bumps to "2.0" (path move is NOT additive per ADR-058 §Confirmation #8). Populate script (`packages/itil/scripts/plugin-maturity-populate.sh`) writes to the new nested location; render script (`packages/itil/scripts/plugin-maturity-render.sh`) reads from the new nested location. Defensive cleanup of legacy top-level keys on re-runs. Bats fixtures (populate + render + drift) updated to new shape — 17 + 17 + 14 green. Manifest fix-up applied to all 11 affected plugin.json files.

  **Hotfix-class bypass** per ADR-013 Rule 5 (reducing — closes a defect that broke `claude plugin install` for all adopters).

## 0.3.6

### Patch Changes

- d33bb7d: P087 Phase 3 — retroactive maturity rollout across all 11 `@windyroad/*` plugins. Each plugin's `plugin.json` now carries a populated `maturity:` field per top-level surface (skills, agents, hooks, commands) plus a `{schema_version, band}` rollup on the plugin root entry per ADR-063 §plugin.json field schema. Each plugin's README now carries a prose-woven rollup badge (`*Maturity: <Band>.*`) in the value-framing lead prose line per ADR-051 anti-pattern + ADR-063 §README badge rendering format.

  Mechanical activation of Phase 3a (`wr-itil-plugin-maturity-populate`) and Phase 3b (`wr-itil-plugin-maturity-render`) against the live monorepo. Bootstrapping window active (suite-oldest surface 39 days shipped, less than 60-day threshold per ADR-053 §Bootstrapping clause); most surfaces land at Experimental with one Alpha bootstrapping surface (`wr-architect:agent` — meets the ≥100 invocations + ≥14 days criterion). Plugin root rollups all resolve to Experimental per the worst-case granularity contract (ADR-053 §granularity contract).

  Drift detector (`wr-retrospective-check-plugin-maturity-drift`) reports 0 drift instances across all 12 packages — rendered badges match canonical records. Anti-pattern absence verified: no standalone `## Maturity` section, no shields.io URL, no compound bootstrapping rendering in per-skill cells (compound stays at rollup per ADR-063).

  Closes the P087 Phase 3 retroactive mechanical rollout investigation task (P087 line 133). Activates the four Phase 3d JTBD outcome amendments shipped in P240: JTBD-302 maturity-band visibility, JTBD-007 maturity-band currency, JTBD-101 promotion-criteria visibility, JTBD-003 at-glance stability.

## 0.3.5

### Patch Changes

- 8a15336: Fix `--update` flag failing with "Plugin not found" (P025). The `updatePlugin` command was missing the `@windyroad` marketplace suffix and `--scope project`, causing all `npx @windyroad/<pkg> --update` invocations to fail. The correct command is now used: `claude plugin update "<name>@windyroad" --scope project`.

## 0.3.4

### Patch Changes

- 24597ed: Update BLOCKED notice to link to canonical upstream issue #42292 (our filing #48216 was a duplicate).

## 0.3.3

### Patch Changes

- a0ecdf3: Add BLOCKED notice to README — setup skill is currently unusable due to upstream claude-code#48216 removing AskUserQuestion/EnterPlanMode/ExitPlanMode from `--channels` sessions. Runtime (send/receive) still works; only guided setup is affected.

## 0.3.2

### Patch Changes

- 05e9e2a: Setup skill now requires AskUserQuestion tool (no plain-prompt fallback). If the tool is unavailable, the skill stops and asks the user to restart Claude Code.

## 0.3.1

### Patch Changes

- c65757b: Break setup skill into fine-grained checkpoints — one action per question instead of multi-step chunks. Agent now pauses after every instruction to confirm.

## 0.3.0

### Minor Changes

- 45882d8: Rewrite setup skill to match Discord plugin flow: /discord:configure for token, --channels for connection, DM pairing, allowlist lockdown. Each repo gets its own bot named after org/repo. Session-start hook detects Discord plugin config instead of env var.

## 0.2.1

### Patch Changes

- 1fa0e46: Improve setup skill: interactive AskUserQuestion at each step, suggest wr-connect bot name, enable reaction intents, support .env file and 1Password CLI for credential storage

## 0.2.0

### Minor Changes

- 93527a5: Add connect plugin for cross-repo collaboration between Claude Code sessions via Discord (experimental)
