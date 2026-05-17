---
'@windyroad/retrospective': patch
---

P097 empirical baseline: first concrete application of ADR-054's sibling-`REFERENCE.md` pattern to `packages/retrospective/skills/analyze-context/`.

Extracted `## Composition with sibling measurements` and `## ADRs cited` sections (~1.7KB combined) from `SKILL.md` to new sibling `REFERENCE.md`; added 2 lazy-load pointer lines per ADR-054 § "Sibling REFERENCE.md pattern" (~280B). Net `SKILL.md` reduction: -1,212 bytes (-7.7%); skill remains OVER WARN but no longer accumulates rationale + lineage at the runtime hot path. All 18 sibling structural-grep bats stay green (token-by-token verified pre-extraction); 21 `check-skill-md-budgets.sh` bats stay green.

Content-equivalent refactor — no behavioural change to the `/wr-retrospective:analyze-context` flow. Per-skill `REFERENCE.md` sibling files are net-new in the retrospective package; this is the canonical empirical example for downstream plugin authors (JTBD-101) and the first proof-of-pattern instance ahead of P241 (MUST_SPLIT cohort, blocked by P081 Layer B), P242 (install-updates project-local), and P243 (WARN-band cohort) follow-ons.
