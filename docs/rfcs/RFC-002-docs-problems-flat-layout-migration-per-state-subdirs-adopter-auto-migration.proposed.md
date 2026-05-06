---
status: proposed
rfc-id: docs-problems-flat-layout-migration-per-state-subdirs-adopter-auto-migration
reported: 2026-05-07
decision-makers: [Tom Howard]
problems: [P069]
adrs: []
jtbd: []
---

# RFC-002: docs/problems/ flat layout migration — per-state subdirs + adopter auto-migration

**Status**: proposed
**Reported**: 2026-05-07
**Problems**: P069
**ADRs**: (none)
**JTBD**: (none)

## Summary

Migrate `docs/problems/<NNN>-<slug>.<status>.md` from the current flat layout to a per-state subdirectory structure (`docs/problems/<status>/<NNN>-<slug>.md`) so the directory becomes skimmable as the backlog grows past ~100 tickets. Compose with adopter auto-migration so plugin-developer projects (JTBD-101) consuming the windyroad ITIL framework receive an idempotent migration path on `/install-updates`. Multi-commit shape inherited from P069's L → XL re-rate after auto-migration scope addition (2026-04-20).

This RFC is the **forward-dogfood candidate** for ADR-060 Phase 1 Slice 5 per the story map at `docs/plans/170-rfc-framework-story-map.md`. Demonstrates framework correctness (architect finding 14 — captured BEFORE its first commit, run to closure under the framework). Closes the bootstrap-circularity gate.

## Driving problem trace

- **P069** (`docs/problems/069-docs-problems-flat-layout-is-unskimmable.open.md`, WSJF 1.875, Open, XL) — the flat layout is unskimmable (175+ tickets in one directory at time of capture); the per-state subdir migration must compose with adopter-tree migration so consumers don't manually re-scaffold their own `docs/problems/` trees. The L → XL re-rate on 2026-04-20 captured the auto-migration scope add — exactly the multi-commit decomposition shape this RFC framework is designed to manage.

## Scope

(deferred — populate at /wr-itil:manage-rfc accepted transition)

## Tasks

- [ ] (deferred — populate at /wr-itil:manage-rfc accepted transition)

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook per ADR-060 Phase 1 item 12; lands in Slice 3 task B5.T9)

## Related

(captured via /wr-itil:capture-rfc; expand at next /wr-itil:manage-rfc invocation)

- **P069** — driving problem ticket (WSJF 1.875, Open, XL, reported 2026-04-20)
- **P170** + **ADR-060** — RFC framework that owns this RFC's lifecycle; Slice 5 forward-dogfood validates framework correctness per architect finding 14
- **`docs/plans/170-rfc-framework-story-map.md`** Slice 5 (B8.T1-T4) — context that selected this candidate
- **JTBD-101** (plugin-developer adopter persona) — auto-migration scope serves this persona
- **JTBD-001** (extended scope, change-set-level governance) — multi-commit RFC governance is JTBD-001 territory; this RFC IS JTBD-001 dogfood
