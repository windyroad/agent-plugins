---
status: proposed
rfc-id: adr-078-phase-1-architect-on-edit-compendium-entries
reported: 2026-06-02
decision-makers: [Tom Howard]
problems: [P337]
adrs: [ADR-078, ADR-077]
jtbd: []
stories: []
---

# RFC-014: ADR-078 Phase 1 — architect-on-edit compendium entries

**Status**: proposed
**Reported**: 2026-06-02
**Problems**: P337
**ADRs**: ADR-078, ADR-077
**JTBD**: (none)

## Summary

ADR-078 Phase 1 — implement architect-on-edit LLM-authored compendium entries via PostToolUse hook + readme-pairing pre-commit hook + retire the current programmatic generator (and its drift gate + refresh-discipline hook) + cadence-driven migration of the 43 non-canonical ADRs + ADR-077 confirmation-criteria amendment.

This RFC scopes the implementation arc for the ADR-078 decision (Option 9 — architect-on-edit, ratified 2026-05-31 with `human-oversight: confirmed`). The decision itself is settled; this RFC sequences and tracks the multi-commit work that delivers it. Substance of each story is intentionally deferred — populate Scope / Tasks at `/wr-itil:manage-rfc <NNN> accepted` transition.

## Driving problem trace

- **P337** (Open) — Decisions compendium omits Decision Outcome for 57% of ADRs. The generator's `get_chosen` regex (`packages/architect/scripts/generate-decisions-compendium.sh:115`) matches only plain-prefix `Chosen option:` tags; 43/75 ADRs render with no decision content. Defeats ADR-077's load-surface goal for the majority of entries. ADR-078 Phase 1 replaces the programmatic extractor with architect-on-edit authored entries — this RFC is that replacement's delivery vehicle.

## Scope

> **DRAFT — substance pending ratification.** Story decomposition, per-story acceptance criteria, and sequencing carry **PROPOSED** status under ADR-074 / P339 substance-confirm-before-build. Substantive sub-decisions (hook trigger granularity, retirement sequencing, ADR-077 amendment shape, migration ordering, etc.) are queued as outstanding_questions for batched user surface at the next interactive transition. No implementation work is built on this RFC's contents until `/wr-itil:manage-rfc 014 accepted` runs with substance-ratified Stories A–E.

### In scope

- Implement the **PostToolUse:Edit/Write** hook + **pre-commit pairing** hook that together replace the programmatic compendium generator. The hook pair is the single mechanism that makes drift between `docs/decisions/*.md` bodies and `docs/decisions/README.md` structurally impossible (ADR-078 § "Architectural relationship between body and README under Option 9").
- Retire the programmatic generator + its drift-gate bats test + its PreToolUse refresh-discipline hook on the ADR-078 backstop schedule (see § Retirement sequencing).
- Amend ADR-077's Confirmation criteria (b), (g), (h) to reflect the move from "compendium = programmatic derivation" to "compendium = architect-authored living view".
- Cadence-driven migration: the new hook fires on every ADR body edit, so the 43 currently-non-canonical compendium entries migrate the next time each ADR is touched. **No mass backfill of the 43 entries is in scope.**
- Adopter opt-out: an `ARCHITECT_AUTO_UPDATE_COMPENDIUM=0` env var (per ADR-078 Confirmation criterion k) disables the PostToolUse hook for API-cost-sensitive adopter setups.

### Out of scope

- Mass backfill of the 43 non-canonical entries (explicitly cadence-driven per ADR-078).
- Programmatic regex-extension fix paths (ADR-078 Option 6 — user-rejected 2026-05-31; P339 lineage).
- Frontmatter `tldr:` cache (ADR-078 Option 7 — rejected).
- ADR body normalisation (ADR-078 Option 8b — rejected).
- New ADR-049 shim for the hook (the hook fires by Claude Code runtime, not via `$PATH`-resolved invocation — no shim needed).
- Story decomposition for Phase 2 (this RFC is single-phase per ADR-078).

## Anticipated story decomposition

Five stories deliver Phase 1. Story IDs are minted at `/wr-itil:manage-rfc 014 accepted` via `/wr-itil:capture-story` invocations; this RFC's `stories:` frontmatter array is refreshed at that time with the ordered execution sequence.

### Story A — Implement architect-compendium-update-entry.sh (PostToolUse hook)

- **Locus**: `packages/architect/hooks/architect-compendium-update-entry.sh` (new file).
- **Trigger**: PostToolUse matching Edit/Write events targeting `docs/decisions/*.md` (excluding `README.md`).
- **Mechanism**: hook spawns `claude -p` subprocess invoking the `wr-architect:agent` with: (1) the just-edited ADR body, (2) the current README entry for that ADR-ID (or empty string if new). The subprocess prompt instructs the architect to emit the updated compendium entry shape: `### ADR-NNN — <title>` h3 header + Status badge + Oversight badge + Supersedes link (if applicable) + `**Decides:**` line (one-or-two-sentence semantic TL;DR derived from `## Decision Outcome`) + `**Confirmation:**` line (truncated bullet join from `## Confirmation`) + `**Related:**` line (deduped ADR-ID list).
- **Application**: hook captures the architect's emit from the subprocess's JSON `.result` field; applies as `Edit` on `docs/decisions/README.md` (replacing existing entry block for that ADR-ID, or inserting in numeric-sort order under the appropriate section: in-force for `proposed` / `accepted`; historical for `superseded` / `rejected` / `deprecated`).
- **Staging**: hook stages the README change automatically so it lands in the same commit as the ADR body change.
- **Failure mode**: subprocess error (network, quota, model error) → hook logs failure + leaves README unchanged (degraded-mode-warn per ADR-078 Confirmation criterion l); subsequent commit attempt is denied by Story B's pairing check, surfacing the failure to the user for manual recovery.
- **Opt-out**: `ARCHITECT_AUTO_UPDATE_COMPENDIUM=0` (or equivalent `settings.json` key) suppresses the hook with stderr message directing the user to run `wr-architect-generate-decisions-compendium` manually.

**Acceptance criteria for Story A** (each verifiable by a bats fixture in `packages/architect/hooks/test/architect-compendium-update-entry.bats`):
1. Hook fires on Edit/Write to any `docs/decisions/*.md` body (not `README.md`).
2. Hook produces a stderr signal or log entry on every invocation (observable).
3. Hook emits the expected entry shape (h3 + Status badge + Oversight badge + Supersedes + Decides + Confirmation + Related).
4. Hook replaces existing entry in-place on ADR amendment (no duplicate entries).
5. Hook inserts entry in numeric-sort order on new ADR (correct in-force vs historical section).
6. Hook handles in-force → historical migration when an ADR transitions `accepted` → `superseded` (entry moves sections).
7. Hook subprocess failure leaves README unchanged + emits stderr; exit code does NOT block the body edit.
8. Hook opt-out via `ARCHITECT_AUTO_UPDATE_COMPENDIUM=0` self-suppresses with stderr message.
9. `packages/architect/hooks/hooks.json` registers the hook on PostToolUse:Edit + PostToolUse:Write matchers scoped to `docs/decisions/*.md` (excluding `README.md`).

### Story B — Implement architect-readme-pairing-check.sh (pre-commit hook)

- **Locus**: `packages/architect/hooks/architect-readme-pairing-check.sh` (new file).
- **Trigger**: PreToolUse:Bash matching `git commit` invocations (consistent with the existing `architect-compendium-refresh-discipline.sh` surface this hook replaces).
- **Assertion**: `git diff --cached --name-only` filtered for `docs/decisions/*.md` (excluding `README.md`) MUST be accompanied by `docs/decisions/README.md` in the same staged diff. If a commit edits any ADR body but does NOT also edit README, the hook DENIES the commit with a clear directive to re-run the edit (which would re-trigger Story A's PostToolUse hook + pair the README change).
- **Replaces**: ADR-077's Confirmation criterion (g) drift gate / bats test 2145 (Story C retires the bats; Story D retires the existing PreToolUse refresh-discipline hook). Story B is the replacement.

**Acceptance criteria for Story B** (each verifiable by a bats fixture in `packages/architect/hooks/test/architect-readme-pairing-check.bats`):
1. Hook denies commit when staged diff contains `docs/decisions/<NNN>-*.md` body change without `docs/decisions/README.md`.
2. Hook permits commit when staged diff contains both ADR body + README changes.
3. Hook permits commit when staged diff contains README change only (e.g. compendium-only edits).
4. Hook permits commit when staged diff contains no ADR-touching changes.
5. Hook denial message names the specific ADR file(s) missing pairing + the directive to re-run the edit.
6. Hook is registered in `packages/architect/hooks/hooks.json` as PreToolUse:Bash matching `git commit` (or sibling commit-shape surface).

### Story C — Retire generate-decisions-compendium.sh + bats test 2145

- **Locus**: `packages/architect/scripts/generate-decisions-compendium.sh` + `packages/architect/scripts/test/generate-decisions-compendium.bats` test 2145 (idempotency / drift gate).
- **Mechanism**: the script gains a stderr deprecation notice on every invocation citing ADR-078 (per ADR-078 Confirmation criterion j). The script remains callable as a backstop / migration tool for **one release cycle** post-Story A landing. After the backstop window (one minor-version cycle of `@windyroad/architect`), the script is removed entirely and its bats coverage retired.
- **Bats test 2145** (`committed compendium matches generator output`) is marked `skip` with a TODO referencing ADR-078's reassessment date as soon as Story A lands; the test is removed entirely with the script.
- **Backstop rationale**: gives adopters one release cycle to migrate from script-driven compendium regeneration to hook-driven. Per ADR-078 § "Architectural relationship between body and README under Option 9".

**Acceptance criteria for Story C**:
1. Script emits stderr deprecation notice on every invocation citing ADR-078 (criterion j).
2. Bats test 2145 marked `skip` with ADR-078 TODO reference.
3. Backstop window documented in `@windyroad/architect` CHANGELOG.
4. Removal commit deletes script + bats + CHANGELOG entry one minor cycle after Story A lands.

### Story D — Retire architect-compendium-refresh-discipline.sh

- **Locus**: `packages/architect/hooks/architect-compendium-refresh-discipline.sh` + its hooks.json registration + its bats fixtures.
- **Mechanism**: hook is deleted in the same commit it is removed from hooks.json; bats fixtures asserting refresh-discipline behaviour are removed. Story B's pairing-check hook is the structural replacement (every commit touching `docs/decisions/<NNN>-*.md` body must touch `docs/decisions/README.md`).
- **Gated on**: Story A landing AND Story B landing AND one session of dogfood-confirmed Story B firing correctly in this repo.
- **Rationale**: Option 9's PostToolUse hook makes drift structurally impossible at the edit boundary; the refresh-discipline PreToolUse hook becomes redundant. Keeping both runs PreToolUse twice on every commit + adds friction with no incremental safety.

**Acceptance criteria for Story D**:
1. `packages/architect/hooks/architect-compendium-refresh-discipline.sh` deleted.
2. `packages/architect/hooks/hooks.json` no longer registers the discipline hook.
3. `packages/architect/hooks/test/architect-compendium-refresh-discipline.bats` deleted.
4. One subsequent in-repo session does NOT hit drift between ADR bodies and README (Story A + B dogfood-pass).

### Story E — Amend ADR-077 confirmation criteria

- **Locus**: `docs/decisions/077-decisions-compendium-as-token-cheap-load-surface.proposed.md` § Confirmation.
- **Mechanism**: edit ADR-077 Confirmation criteria (b), (g), (h) per ADR-078 § "Architectural relationship between body and README under Option 9":
  - (b) "Generator is idempotent — two runs produce byte-identical output" → **retired**. Replace with **freshness-on-edit invariant**: every body edit triggers a same-commit README edit (Story A enforces).
  - (g) "Committed compendium matches generator output (CI drift gate)" → **retired**. Replace with **pre-commit pairing assertion** (Story B): every commit that edits a `docs/decisions/*.md` body MUST also edit `docs/decisions/README.md`.
  - (h) "Skills regenerate the compendium after writing an ADR" → **retired**. Replace with the PostToolUse hook firing automatically (Story A).
- **Order**: lands after Story A + Story B are in production (criteria reflect the as-shipped enforcement surface, not aspirational).
- **Same-commit hygiene**: this amendment is itself an ADR body edit, so per Story B it must pair with a `docs/decisions/README.md` regeneration (Story A's hook handles this automatically on commit).

**Acceptance criteria for Story E**:
1. ADR-077 § Confirmation criteria (b), (g), (h) updated to reference the as-shipped Story A / Story B enforcement.
2. `docs/decisions/README.md` ADR-077 entry refreshed via Story A's hook (validates Story A is firing correctly on dogfood).
3. ADR-077's `amended:` frontmatter field updated.

## Sequencing

Stories land in dependency order, ratified at `/wr-itil:manage-rfc 014 accepted`:

```
Story A (PostToolUse hook + claude -p subprocess + Edit application + staging)
  ↓
Story B (pre-commit pairing check) — depends on Story A's README writes being correct
  ↓
[ dogfood window — one full in-repo session must exercise Stories A + B without manual recovery ]
  ↓
Story D (retire architect-compendium-refresh-discipline.sh) — depends on Story B landing
  ↓
Story E (amend ADR-077 confirmation criteria) — depends on Stories A + B + D in production
  ↓
[ backstop window — one minor-version release cycle ]
  ↓
Story C (retire generate-decisions-compendium.sh + bats test 2145) — depends on the backstop window
```

Story C is the latest because it removes the migration tool adopters may still call during the backstop window. Story E is the formal Confirmation-criteria amendment (load-bearing for ADR-077 conformance) and lands as the second-to-last commit.

## Test and eval coverage strategy

- **Bats fixtures**: each new hook gets a `packages/architect/hooks/test/<hook-name>.bats` covering the acceptance criteria above. Behavioural (asserts on hook output / side-effects / denial messages), not structural (no grep on hook source per `feedback_behavioural_tests`).
- **Claude `-p` subprocess testing**: Story A's hook spawns a real `claude -p` invocation per the AFK iteration-worker pattern (briefing entry "AFK iteration-workers use `claude -p` subprocess dispatch"). Bats fixtures either (a) stub the subprocess with a fixed-response shim under `PATH` priority, or (b) gate on `CLAUDE_P_AVAILABLE` env var and run real-subprocess integration tests in a tagged CI lane. **Sub-decision** (queued in outstanding_questions): which testing shape is canonical.
- **Adopter-portable tests**: hook tests run from a fresh-install marketplace cache in an arbitrary adopter project root (ADR-049 / JTBD-301 promise). Fixtures must not reference `packages/architect/...` repo-relative paths.
- **Dogfood**: Phase 1 dogfoods on this same repo's `docs/decisions/` corpus — the first ratified `human-oversight: confirmed` substantive change post-Story-A landing triggers compendium update via the new hook, and Story B's pairing check catches any drift.

## JTBD anchors (per jtbd-lead verdict 2026-06-02)

- **Primary**: JTBD-001 (Enforce Governance Without Slowing Down) — the new hooks enforce compendium currency per-edit; JTBD-001's 2026-05-05 amendment explicitly covers "multi-commit coordinated changes governed at the change-set level".
- **Secondary**: JTBD-008 (Decompose a Fix Into Coordinated Changes) — RFC-014 IS the decomposition vehicle for Phase 1.
- **Tertiary** (optional): JTBD-002 (Ship AI-Assisted Code with Confidence) — compendium currency contributes to decision-load confidence per ADR-077.

Populate `jtbd: [JTBD-001, JTBD-008]` at `/wr-itil:manage-rfc 014 accepted`; consider JTBD-002 if tertiary anchoring is desired.

## Tasks

- [ ] **Story A** — Implement `packages/architect/hooks/architect-compendium-update-entry.sh` + `packages/architect/hooks/test/architect-compendium-update-entry.bats` + register in `packages/architect/hooks/hooks.json` (PostToolUse:Edit + PostToolUse:Write on `docs/decisions/*.md` excluding `README.md`). Acceptance criteria 1–9 above.
- [ ] **Story B** — Implement `packages/architect/hooks/architect-readme-pairing-check.sh` + `packages/architect/hooks/test/architect-readme-pairing-check.bats` + register in `packages/architect/hooks/hooks.json` (PreToolUse:Bash on `git commit`). Acceptance criteria 1–6 above.
- [ ] **Dogfood window** — one full in-repo session exercising Stories A + B without manual recovery. Document on the RFC's commit trail.
- [ ] **Story D** — Delete `packages/architect/hooks/architect-compendium-refresh-discipline.sh` + remove from `hooks.json` + remove `packages/architect/hooks/test/architect-compendium-refresh-discipline.bats`. Acceptance criteria 1–4 above.
- [ ] **Story E** — Amend ADR-077 Confirmation criteria (b), (g), (h) + bump `amended:` frontmatter. Acceptance criteria 1–3 above.
- [ ] **Backstop window** — one minor-version release cycle of `@windyroad/architect` with Stories A + B in production.
- [ ] **Story C** — Add stderr deprecation notice to `packages/architect/scripts/generate-decisions-compendium.sh` + mark bats test 2145 `skip` + (post-backstop) delete script + bats + CHANGELOG entry. Acceptance criteria 1–4 above.

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook per ADR-060 Phase 1 item 12)

## Related

(captured via /wr-itil:capture-rfc; expand at next /wr-itil:manage-rfc invocation)

- **P337** — driving problem ticket; § Fix Strategy enumerates the 5-story anticipated decomposition.
- **ADR-078** — ratified architectural decision (Option 9, human-oversight: confirmed 2026-05-31); this RFC is its delivery vehicle.
- **ADR-077** — the compendium ADR; confirmation criteria (b), (g), (h) scheduled for amendment in Story E.
- **ADR-060** — Problem-RFC-Story framework; this RFC scopes a multi-commit fix per JTBD-008.
- **P339** — substance-confirm-before-build prior occurrence on the same ADR-078 (lineage; informs how this RFC's stories should land — each at architect-confirmed substance before implementation).
