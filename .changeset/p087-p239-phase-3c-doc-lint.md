---
"@windyroad/itil": patch
---

P087 Phase 3c (P239) — bats doc-lint per plugin asserting `plugin.json` `maturity:` field shape, rollup-equals-worst-case invariant, README badge marker currency, and anti-pattern absence. Ships as `packages/itil/scripts/test/plugin-maturity-doc-lint.bats` (11 tests, behavioural per ADR-052; runs against the standard `bats --recursive packages/*/scripts/test/` harness).

Coverage per ADR-063 §Phase 3c contract:

- **A1 Schema shape**: every per-surface record under `maturity.skills` / `maturity.agents` / `maturity.hooks` / `maturity.commands` carries `schema_version` ∈ `{"1.0", "2.0"}`, `band` ∈ taxonomy, `computed_at` string, and `evidence: {invocations_30d, days_shipped, closed_tickets_window, breaking_change_age_days}`. `invocations_30d` may be null for hook surfaces (transcript-unobservable); `breaking_change_age_days` may be null (no breaking marker observed).
- **A2 Rollup shape**: plugin root carries `schema_version` + `band` mandatory pair per ADR-063 §rollup-schema + iter-10 Amendment 2026-05-18 (nested per-kind maps tolerated additionally).
- **A3 Worst-case invariant**: rollup band equals worst-case of constituent surfaces per ADR-053 §granularity contract. Includes two synthetic-fixture tests — multi-band (Experimental ≻ Beta ⇒ rollup Experimental) and all-Deprecated (rollup Deprecated).
- **A4 README marker**: per-plugin README carries `*Maturity: <band>` anchored regex match followed by `.` or `(`, where `<band>` equals the canonical plugin.json rollup band. Architect adjustment A2 tightening (anchored regex over raw substring).
- **A5 Anti-patterns**: README has NO standalone `## Maturity` heading; NO `img\.shields\.io/badge/maturity` shields.io URL; per-skill table cells contain NO compound bootstrapping rendering (`(suite-bootstrap window;`) — compound stays at rollup per ADR-063 §Bootstrapping clause rendering.
- **Regression fence (architect adjustment A1)**: no top-level `skills:` / `agents:` / `hooks:` / `commands:` keys carry maturity-shaped records. Guards the iter-10 P0 hotfix incident class (Claude Code manifest validator rejection on top-level kind keys carrying maturity-only records).

Plugins without `maturity:` are skipped — the lint asserts SHAPE WHEN PRESENT, not mandatory presence per-plugin. Presence enforcement belongs to a Phase 4+ release-blocking gate per ADR-013 Rule 6 (advisory → release-blocking escalation on N consecutive releases with M drift instances).

Compound-vs-bare badge form is OUT OF SCOPE for this lint per architect adjustment A3 — the renderer's compound-rendering fall-through (renderer expects `rollup_invocations_30d` field that populate never writes) is a separate sub-iter defect. The lint asserts band-substring-match only and remains agnostic to the compound form.

Closes P239 Investigation Tasks (bats fixture, anti-pattern assertions, rollup-equals-worst-case invariant on multi-band synthetic fixture, dynamic plugin discovery). P239 transitions Open → Verifying this iter.
