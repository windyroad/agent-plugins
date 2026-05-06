---
status: verifying
rfc-id: pipeline-consume-catalog-and-bootstrap-from-reports
reported: 2026-05-06
decision-makers: [Tom Howard]
problems: [P168]
adrs: [ADR-059]
jtbd: []
---

# RFC-001: Pipeline consume-catalog and bootstrap-from-reports — multi-commit retrofit

**Status**: verifying
**Reported**: 2026-05-06 (retroactive — work shipped 2026-05-04)
**Problems**: P168
**ADRs**: ADR-059
**JTBD**: (none directly anchored — P168 itself anchors JTBD-001 / JTBD-006 / JTBD-202; this RFC inherits transitively without re-anchoring)

## Summary

RFC-001 is the **retrospective migration of P168** into the RFC framework — the first dogfood pass per ADR-060 Phase 1 item 9 + Slice 4 of `docs/plans/170-rfc-framework-story-map.md`. It captures the multi-commit coordinated change that promoted ADR-047 Phase 2 (consume-catalog) and Phase 3 (bootstrap-from-reports) of the standing-risk register from "deferred" to shipped, addressing the missed-risk-class hazard surfaced by P167 / P168 (risk-scorer agent regenerated risk classes from scratch on every per-action assessment).

The work landed across three coordinated commits + one deferred sub-commit, all under ADR-059 ("Pipeline consume-catalog and bootstrap-from-reports for the standing-risk register"):

| # | Commit | Scope |
|---|--------|-------|
| 1 | `ab73328` | Pipeline consume-catalog protocol + create-risk `--slug` / `--prefill` flag-driven path + 30 bats |
| 2 | `af5447c` | Bootstrap-catalog skill + install-updates Step 6.5.1 auto-trigger + 29 bats |
| 3 | `8edaf7b` | Wipe R001-R006 + extractor script + 17 bats + first bootstrap-derived entry (R007) |
| 3' | (deferred) | Heuristic-slug derivation for pre-ADR-056 reports — see `## Deferred Scope` |

This RFC is authored at `verifying` status directly — see `## Lifecycle Provenance` below.

## Lifecycle Provenance

This RFC is a **retrospective migration of completed work** captured under the pre-RFC framework. The proposed → accepted → in-progress → verifying lifecycle states were collapsed into a single authoring event because the work had already shipped (commits ab73328, af5447c, 8edaf7b landed 2026-05-04) before the RFC framework existed (Slices 1-3 of P170, completed 2026-05-05/06).

**Retro carve-out authority**:

- **Framework-level**: ADR-060 Phase 1 item 9 + § Confirmation criterion 5 explicitly contemplate retroactive migration of P168 as the Phase 1 dogfood pass. The bounded-escape carve-out at `/wr-itil:capture-rfc` Step 2 (`packages/itil/skills/capture-rfc/SKILL.md` lines 113-120) acknowledges this case at the framework level: Verifying problem-traces pass with advisory note; Closed/Parked traces pass with advisory-warn — the carve-out is "load-bearing for the Phase 1 dogfood pass".
- **Skill-level bypass**: `/wr-itil:capture-rfc` is a forward-capture surface (writes only `.proposed.md`, single-commit, skeleton-then-defer). Authoring a retro RFC at `.verifying.md` directly is outside that contract. This RFC was authored manually — read against the framework primitives (`docs/rfcs/README.md` body shape spec) but bypassing `capture-rfc` because the skill doesn't model the retro-as-completed-work shape. **No deny-log entry is generated** because the bypass is not a denial (architect-review verdict 2026-05-06: "in-RFC record is sufficient"). The trace-violation-rate measurement at `logs/rfc-capture-denials.jsonl` (ADR-060 § Reassessment criterion) measures forward-capture denials, not retro-authoring bypasses.
- **Atomicity gate untouched**: per ADR-060 § Confirmation criterion 6, ADR-042 auto-apply remains paused until RFC-001 reaches `closed`. Authoring at `.verifying.md` does NOT graduate the held-changeset window. Closure follows the forward-dogfood gate (architect finding 14 + § Confirmation criterion 9).

This provenance block satisfies architect-review finding 2 (2026-05-06): a future reader sees a `.verifying.md` RFC with no proposed/accepted/in-progress audit trail and is owed an in-file explanation. Round-trip retrievability (criterion 5(f)) survives.

## Driving problem trace

**P168** (`docs/problems/168-risk-scorer-doesnt-consume-catalog-or-bootstrap.verifying.md`, status `.verifying.md` preserved per § Confirmation criterion 5(d)):

The risk-scorer agent (`packages/risk-scorer/agents/pipeline.md`) emits `RISK_SCORES:` + `RISK_REGISTER_HINT:` on every per-action assessment but **does NOT read `docs/risks/` to consume the catalog** and **does NOT bootstrap the catalog from `.risk-reports/`**. Operationally functional but with two latent hazards: (1) the **missed-risk-class hazard** — agent omits a class that would surface from a populated catalog → wrong gate verdict → governance step skipped; (2) wasted-effort cost — agent regenerates risk classes from scratch on every per-action assessment, blowing the JTBD-001 60-second budget.

ADR-047 Phase 2 (back-channel: pipeline writes new entries when reports identify register-worthy risks) and Phase 3 (one-time backfill from `.risk-reports/` corpus) had been deferred for "architect-design depth (autonomy boundary, dedupe-by-risk-name, evidence-log appending, marker-driven backfill gating)". P168 is the substantive design + implementation ticket that promoted both phases through architect verdict + JTBD verdict + 3-commit shipping shape.

## Underpinning ADR trace

**ADR-059** (`docs/decisions/059-pipeline-consume-catalog-and-bootstrap-from-reports.proposed.md`, status `.proposed.md` preserved):

ADR-059 captures the substantive design space: hybrid filter (slug-token-match primary, free-form judgement fallback), residual reconciliation, ADR-056 slug as dedupe primitive, two-pass validation timing, auto-write at orchestrator-side preserving pure-scorer contract, install-updates Phase 3 ride. Architect verdicts B/C/D/E/F/G + JTBD verdicts J1-J6 are all recorded in the ADR's body. The RFC layer here adds NO new design decisions — it is purely the change-set-level artefact tying the three commits to one another, to the driving problem (P168), and to the underpinning decision (ADR-059).

## Scope

The RFC's scope mirrors what shipped under ADR-059:

1. **Consume-catalog protocol** — `packages/risk-scorer/agents/pipeline.md` reads `docs/risks/*.active.md`, filters by hybrid (slug-token-match primary, free-form judgement fallback), emits `Catalog match:` and `Catalog baseline:` lines in risk-item blocks, emits `CATALOG_HIT_RATE:` summary.
2. **Create-risk flag-driven path** — `packages/risk-scorer/skills/create-risk/SKILL.md` accepts `--slug` and `--prefill` flags for orchestrator-driven prefilled invocation; existing AskUserQuestion-driven authoring path preserved for human invocation.
3. **Bootstrap-catalog skill** — new `/wr-risk-scorer:bootstrap-catalog` skill with SKILL.md + REFERENCE.md + bats fixture. Walks `.risk-reports/*.md`, computes ADR-056 slug per report, emits one R<NNN>-`<slug>`.active.md per unique slug with `## Source Evidence` block.
4. **Install-updates Step 6.5.1 auto-trigger** — `scripts/repo-local-skills/install-updates/SKILL.md` auto-invokes bootstrap-catalog when catalog is empty AND `RISK-POLICY.md` is present AND `.risk-reports/` is non-empty.
5. **Wipe + re-bootstrap pass** — retire R001-R006 (pre-Control-Composition conservatism, superseded by P167 alignment); regenerate via extractor; first bootstrap-derived entry (R007) lands; broken markdown references in P158/P159 fixed.
6. **Behavioural bats coverage** — 30 + 29 + 17 = 76 bats across the three commits per ADR-052.

## Tasks (retrospective)

The tasks below describe what was done, in commit order. Forward-shape RFCs (Slice 5) populate Tasks BEFORE commit work begins; this retro reverses that ordering by design.

### Commit 1 — design + steady-state surfaces (`ab73328`)

- [x] Author `packages/risk-scorer/agents/pipeline.md` consume-catalog protocol — hybrid filter + residual reconciliation
- [x] Extend `packages/risk-scorer/skills/create-risk/SKILL.md` with `--slug` and `--prefill` flags
- [x] Wire orchestrator auto-invocation of `/wr-risk-scorer:create-risk` on `RISK_REGISTER_HINT:` consumption sites under ADR-013 Rule 5 + ADR-042 Rule 5
- [x] 30 bats covering pure-scorer-contract preservation + filter behaviour + residual reconciliation

### Commit 2 — bootstrap surface + install-updates auto-trigger (`af5447c`)

- [x] Author `/wr-risk-scorer:bootstrap-catalog` SKILL.md + REFERENCE.md + templates + bats
- [x] Extend `scripts/repo-local-skills/install-updates/SKILL.md` Step 6.5 with auto-trigger when catalog is empty
- [x] 29 bats covering empty-catalog bootstrap + populated-catalog smoke test + idempotency + slug-collapse correctness + source-evidence block presence

### Commit 3 — wipe + re-bootstrap validation pass (`8edaf7b`)

- [x] `rg 'R00[1-6]' docs/problems/` — detect dangling references; annotate or preserve IDs
- [x] `git mv docs/risks/R00{1..6}-*.active.md → .retired.md` with retire-reason "superseded by bootstrap-derived entries (ADR-059) post pre-Control-Composition reset"
- [x] Author `packages/risk-scorer/scripts/extract-risks-from-reports.sh` (~270 lines, two-phase: deterministic + LLM-walk fallback)
- [x] Generate R007 (first bootstrap-derived entry from this repo's actual corpus)
- [x] Generate `docs/risks/README.md`
- [x] Reinstate the held P168 changeset
- [x] Fix broken markdown references in P158/P159
- [x] 17 bats covering extractor + first bootstrap-derived entry shape

### Commit 3' (deferred) — see `## Deferred Scope`

## Commits

The trailer-recognition hook (`packages/itil/hooks/itil-rfc-trailer-advisory.sh`, Slice 3 B5.T9) populates this section forward-shape on each commit message carrying `Refs: RFC-NNN`. For RFC-001's retrospective shape, the commits below are listed manually because they predate the trailer convention:

| Commit | Date | Message |
|--------|------|---------|
| `ab73328` | 2026-05-04 | feat(risk-scorer): pipeline consume-catalog protocol + create-risk flag-driven path (ADR-059 Commit 1, P168) |
| `af5447c` | 2026-05-04 | feat(risk-scorer): bootstrap-catalog skill + install-updates Step 6.5.1 auto-trigger (ADR-059 Commit 2, P168) |
| `8edaf7b` | 2026-05-04 | feat(risk-scorer): wipe pre-correction R001-R006 + write extractor (P168 / ADR-059 Commit 3, user direction 2026-05-04) |

The current commit (the one creating this RFC file) carries the `Refs: RFC-001` trailer per the convention; its message announces the retro authoring rather than additional substantive work.

## Verification

Six-clause "no semantic loss" check per ADR-060 § Confirmation criterion 5 + architect finding 5:

- [x] **5(a) commits referenced** — `ab73328`, `af5447c`, `8edaf7b` all named in `## Commits` table above; they match P168's `## Fix Released` section verbatim.
- [x] **5(b) Smoke-Test Findings map to verification entries** — P168's `## Smoke-Test Finding (2026-05-04, post-Commit-2)` section captures two findings (dangling-reference density; corpus mostly pre-ADR-056) that drove the Commit 3 deferral. These map to RFC-001 § Deferred Scope below; the smoke-test rationale is preserved verbatim in P168 and forward-pointed from RFC-001.
- [x] **5(c) deferred Commit 3' named** — under `## Deferred Scope` below AND explicitly listed in P168's continuing-scope (see edit to P168 in same commit). The conjunctive AND is satisfied (architect-review finding 1, 2026-05-06).
- [x] **5(d) P168 lifecycle preserved** — P168 stays at `.verifying.md`. No transition. The auto-maintained `## RFCs` reverse-trace section is added to P168 in this commit; no other body content is changed except the one-line continuing-scope addition under `## Smoke-Test Finding`.
- [x] **5(e) ADR-059 references propagate** — frontmatter `adrs: [ADR-059]` + body cross-refs at `## Underpinning ADR trace` + `## Related`.
- [x] **5(f) round-trip retrievability** — every fact retrievable from P168 pre-migration is retrievable post-migration via the RFC-001 + P168 pair: P168 retains its full body (Description, Symptoms, Workaround, Impact, RCA, Architect Review, JTBD Review, Smoke-Test Finding, Fix Strategy, Dependencies, Related, Fix Released); RFC-001 adds change-set-level scope, retroactive Tasks, Commits table, Verification, Deferred Scope, and this Lifecycle Provenance block. Cross-references are bidirectional: P168 references RFC-001 via the auto-maintained `## RFCs` section; RFC-001 references P168 via frontmatter `problems: [P168]` + the `## Driving problem trace` section.

## Deferred Scope

**Commit 3' — Heuristic-slug derivation for pre-ADR-056 reports**:

Of 164 `.risk-reports/*.md` files at the time of bootstrap (2026-05-04), only 1 carries a structured `RISK_REGISTER_HINT:` block (the post-ADR-056 deterministic path the bootstrap-catalog skill consumes natively). The remaining 163 reports require LLM-walking per the SKILL.md fallback path — a multi-hundred-tool-call pass impractical to run inline in a single agent session.

The deferral does NOT prevent ADR-059 Commit 1 + Commit 2 + Commit 3 from being released; only the historical-backfill validation is deferred. The runtime contract is complete (the deterministic path covers post-ADR-056 reports going forward). Reinstate triggers (any of):

- **Corpus matures**: ≥30 days post-ADR-056 release accumulates a critical mass of hint-bearing reports (≥20 unique slugs surfaced via `RISK_REGISTER_HINT:`). At that point, the deterministic path covers the catalog without LLM-walk dependency.
- **User-driven LLM-walk pass**: user invokes `/wr-risk-scorer:bootstrap-catalog` interactively in a dedicated session, walks the 163 unhinted reports, and validates the output covers R001-R006's surfaced classes before authorising further wipe.
- **Dedicated bootstrap script extension**: extend `packages/risk-scorer/scripts/extract-risks-from-reports.sh` (per ADR-049 plugin-bundled scripts) with heuristic-slug derivation for pre-ADR-056 reports. This is itself an XL extension of ADR-059 and warrants its own ADR + RFC pair when it's picked up.

When Commit 3' is picked up, the work belongs under one of: (a) a follow-up RFC (RFC-NNN, traced to P168 + this RFC) if the heuristic-slug work is itself multi-commit; (b) a single commit referencing both this RFC's `## Commits` table and the new ADR/RFC pair if it stays atomic.

## Related

- **P168** — driving problem (`docs/problems/168-risk-scorer-doesnt-consume-catalog-or-bootstrap.verifying.md`). Lifecycle preserved at `.verifying.md` per § Confirmation criterion 5(d).
- **ADR-059** — `docs/decisions/059-pipeline-consume-catalog-and-bootstrap-from-reports.proposed.md` — substantive design.
- **ADR-060** — `docs/decisions/060-problem-rfc-story-framework-with-mandatory-problem-trace-and-unified-problem-ontology.accepted.md` — RFC framework constitutional ADR; § Confirmation criterion 5 (six-clause no-semantic-loss test) is the Verification block above. ADR-060 Phase 1 item 9 is THIS RFC.
- **P170** — `docs/problems/170-problem-tickets-strain-as-fixes-decompose-into-multiple-coordinated-changes-need-rfc-framework.open.md` — driver problem for ADR-060 / RFC framework rollout.
- **`docs/plans/170-rfc-framework-story-map.md`** — Slice 4 tasks B6.T1-T4 land this RFC.
- **ADR-047** — Phase 2 / Phase 3 deferred there; P168 + ADR-059 promoted both.
- **ADR-056** — slug primitive consumed by the deterministic bootstrap path.
- **P167** — driver of P168 (P167's substantive remaining work was delegated to P168).
- **JTBD-001** — primary persona-job served by the consume-catalog protocol (missed-risk-class hazard IS a JTBD-001 desired-outcome failure).
- **JTBD-006** — AFK-safety binding constraint (orchestrator-side auto-invocation preserves pure-scorer contract).
- **JTBD-202** — audit-trail constraint (catalog IS the structured/auditable artefact).
- **ADR-014** — single-commit grain. RFC-001 = N×ADR-014-grain commits, ordered.
- **ADR-042 / P162** — held-changeset window. ADR-042 auto-apply remains paused until RFC-001 reaches `closed` per § Confirmation criterion 6.
- **ADR-052** — behavioural-tests default. 76 bats across the three commits.
- **ADR-060 § Reassessment criterion "Forward-dogfood pending"** — RFC-001 demonstrates representability; framework correctness requires the forward-dogfood RFC (Slice 5).
