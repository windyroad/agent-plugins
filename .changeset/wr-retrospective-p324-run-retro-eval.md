---
"@windyroad/retrospective": patch
---

P324 Phase 6 — paired promptfoo Tier-A/B eval for `run-retro` SKILL surface (6/6 GREEN). First eval-bearing release for `@windyroad/retrospective` — `package.json` `files:` array adds the `"!skills/*/eval/"` negation and a new `packages/retrospective/.npmignore` belts-and-braces the exclusion (verified via `npm pack --dry-run` — zero `eval/` paths in the tarball). The eval ships under `packages/retrospective/skills/run-retro/eval/` and is excluded from the published tarball; only the build-side test infrastructure is added. Flips the R009 prose-surface modulator +1 → -1 for `run-retro`, dropping the retrospective-plugin prose class within appetite per ADR-061 Rule 4 evidence-floor.
