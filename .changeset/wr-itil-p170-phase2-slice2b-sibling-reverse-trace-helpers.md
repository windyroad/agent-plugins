---
"@windyroad/itil": minor
---

P170 Phase 2 Slice 2b — three sibling generalised reverse-trace helpers landing alongside the canonical Slice 2a helper:

- `packages/itil/scripts/update-rfc-references-section.sh` — `## Story Maps` / `## Stories` sections on RFC files
- `packages/itil/scripts/update-jtbd-references-section.sh` — `## RFCs` / `## Story Maps` / `## Stories` sections on JTBD files (NEW reverse-trace surface tier)
- `packages/itil/scripts/update-story-references-section.sh` — `## RFCs` / `## Story Maps` sections on story files

All three follow the same lookup-table-driven dispatch pattern as Slice 2a (no per-section-name branching in body per ADR-060 § Phase 2 encoding amendment 2026-05-12 architect finding 4); polymorphic extraction (HTML data-attribute grep / markdown frontmatter parse) per source-artefact type; lazy-empty discipline; idempotent rerun. Sanity bats fixture asserts existence + executable + positional argument validation + structural no-branching guard for all three siblings. Full behavioural coverage of the polymorphism is asserted by Slice 2a's comprehensive bats fixture for the canonical helper.
