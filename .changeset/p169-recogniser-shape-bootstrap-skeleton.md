---
"@windyroad/risk-scorer": patch
---

P169 — Recogniser-shape catalogue residual: extractor + bare-entry population.

`packages/risk-scorer/scripts/extract-risks-from-reports.sh` now emits a
`## Recogniser` skeleton on newly-scaffolded entries (Path patterns /
Diff-content keywords / Anti-patterns sub-blocks each marked with the
ADR-026-style "pending review" sentinel so curators can grep for
unfinished sections). New risks stop landing without the shape the
pipeline scorer relies on for slug-token matching.

3 new behavioural bats in
`packages/risk-scorer/scripts/test/extract-risks-from-reports.bats`
assert skeleton presence, sub-block headers, and pending-review
placeholders. 20/20 tests green.

Phase 1 (scorer reads `## Recogniser` from `docs/risks/R*.active.md`
catalogue entries) was already shipped via ADR-059's Catalog Consumption
Protocol. The companion `docs/risks/R011`–`R030.active.md` register
entries in the source monorepo are populated in the same commit but ship
to adopters as bootstrap output, not as code.

No new ADR — ADR-059 already governs the catalogue. No behavioural
regression for adopters who haven't re-run the bootstrap; the skeleton
only appears on freshly-scaffolded entries.
