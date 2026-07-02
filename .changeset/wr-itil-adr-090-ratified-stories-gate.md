---
"@windyroad/itil": minor
---

Enforce ADR-090's ratified-stories reference gate at RFC acceptance (P404 Phase 2). `manage-rfc`'s `proposed → accepted` transition now also runs the new `wr-itil-check-rfc-stories-ratified` predicate: every story an RFC lists must carry `human-oversight: confirmed`, else the transition hard-blocks. Composes with the ADR-089 has-stories gate — has-stories checks that at least one story exists, ratified checks that each listed one is confirmed.
