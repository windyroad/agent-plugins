---
status: proposed
job-id: migrate-adopter-artefacts
persona: developer
date-created: 2026-06-07
human-oversight: confirmed
oversight-date: 2026-06-07
---

# JTBD-009: Migrate Adopter Artefacts When a Plugin Layout Evolves

## Job Statement

When a `@windyroad/*` plugin I depend on evolves its expected on-disk layout (e.g. legacy single-file `docs/BRIEFING.md` → per-topic `docs/briefing/` tree), I want a one-command, idempotent migration that brings my existing adopter artefacts into the new layout, so I keep getting the plugin's full value (per-topic rotation, surface-specific signals, future layout-aware behaviour) without hand-splitting files or leaving stale artefacts that the dual-tolerant fallback silently downgrades.

## Desired Outcomes

- **One command, idempotent.** A single `/wr-<plugin>:migrate-<artefact>` skill walks my adopter artefacts from the old layout to the new one. Re-running after a previous migration is a silent no-op; running before any legacy file exists is a silent no-op. I never have to remember "did I migrate this project yet?".
- **Dual-tolerant fallback is a bridge, not a destination.** When a plugin ships a layout change, the read-path hook stays dual-tolerant so I keep working — but a migration command closes the loop so I actually get the new shape's full behaviour (per-topic rotation, finer-grained currency signals, etc.) rather than living indefinitely on the legacy read-path.
- **Foreground-synchronous + self-committed** per [ADR-032](../../decisions/032-governance-skill-invocation-patterns.proposed.md) and [ADR-014](../../decisions/014-governance-skills-commit-their-own-work.proposed.md). I review the rewritten artefacts before they ship — the migration commits its own work in one coherent commit, traceable to the driving problem and the originating layout-evolution ADR.
- **Legacy preserved on disk, retired from read paths.** The migration renames the legacy artefact (e.g. `docs/BRIEFING.md` → `docs/BRIEFING.md.migrated-<date>`) rather than deleting it — the source is preserved for audit + recovery while no longer matching the plugin's read paths.
- **Scoped to layout-evolution, not content-currency.** This job is about the artefact's **structural shape** (one file vs. many; flat vs. nested; legacy filename vs. new directory) — distinct from [JTBD-007](JTBD-007-keep-plugins-current.proposed.md)'s code-currency + README-content-currency scope. The user ratified this scope split on 2026-06-07 (P204 Q1) — adding a new job rather than extending JTBD-007 a third time.
- **Composes with the plugin distribution model.** The skill ships **inside** the evolving plugin so adopters get the migration path on the same `npm install` that brings the layout change — no separate tooling install, no version skew between layout and migration.

## Persona Constraints

- **Works across multiple related projects.** A layout evolution that lands in one upstream release fans out to every project that has the plugin installed. The migration cost is per-project; the cognitive cost of remembering which projects still need migration is per-developer-per-release.
- **Expects the agent to handle the mechanics.** After a release that ships a layout change, the developer wants `/wr-<plugin>:migrate-<artefact>` to do the structural rewrite, leaving them to review and commit — not to hand-split, hand-slugify, or hand-stage.
- **Trusts idempotency over coordination.** Running the migration speculatively (already migrated? not yet? unsure?) is cheaper than tracking per-project migration state. Idempotency is what makes the speculative invocation safe — and what makes the skill safe to wire into bootstrap / install flows.
- **No source archaeology expected.** The developer does not read the plugin's source to understand the new layout. The migration encodes the layout contract in executable form (the rewrite logic IS the spec) so the contract is invokable, not just documented.

## Current Solutions

- **Manual hand-split.** Walk the legacy file, split by section headings, write per-topic files, generate an index, retire the legacy file. Error-prone, tedious, and asymmetric across projects (every adopter does the same work).
- **Indefinite dual-tolerant fallback.** Lean on the plugin's read-path hook tolerating both layouts forever. Works until the plugin ships a layout-only feature (per-topic rotation, surface-specific signals) that the legacy shape can't carry — at which point adopters get the silent downgrade without realising it.
- **Per-plugin bespoke migration script.** Author a one-off script per evolution. Doesn't compose — every layout change re-invents the same idempotency contract, the same legacy-preservation pattern, the same single-commit shape.

## Current realisation

- **`/wr-retrospective:migrate-briefing`** (shipped 2026-06-06 via P204) is the first instance of this job pattern — legacy `docs/BRIEFING.md` → per-topic `docs/briefing/` tree migration. The skill ships in `packages/retrospective/skills/migrate-briefing/`, ADR-anchored (032/014/038/040/049/052/080), with 27 behavioural + contract bats covering both idempotency directions, slug-collision, code-fence-aware parsing, `--dry-run`, and `--force`. It is the trace target for this JTBD's first concrete realisation.

## Related decisions

- **[ADR-040](../../decisions/040-session-start-briefing-surface.proposed.md)** — defines the per-topic briefing surface that this JTBD's first realisation (`migrate-briefing`) migrates **into**. The layout evolution that surfaced the job pattern.
- **[ADR-032](../../decisions/032-governance-skill-invocation-patterns.proposed.md)** — foreground-synchronous skill invocation. Required for migrations because the developer wants to review the rewrite before it ships.
- **[ADR-014](../../decisions/014-governance-skills-commit-their-own-work.proposed.md)** — governance skills commit their own work. Migrations are one coherent commit traceable to the driving problem.
- **[ADR-038](../../decisions/038-progressive-disclosure-pattern.proposed.md)** — SKILL/REFERENCE split. Migration skills carry rewrite-algorithm + slug-collision + code-fence rules in REFERENCE.md, contract surface in SKILL.md.
- **[ADR-049](../../decisions/049-plugin-bundled-scripts-on-path.proposed.md)** + **[ADR-080](../../decisions/080-plugin-bundled-scripts-on-path-shim.proposed.md)** — migration scripts invoked via PATH shims so they resolve in adopter installs, not just the source monorepo. (Recurring class P151/P153/P219/P317.)
- **[ADR-052](../../decisions/052-behavioural-tests-default.proposed.md)** — behavioural-first bats coverage for the migration's idempotency contract.

## Related JTBDs

- **[JTBD-007](JTBD-007-keep-plugins-current.proposed.md)** — Keep Plugins Current Across Projects. Sibling on the same developer persona; covers code-currency + README-content-currency + maturity-band-currency. JTBD-009 covers the **adopter-artefact-layout-currency** dimension the user explicitly carved out as a separate job rather than extending JTBD-007 a third time (P204 Q1, ratified 2026-06-07).
- **[JTBD-101](../plugin-developer/JTBD-101-extend-suite.proposed.md)** — Extend the Suite with New Plugins. Plugin-developer's side of the same evolution: when a plugin developer evolves a layout, JTBD-101 covers the design-side (deliver the new shape + ship the migration skill alongside it); JTBD-009 covers the adopter-developer's side (run the migration, get the new shape, keep working).

## Related problems

- **P204** (`docs/problems/verifying/204-...md`) — driver. *"No `/wr-retrospective:migrate-briefing` skill — legacy `docs/BRIEFING.md` → `docs/briefing/` tree migration is manual."* Q1 of P204 (amend JTBD-007 vs. add JTBD-009) was ratified on 2026-06-07 in favour of adding this job. The shipped migrate-briefing skill is this JTBD's first concrete realisation.
