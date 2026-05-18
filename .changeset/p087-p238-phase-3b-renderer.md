---
"@windyroad/itil": minor
---

P087 Phase 3b — README badge renderer ships (`wr-itil-plugin-maturity-render`). New `packages/itil/scripts/plugin-maturity-render.sh` canonical body + `packages/itil/bin/wr-itil-plugin-maturity-render` ADR-049 shim. Reads each plugin's `plugin.json` `maturity:` field (populated by Phase 3a) and writes a prose-woven `*Maturity: <Band>.*` span into the README.md value-framing lead prose line, plus a `Maturity` column populated in the existing `## Skills` table. Idempotent — re-running with unchanged plugin.json produces byte-identical README output; existing `*Maturity: ...*` spans are replaced, not duplicated.

Compound rendering (e.g. `*Maturity: Experimental (suite-bootstrap window; <N> invocations / 30d).*`) stays at the rollup during the suite-bootstrap window per ADR-053 §Bootstrapping clause rendering; per-skill column cells carry band name only.

Anti-patterns enforced: never emits a standalone `## Maturity` section, never emits a shields.io URL / inline SVG (markdown text only per ADR-063 §F5).

17 behavioural bats fixtures at `packages/itil/scripts/test/plugin-maturity-render.bats` cover: badge insertion, bootstrapping compound rendering, post-bootstrap band-only rendering, per-skill column add, idempotency, badge-replacement, anti-pattern absence, fail-safe missing-maturity / missing-README, ADR-044 no-AskUserQuestion, ADR-035 no-network primitive, multi-plugin independence, dry-run preview.

Phase 3b drift detector (`check-plugin-maturity-drift.sh`) ships in `@windyroad/retrospective` — sibling minor bump.
