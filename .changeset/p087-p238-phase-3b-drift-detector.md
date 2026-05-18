---
"@windyroad/retrospective": minor
---

P087 Phase 3b — plugin maturity drift detector ships (`wr-retrospective-check-plugin-maturity-drift`). New `packages/retrospective/scripts/check-plugin-maturity-drift.sh` canonical body + `packages/retrospective/bin/wr-retrospective-check-plugin-maturity-drift` ADR-049 shim. Sibling to ADR-051's `check-readme-jtbd-currency.sh` — same detector pattern, different anchor (`plugin.json` `maturity:` field vs JTBD ID citation).

Compares each plugin's rendered README maturity badge against the canonical `plugin.json` `maturity:` field and emits NDJSON-per-drift signals to stdout:

- `missing-badge` — plugin.json has maturity but README has no badge
- `stale-band` — README badge band mismatches canonical record
- `orphan-badge` — README has badge but plugin.json has no maturity
- `anti-pattern-section` — README has a standalone `## Maturity` section
- `anti-pattern-url` — README has a shields.io URL or inline SVG

Exit code 0 always per ADR-013 Rule 6 fail-safe / ADR-040 declarative-first — drift is data, not failure. Downstream consumers (run-retro Step 2b future wiring, release pre-flight habit, Phase 4 escalation per ADR-063 §Reassessment Triggers) decide whether to act.

14 behavioural bats fixtures at `packages/retrospective/scripts/test/check-plugin-maturity-drift.bats` cover: clean fixture, stale-band, missing-badge, orphan-badge, anti-pattern-section, anti-pattern-url, multi-plugin aggregation, exit-0-always invariant, package-without-README skip, ADR-035 no-network primitive, NDJSON output shape.
