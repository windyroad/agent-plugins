---
status: proposed
job-id: migrate-adopter-artefacts
persona: developer
date-created: 2026-06-07
human-oversight: confirmed
oversight-confirmed-date: "2026-08-21 — re-ratified via AskUserQuestion alongside ADR-119. Amendment confirmed: a stop-growing evolution has no migration command and dual-tolerant reading is its destination rather than a bridge; the obligation moves to the release notes, which must say plainly that no migration exists and none is coming."
oversight-date: 2026-07-30
oversight-confirmed-date-prior: "2026-06-07 — original ratification (P204 Q1): the adopter-artefact-layout-currency scope split, distinct from JTBD-007's code-currency and README-content-currency. 2026-07-30 — re-ratified via AskUserQuestion after three Desired Outcomes were amended; the maintainer was shown each amendment and what it changed, and confirmed the amended version."
oversight-note: "Amended 2026-07-29/30 and re-confirmed: (1) the migration carrier may be a PATH shim rather than a skill when there is no decision to govern, with the obligation that release notes then carry the invocation since a shim does not surface in autocomplete; (2) legacy-artefact preservation is conditional on the artefact not being recoverable from git, because for an intra-file edit a retained duplicate would share a story-id and drift both copies; (3) scope covers an artefact's intra-file contract, not only its structural shape. All three record behaviour the repo had already adopted — the job text had drifted behind its own realisations."
---

# JTBD-009: Migrate Adopter Artefacts When a Plugin Layout Evolves

## Job Statement

When a `@windyroad/*` plugin I depend on evolves its expected on-disk layout (e.g. legacy single-file `docs/BRIEFING.md` → per-topic `docs/briefing/` tree), I want a one-command, idempotent migration that brings my existing adopter artefacts into the new layout, so I keep getting the plugin's full value (per-topic rotation, surface-specific signals, future layout-aware behaviour) without hand-splitting files or leaving stale artefacts that the dual-tolerant fallback silently downgrades.

## Desired Outcomes

- **One command, idempotent.** A single invocation walks my adopter artefacts from the old layout to the new one. Re-running after a previous migration is a silent no-op; running before any legacy file exists is a silent no-op. I never have to remember "did I migrate this project yet?". The carrier is a `/wr-<plugin>:migrate-<artefact>` **skill when the migration has a decision to govern** — a choice to surface, an interactive branch, an artefact I must review mid-flight. When it has none, a `wr-<plugin>-migrate-<artefact>` PATH shim is the correct carrier and a skill wrapper is ceremony with nothing to govern; in that case the release notes MUST carry the invocation, because a shim does not surface in autocomplete. *(Amended 2026-07-29 — one wrapper-less migration (`wr-itil-migrate-problems-layout`) had already shipped against this job and went unrecorded here, while this outcome's text named only the skill shape; a second (`wr-itil-migrate-story-status-mirror`) lands with the same change that adds this clause. The amendment rests on the one prior departure, not on the change requesting it.)*
- **Dual-tolerant fallback is a bridge, not a destination — except where there is no destination.** When a plugin ships a layout change, the read-path hook stays dual-tolerant so I keep working — but a migration command closes the loop so I actually get the new shape's full behaviour (per-topic rotation, finer-grained currency signals, etc.) rather than living indefinitely on the legacy read-path.

  *(Amended 2026-08-21, ADR-119 lockstep.)* A third shape exists that neither carrier above fits: a **stop-growing evolution**, where the old artefact type simply stops being created and existing ones are never rewritten. ADR-119 is the first — a fix proposal becomes a release row rather than a document, and the 60 existing documents keep their derived sections, keep resolving, and convert one at a time only as their own problem is next worked.

  For this shape there is **nothing for a migration command to transform**, so shipping one would be the ceremony the One-command outcome above rejects. Dual-tolerant reading is therefore the destination rather than a bridge, and indefinitely so by design. Critically, *"did I migrate this project yet?"* stops being a question I can be behind on — not because I am told to stop worrying, but because there is no migration to be behind on. The obligation this job protects is preserved in a different place: the release notes MUST name the evolution and say plainly that no migration command exists and none is coming, so silence is never mistaken for an unshipped tool.
- **Foreground-synchronous + self-committed** per [ADR-032](../../decisions/032-governance-skill-invocation-patterns.proposed.md) and [ADR-014](../../decisions/014-governance-skills-commit-their-own-work.proposed.md). I review the rewritten artefacts before they ship — the migration commits its own work in one coherent commit, traceable to the driving problem and the originating layout-evolution ADR.
- **Legacy preserved on disk when it is not otherwise recoverable, retired from read paths.** Where the migration replaces a whole artefact, it renames the legacy file (e.g. `docs/BRIEFING.md` → `docs/BRIEFING.md.migrated-<date>`) rather than deleting it, so the source survives for audit and recovery while no longer matching the plugin's read paths. Where the migration edits *within* an artefact, preservation is satisfied by git history and an on-disk duplicate is wrong, not merely redundant: two files carrying the same `story-id` would both be fingerprinted and both drift. *(Amended 2026-07-29.)*
- **Scoped to layout-evolution, not content-currency.** This job is about the artefact's **shape** rather than its content — including its **structure** (one file vs. many; flat vs. nested; legacy filename vs. new directory) and its **intra-file contract** (a field the plugin no longer expects; a body line the plugin's own tooling now reads differently). The three structural cases are illustrations of the carve-out, not an exhaustive test. What is excluded is [JTBD-007](JTBD-007-keep-plugins-current.proposed.md)'s code-currency + README-content-currency scope. The user ratified this scope split on 2026-06-07 (P204 Q1) — adding a new job rather than extending JTBD-007 a third time; the intra-file clarification was added 2026-07-29 when a story-file contract migration proved to be neither structural-shape nor content-currency, and so had no home under the narrower reading.
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

Three realisations exist in two carrier shapes — two shipped, one landing with this change. The skill shape is **not** the only one, which is why the One-command outcome above was amended on 2026-07-29 to admit both.

- **`wr-itil-migrate-problems-layout`** — a wrapper-less PATH-shimmed migration with no skill surface, and the one prior departure this amendment rests on. It predates the 2026-07-29 amendment and went unrecorded here, which is how this job's text came to assert a shape the repo had already left behind. (`packages/itil/scripts/migrate-problems-add-type.sh` is a candidate second prior but has no PATH shim, so it is unreachable by adopters and fails this outcome's own carrier test — it is not counted.)
- **`wr-itil-migrate-story-status-mirror`** (2026-07-29 via P474 / RFC-059) — removes the `**Status**:` body line duplicating a story's frontmatter `status:`, and re-points each artefact's oversight fingerprint without ever writing `human-oversight`. Wrapper-less by the amended outcome's test: it takes no decisions and has no interactive branch. Idempotent; reports every artefact it touches; skips and reports any artefact whose body line disagrees with its frontmatter rather than deleting content it cannot prove redundant.
- **`/wr-retrospective:migrate-briefing`** (shipped 2026-06-06 via P204) is the first *skill*-shaped instance of this job pattern — legacy `docs/BRIEFING.md` → per-topic `docs/briefing/` tree migration. The skill ships in `packages/retrospective/skills/migrate-briefing/`, ADR-anchored (032/014/038/040/049/052/080), with 27 behavioural + contract bats covering both idempotency directions, slug-collision, code-fence-aware parsing, `--dry-run`, and `--force`. It is the trace target for this JTBD's first concrete realisation.

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


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-054 | STORY-054: Lifecycle transitions preserve a story's ratification | accepted |
