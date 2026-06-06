---
name: wr-retrospective:migrate-briefing
description: Migrate a legacy single-file `docs/BRIEFING.md` into the per-topic `docs/briefing/` tree expected by the `wr-retrospective:run-retro` Tier-3 rotation and the SessionStart briefing surface. Idempotent and foreground-synchronous — silently no-ops when the tree is already in place or when no legacy file is present. Implements the migration path P204 left manual.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Migrate Briefing — Legacy Single-File → Per-Topic Tree

Adopters who carried a legacy monolithic `docs/BRIEFING.md` from an older `@windyroad/retrospective` release have no automation path to the per-topic `docs/briefing/` tree the current Tier-3 rotation contract (ADR-040) expects. The dual-tolerant SessionStart hook (`packages/retrospective/hooks/session-start-briefing.sh`) keeps adopters working while the legacy file remains, but per-topic-rotation only fires once the tree exists. This skill closes the loop.

See `REFERENCE.md` in this directory for the heading-extraction algorithm, slug-collision handling, code-fence-aware parsing, recovery semantics, and scope exclusions (progressive disclosure per ADR-038).

## Pattern

This skill is **foreground-synchronous** per [ADR-032](../../../../docs/decisions/032-governance-skill-invocation-patterns.proposed.md) (Governance skill invocation patterns). Migration writes files into `docs/briefing/` that the user normally wants to review before they commit — the wrapped subagent shape would defeat that review. The skill commits its own work per [ADR-014](../../../../docs/decisions/014-governance-skills-commit-their-own-work.proposed.md).

The target tree shape (per-topic files + `README.md` index + Critical Points roll-up) is defined by [ADR-040](../../../../docs/decisions/040-session-start-briefing-surface.proposed.md). This skill is the migration path INTO that shape — not a re-encoding of it.

REFERENCE.md split + the progressive-disclosure structure of this SKILL.md follows [ADR-038](../../../../docs/decisions/038-progressive-disclosure-pattern.proposed.md). Behavioural-first bats coverage follows [ADR-052](../../../../docs/decisions/052-behavioural-tests-default.proposed.md).

## Idempotency Contract

The skill MUST silently no-op in two cases:

1. **Tree already present** — `docs/briefing/README.md` exists. Re-running after a previous migration is safe and reports "already migrated; no action".
2. **No legacy file** — `docs/BRIEFING.md` does not exist (or is empty). Fresh adopters who never had a monolithic briefing get a "no legacy file found; no action" outcome.

Both no-op paths exit 0. The fixture bats asserts both directions.

## Invocation

```
/wr-retrospective:migrate-briefing [--dry-run] [--force]
```

| Flag | Effect |
|---|---|
| `--dry-run` | Print the topic slug list + per-topic file plan; no writes. |
| `--force` | Re-run even when `docs/briefing/README.md` already exists. Off by default — present tree is reported and skipped per the idempotency contract. |

## Steps

### 1. Detect inputs and short-circuit

```bash
LEGACY="docs/BRIEFING.md"
TREE_DIR="docs/briefing"
TREE_INDEX="$TREE_DIR/README.md"

if [ -f "$TREE_INDEX" ] && [ "${FORCE:-0}" != "1" ]; then
  echo "migrate-briefing: $TREE_INDEX already exists; tree already migrated (no action)."
  exit 0
fi

if [ ! -s "$LEGACY" ]; then
  echo "migrate-briefing: $LEGACY missing or empty; nothing to migrate (no action)."
  exit 0
fi
```

`-s` (non-empty file test) covers the empty-file edge case. An empty legacy stub is functionally indistinguishable from "no legacy file" — both warrant the no-op path.

### 2. Split the legacy file by H2 headings

Walk the legacy file line-by-line. Skip lines inside fenced code blocks (toggled by ` ``` ` or `~~~` at column 0) so accidental `## ` patterns inside code samples are not promoted to topic markers. Each H2 (`^## `) starts a new topic; H1 (`^# `) becomes the document preamble.

Slug derivation per heading text:
- Lowercase
- Replace non-alphanumeric runs with `-`
- Trim leading/trailing `-`
- Truncate to 60 chars
- On collision, append `-2`, `-3`, ...

Write each topic body to `docs/briefing/<slug>.md`. The preamble (everything before the first H2) goes to the index README under a "Preamble" section.

The full bash implementation ships as a script invoked via the `wr-retrospective-migrate-briefing` shim on `$PATH` per [ADR-049](../../../../docs/decisions/049-plugin-bundled-scripts-resolve-via-bin-on-path.proposed.md) (no repo-relative `packages/...` paths in shipped SKILL prose). The shim is wrapped per [ADR-080](../../../../docs/decisions/080-highest-version-wins-shim-wrapper-plugin-scaffold.proposed.md) so it resolves correctly under both source-monorepo execution and installed-cache execution:

```bash
wr-retrospective-migrate-briefing "$@"
```

See REFERENCE.md → "Heading-extraction algorithm" for the line-walker pseudocode + slug-collision worked example.

### 3. Generate the index

`docs/briefing/README.md` is written with:

- Title `# Project Briefing`.
- A short "Critical Points (Session-Start Surface)" placeholder noting the run-retro pass populates it from per-entry signal scores (ADR-040).
- A "Topic Index" table listing every generated topic file with its source-section heading text as the human label.
- A "Migrated from legacy `docs/BRIEFING.md` via `/wr-retrospective:migrate-briefing`" provenance line.

The Critical Points section is intentionally left as a placeholder. The next `/wr-retrospective:run-retro` Step 1.5 signal-vs-noise pass populates it from per-entry classifications. Pre-seeding from heading text would be lossy guesswork.

### 4. Retire the legacy file

Rename `docs/BRIEFING.md` → `docs/BRIEFING.md.migrated-<date>` so the source is preserved on disk but no longer matches the SessionStart hook's read paths. `git mv` is used so the rename stages cleanly. (Per the briefing's own `git mv + Edit + git add` note — there is no Edit in this step, so no re-stage is needed.)

### 5. Commit

One coherent commit per ADR-014:

```
chore(retrospective): migrate legacy docs/BRIEFING.md to per-topic docs/briefing/ tree
```

with a `RISK_BYPASS: legacy-briefing-migration` trailer if the project's risk-scorer pipeline flags the bulk-file-add.

## Rule 6 audit (ADR-013)

This skill emits **no** `AskUserQuestion` calls. Every decision is mechanical (idempotency detection, slug derivation, file write). Per ADR-032 + ADR-013 Rule 5, mechanical / policy-authorised stages own silent classification and MUST NOT surface consent gates (P132 inverse-P078).

If a future enhancement adds direction-setting choices (e.g. user-supplied topic-grouping), that surface routes through `AskUserQuestion` per ADR-013 Rule 1 with the 4-option cap. The non-interactive / AFK fallback is the queue-and-continue default per ADR-013 Rule 6 (P352 universal default) — never auto-decide direction-setters.

## When to invoke

- One-time during an adopter migration to `@windyroad/retrospective` ≥ the version that ships per-topic rotation.
- After a manual edit of `docs/BRIEFING.md` that the adopter wants to formally re-split (use `--force`).
- Safe to run any time — the idempotency contract guarantees no-op on already-migrated trees and on fresh repos.

## Relationship to other skills

- **Composes with** `/wr-retrospective:run-retro` — once the tree exists, Step 1.5 (signal-vs-noise pass) + Step 3 (briefing curation) operate on the per-topic files. Pre-migration, run-retro reads the legacy single file.
- **Composes with** the SessionStart hook (`session-start-briefing.sh`) — the hook silently no-ops when neither `docs/briefing/README.md` nor `docs/BRIEFING.md` is present; this skill produces the former from the latter.
- **Distinct from** `/install-updates` — that skill refreshes the plugin install cache; this skill migrates adopter artefacts on disk.

## See also

- P204 (Known Error) — the ticket this skill closes
- ADR-040 — per-topic briefing surface contract (target shape)
- ADR-038 — progressive disclosure pattern (SKILL/REFERENCE split)
- ADR-052 — behavioural tests by default
- JTBD-007 — Keep Plugins Current (adopter currency — pending amendment to extend currency scope to adopter-artefact-layout; see P204 new-jtbd-flag)
