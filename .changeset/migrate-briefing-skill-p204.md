---
"@windyroad/retrospective": minor
---

Add `/wr-retrospective:migrate-briefing` — idempotent migration skill that splits a legacy single-file `docs/BRIEFING.md` into the per-topic `docs/briefing/` tree the Tier-3 rotation contract (ADR-040) and SessionStart briefing surface expect. Foreground-synchronous per ADR-032; self-commits per ADR-014; ships behavioural fixture + contract bats per ADR-052; helper script invoked via `wr-retrospective-migrate-briefing` PATH shim per ADR-049/ADR-080. Closes P204.
