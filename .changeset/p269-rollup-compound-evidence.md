---
"@windyroad/itil": patch
"@windyroad/architect": patch
"@windyroad/c4": patch
"@windyroad/connect": patch
"@windyroad/jtbd": patch
"@windyroad/retrospective": patch
"@windyroad/risk-scorer": patch
"@windyroad/style-guide": patch
"@windyroad/tdd": patch
"@windyroad/voice-tone": patch
"@windyroad/wardley": patch
---

P087 Phase 3 (P269) — amend `packages/itil/scripts/plugin-maturity-populate.sh` rollup-emission to write `rollup_invocations_30d` (sum of non-null per-surface `invocations_30d`; null when all-null) and `bootstrapping` (populate-time snapshot of the bootstrapping-window state) onto the plugin root `maturity:` rollup. Restores compliance with ADR-053 §Bootstrapping clause Phase 3 rendering requirement — the renderer's compound-form predicate at `plugin-maturity-render.sh` line 144-147 is AND-gated on both fields, so pre-amendment all 11 plugins fell through to bare-band during the bootstrapping window even though the band derivation correctly applied the bootstrapping rule.

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
