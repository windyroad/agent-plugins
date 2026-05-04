---
name: wr-risk-scorer:bootstrap-catalog
description: Bootstrap docs/risks/ standing-risk catalog from existing .risk-reports/ corpus. Walks reports, dedupes by ADR-056 slug, emits one R<NNN>-<slug>.active.md per unique slug with ## Source Evidence block citing originating reports. Idempotent — re-runs are no-ops by file-existence per slug. One-shot per project lifetime; install-updates Step 6.5 auto-triggers when catalog is empty AND .risk-reports/ is non-empty AND RISK-POLICY.md is present.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
maturity: proposed
---

# Risk Catalog Bootstrap

Walk the project's `.risk-reports/*.md` corpus, dedupe by ADR-056 risk-slug, and emit one `R<NNN>-<slug>.active.md` register entry per unique slug with a `## Source Evidence` block citing originating reports. This is the **one-shot historical backfill** that Phase 3 of ADR-047's roadmap deferred — now landed via ADR-059.

This skill is the on-demand surface (per ADR-059 verdict A4). The auto-trigger surface (per ADR-059 verdict A6) is `/install-updates` Step 6.5, which invokes this skill when the catalog is empty AND `.risk-reports/` is non-empty AND `RISK-POLICY.md` is present. Both surfaces resolve to this skill's runtime contract.

## When to invoke

- **First-time setup**: project has accumulated `.risk-reports/` reports but `docs/risks/` is empty (only `README.md` + `TEMPLATE.md` from ADR-047 Phase 1 scaffold). Bootstrap populates the register from the historical corpus.
- **After a wipe**: per ADR-059 verdict I2 two-pass validation, the wipe pass retires R001-R006 then re-runs this skill on the empty catalog.
- **NOT for incremental updates**: new risk classes detected during per-action assessments flow through ADR-056 hint-and-drain (`RISK_REGISTER_HINT:` → queue → consumer-skill drain → `/wr-risk-scorer:create-risk --slug --prefill`). Re-running this skill on a populated catalog appends to existing source-evidence blocks but does NOT fire for new slugs (those are the hint-and-drain path's job).

## Pre-conditions

Verify before running:

1. `RISK-POLICY.md` is present at the repo root. If absent, the project hasn't opted into the catalog framing — exit cleanly with a one-line message ("RISK-POLICY.md not found; bootstrap not applicable. Run /wr-risk-scorer:update-policy first.") and do not write anything.
2. `docs/risks/` directory exists with `README.md` + `TEMPLATE.md` (ADR-047 Phase 1 scaffold). If absent, exit cleanly with a one-line message ("docs/risks/ scaffold not found; run /install-updates to scaffold first.") and do not write anything.
3. `.risk-reports/` directory exists and contains at least one `*.md` file. If empty or absent, exit cleanly with a one-line message ("No .risk-reports/ corpus to walk; bootstrap is a no-op.") and do not write anything.

## Steps

### 1. Walk the report corpus

Glob `.risk-reports/*.md`. Read each report. For each report, parse the `RISK_REGISTER_HINT:` block (if present per ADR-056 3-column format `<reason-tag> | <slug> | <prefill>`). If the block is absent (older reports pre-ADR-056), parse risk-item descriptions from the report body and derive slugs per ADR-056's slug-computation rules (lowercase, kebab, drop articles, ≤60 chars, word-boundary truncation).

Record per slug:
- `slug` (ADR-056 risk-slug — the dedupe key).
- `originating_reports` — list of `.risk-reports/<filename>.md` paths where this slug surfaced.
- `prefill` — first non-empty prose prefill seen for this slug (carried into Description field).
- `reason_tag` — first non-empty reason-tag seen (`above-appetite-residual`, `confidentiality-disclosure`, or `user-stated-precondition` per ADR-056 reserved vocabulary).

### 2. Dedupe by slug

Group all surfaced risk-mentions by slug. N reports producing the same slug collapse to ONE register entry; the entry's `## Source Evidence` block cites all N originating reports per ADR-026 grounding (provenance is load-bearing per ADR-059 verdict D).

### 3. Compute next R<NNN> IDs

Per ADR-019 dual-source ID contract:
- Local-max: `ls docs/risks/R*.active.md docs/risks/R*.retired.md 2>/dev/null | grep -oE '^R[0-9]+'` → max numeric.
- Origin-max: `git ls-tree --name-only origin/main docs/risks/ | grep -oE '^R[0-9]+'` → max numeric (per P056 `--name-only` requirement to avoid false-matching on blob SHAs).
- Next R<NNN> = max(local, origin) + 1, allocated sequentially across N unique slugs.

Allocate IDs deterministically: sort slugs alphabetically before assigning IDs so re-runs on the same corpus produce stable IDs (within a single bootstrap pass; across bootstrap passes, IDs are not stable because new reports may surface in between — that's by design).

### 4. Idempotency check (per-slug)

For each unique slug, glob `docs/risks/R*-<slug>.active.md`:
- **No match**: this slug is new — proceed to write a new register entry (Step 5).
- **Match exists**: this slug already has a register entry — append the originating reports to its `## Source Evidence` block instead of creating a new file (Step 6). Preserves human-curated content in existing entries.

This is the idempotency primitive. Re-running the skill on a populated catalog is a no-op for the slugs already present; new slugs get new entries.

### 5. Write new register entries

For each new slug, write `docs/risks/R<NNN>-<slug>.active.md` from `docs/risks/TEMPLATE.md` shape with these field values:

- **Status**: `Active (auto-scaffolded — pending review)` per ADR-056 pending-review pattern.
- **Category**: heuristic-derive from the reason-tag — `confidentiality-disclosure` → `infosec`; `above-appetite-residual` / `user-stated-precondition` → `operational` unless the slug strongly suggests another category. If ambiguous, default to `operational` and let curation review re-categorise.
- **Identified**: today's date.
- **Owner**: `pending review` (defer to human curation).
- **Last reviewed**: today's date.
- **Next review**: 6 months from today.
- **Description**: prefill verbatim. Single line; do NOT generate prose.
- **Inherent Risk** fields (Impact / Likelihood / Score / Band): ALL emit ADR-026 sentinel `not estimated — no prior data`. Numeric defaults of `0` or `Low` would falsely look human-affirmed and violate JTBD-201 audit-trail integrity.
- **Controls**: empty list. Controls are project-specific and pending human curation.
- **Residual Risk** fields: same ADR-026 sentinel as Inherent.
- **Within appetite?**: `pending — scoring not estimated`.
- **Treatment**: `pending review`.

Append a `## Source Evidence` block in the format ADR-059 verdict D specifies:

```markdown
## Source Evidence (bootstrap-derived YYYY-MM-DD)

Aggregated from N `.risk-reports/` entries (slug: `<risk-slug>`):
- `.risk-reports/<filename>.md`
- `.risk-reports/<filename>.md`
...

Re-rate when new reports surface against this slug or when controls change.
```

**Curation marker** — append also `**Curation**: pending review (auto-scaffolded YYYY-MM-DD)` immediately after the file's frontmatter so downstream curation tooling (`/wr-risk-scorer:review-register` future skill — out of scope ADR-059) can grep for pending-review entries deterministically.

### 6. Append to existing entries (slug collision)

For each slug whose `docs/risks/R*-<slug>.active.md` already exists, locate the existing `## Source Evidence` block (if present). Append the originating reports to the bullet list. If the block is absent (existing entry is hand-authored without Source Evidence), append a new `## Source Evidence (bootstrap-derived YYYY-MM-DD)` block at the end of the file.

Do NOT modify any other field of an existing entry. The existing entry's Status / scoring / controls / treatment are human-curated; bootstrap only adds provenance.

### 7. Update `docs/risks/README.md` Register table

Append one row per new `R<NNN>` entry to the Register table. Use em-dash (`—`) for stub scoring fields (Inherent Score, Inherent Band, Residual Score, Residual Band, Within appetite?). Treatment column = `pending review`. Owner column = `pending review`.

Row shape:

```markdown
| R<NNN> | <Title> | <Category> | — | — | — | — | — | pending review | pending review |
```

The Title is derived from the slug (kebab → Title Case). Category per Step 5 heuristic. Em-dashes per ADR-026 sentinel display contract (numeric defaults would falsely look human-affirmed).

For slug-collision entries (Step 6), do NOT modify the README row — the row already exists for the existing R<NNN>.

### 8. Stage and commit

`git add docs/risks/` (covers all new entries + README update + Source Evidence appends).

Per ADR-014 single-commit grain, commit message:

```
feat(risks): bootstrap register from .risk-reports/ corpus (<N> new entries, <M> existing updates)

Bootstrapped <N> new R<NNN>-<slug>.active.md entries from <K>
.risk-reports/ files clustering into <N> unique slugs per ADR-056
slug rules. Appended source-evidence to <M> existing entries
(slug collision). All new entries marked Status: Active
(auto-scaffolded — pending review) with ADR-026 sentinel
'not estimated — no prior data' for ungrounded scoring fields.

Refs: ADR-059 (this skill's design), ADR-056 (slug primitive),
ADR-026 (grounding sentinel), ADR-047 (Phase 1 directory scaffold
parent), P168 (driver).
```

The commit goes through architect / JTBD / risk-scorer review per ADR-014. Per ADR-013 Rule 5, the bootstrap action is policy-authorised silent proceed — no `AskUserQuestion` round-trip needed; the catalog framing in `RISK-POLICY.md` IS the policy authorisation, and the skill's pre-conditions (Step 0) verify the project opted in.

### 9. Report

Print a one-screen summary:

```
Risk register bootstrap complete.

  Walked:    <K> .risk-reports/ files
  Slugs:     <T> unique slugs
  New:       <N> R<NNN>-<slug>.active.md entries
  Appended:  <M> existing entries gained source-evidence
  Skipped:   <S> reports without parseable hints (pre-ADR-056 format)

  Next steps:
  - Curate auto-scaffolded entries: review Status, scoring, controls.
  - Run /wr-risk-scorer:assess-wip to verify per-action assessments
    consume the new catalog (look for Catalog match: lines).
```

The report is consumed by `/install-updates` Step 6.5 when the auto-trigger surface invokes this skill (the Step 7 final-report integration shows the bootstrap row with these counts — JTBD-007 transparency).

## Idempotency contract

Re-invoking this skill on a populated catalog:

- For slugs ALREADY present: the existing entry's `## Source Evidence` block gains appended reports (Step 6). NO other field changes. Re-run produces zero diff if the same `.risk-reports/` corpus is processed twice.
- For slugs NOT yet present: a new register entry is written (Step 5). This handles the case where new `.risk-reports/` files have been added since the last bootstrap.
- ID stability: bootstrap-pass-N IDs are stable WITHIN a single pass. Across passes, new slugs may interleave with existing IDs; that's by design (the catalog grows monotonically).

The skill is safe to invoke at any time. Pre-condition checks (Step 0) prevent it from running when the project hasn't opted into the catalog framing (no `RISK-POLICY.md`) or when there's nothing to bootstrap (no `.risk-reports/`).

## ADR alignment

- **ADR-059** — this skill's design ADR. Covers verdicts A4 (on-demand surface), B1 (slug dedupe), C1 (no threshold), D1 (Source Evidence required), G (skill ownership).
- **ADR-056** — slug primitive consumed verbatim. Slug rules in `pipeline.md` lines 207-220 are the authority.
- **ADR-026** — grounding sentinel for ungrounded scoring fields. `not estimated — no prior data` per the sentinel pattern.
- **ADR-047** — parent ADR (Phase 1 directory scaffold). This skill is Phase 3 of ADR-047's roadmap; ADR-047's `## Out of scope` carries a forward pointer to ADR-059.
- **ADR-014** — single-commit grain. Bootstrap commits as one unit per skill invocation.
- **ADR-013 Rule 5** — policy-authorised silent proceed. Catalog framing in `RISK-POLICY.md` IS the policy.
- **ADR-019** — dual-source ID allocation (local-max + origin-max + 1).
- **ADR-038** — progressive disclosure; this SKILL.md is the runtime contract; REFERENCE.md (sibling file) carries deeper context.
- **ADR-049** — plugin-bundled scripts via `bin/` on `$PATH`. Helper scripts (e.g. slug-derivation; report walker) ride `packages/risk-scorer/scripts/` with `bin/` shims.
- **ADR-053** — plugin maturity taxonomy. This skill ships with `maturity: proposed` per the taxonomy; promote to `accepted` after the first successful bootstrap on an adopter project.

## Related

- **P168** — driver ticket. Closes the missed-risk-class hazard (catalog absence).
- **P167** — parent ticket. Corrected the policy framing this skill implements at runtime.
- **P033** — original 99%-miss-rate ticket; this skill is part of the multi-phase fix alongside ADR-047 Phase 1 + ADR-056 Phase 2a.
- **`docs/risks/TEMPLATE.md`** — template source for new entries.
- **`docs/risks/README.md`** — register index; updated by Step 7.
- **`.risk-reports/`** — corpus walked by Step 1.
- **`packages/risk-scorer/agents/pipeline.md`** — consume-catalog protocol consumes the entries this skill writes.
- **`/wr-risk-scorer:create-risk`** — sibling skill for hand-authored entries; flag-driven path (`--slug` / `--prefill`) shares the auto-scaffolded entry shape this skill emits.
- **`/install-updates` Step 6.5** — auto-trigger surface that invokes this skill when pre-conditions match.
