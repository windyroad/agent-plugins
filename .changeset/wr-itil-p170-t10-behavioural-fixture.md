---
"@windyroad/itil": patch
---

Fix `migrate_problems_to_per_state_layout` commit message: under git 2.47.x, `git commit --trailer "RISK_BYPASS: adr-031-migration"` produced a corrupted trailer line (`RISK_BYPASS: adr-031-migration:` with a spurious trailing colon) that broke downstream `^RISK_BYPASS:\s*adr-031-migration$` parsers in T11 commit-gate hook recognition. Switched to sequential `-m` paragraphs which emit a clean `RISK_BYPASS: adr-031-migration` body line. Discovered by RFC-002 T10 behavioural bats fixture (11 end-to-end tests at `packages/shared/test/migrate-problems-layout-behavioural.bats` simulating adopter flat-layout migration in a temp git repo).
