---
"@windyroad/itil": minor
---

Add shared shell migration routine `packages/itil/lib/migrate-problems-layout.sh` (synced from `packages/shared/lib/`) per P170 / RFC-002 / ADR-031. Exposes two functions sourced by adopter `manage-problem` / `work-problems` skills at Step 1 (T8 + T9 in follow-up commits): `detect_flat_layout` predicate and `migrate_problems_to_per_state_layout` idempotent entrypoint. The entrypoint auto-migrates adopter `docs/problems/<NNN>-<slug>.<state>.md` flat-layout trees to the per-state-subdirectory shape (`docs/problems/<state>/<NNN>-<slug>.md`) on first invocation after update; emits a standalone commit with `RISK_BYPASS: adr-031-migration` trailer. Dormant in this release — no skill sources the routine yet — but ships in the tarball so the consumer wiring in subsequent releases can rely on it being present. nullglob-guarded; partial-migration-safe; idempotent.
