---
status: "proposed"
date: 2026-05-04
decision-makers: [Tom Howard]
consulted: [wr-architect:agent (P168 design review 2026-05-04 + ADR-059 draft review 2026-05-04), wr-jtbd:agent (P168 design review 2026-05-04)]
informed: [Windy Road plugin users, adopter maintainers (addressr, addressr-mcp, addressr-react, very-fetching, bbstats, windyroad)]
reassessment-date: 2026-08-04
---

# Pipeline consume-catalog protocol and bootstrap-from-reports register population

## Context and Problem Statement

P168 (driver) captures two structural failure modes in the standing-risk register pipeline:

1. **The pipeline agent regenerates risk classes from scratch on every per-action assessment** — wasted effort plus the missed-risk-class hazard (the agent might omit a risk it surfaced before because it didn't think of it this time).
2. **No bootstrap path populates `docs/risks/` from the existing `.risk-reports/` corpus** — adopters end up with an empty register even after running for weeks, because no agent / skill / hook walks the historical reports to seed the register.

The catalog framing landed in `RISK-POLICY.md` `## Risk Catalog` section (commit `9e339d0`, 2026-05-04) describes the consume-catalog and bootstrap workflow at policy layer:

> The catalog is consumed by per-action risk assessments (commit / push / release / external-comms / etc.):
> 1. The assessing agent reads `docs/risks/` and filters to risks that apply to THIS action.
> 2. For each applicable risk, it assesses whether the documented controls are in effect for this action and computes residual against the same 4/Low appetite.
> 3. If residual exceeds appetite, the agent applies additional controls, or blocks/halts the action per the gate-specific rules.
> 4. If the agent conceives a new risk class during assessment that is not yet documented, it adds an entry to `docs/risks/` so it carries forward to the next assessment.

But no agent implements steps 1, 2, or 4. ADR-056 implemented step 4 partially (hook queues hint; drain step writes register entry — Phase 2a landed; Phase 2b drain still deferred). ADR-047 Phase 3 (one-time backfill from `.risk-reports/`) was explicitly deferred for "architect-design depth (autonomy boundary, dedupe-by-risk-name, evidence-log appending, marker-driven backfill gating)" — those concerns are now resolvable given ADR-056's slug primitive.

P168 is the substantive design successor to P167 (which captured the symptom — register reads as "don't ship" — and corrected the policy framing). P168 packages three remaining pieces:

- **Consume-catalog protocol** — extension to `packages/risk-scorer/agents/pipeline.md`. Hybrid filter; residual reconciliation.
- **Bootstrap-from-empty** — new `/wr-risk-scorer:bootstrap-catalog` skill + `/install-updates` Step 6.5 auto-trigger.
- **Phase 2b drain wire-up** — orchestrator-side auto-invocation of `/wr-risk-scorer:create-risk` with prefill flags.

Effort: **XL** (architect estimate; 8 distinct edits across 2-3 commits, multi-iteration). This ADR covers the design decisions; implementation rides separate commits per ADR-014 grain.

**Why a sibling ADR rather than amending ADR-047 or ADR-056:** ADR-047's frame is narrowly Phase 1 directory scaffold; ADR-056's frame is the queue-write contract for new-risk-class detection. Neither covers the read-side consume-catalog protocol nor the historical bootstrap. Architect verdict on P168 (verdict H): NEW sibling ADR; one-line forward-pointer amendment to ADR-047's `## Out of Scope` only. ADR-056's `## Reassessment Criteria` already anticipates Phase 2b / Phase 3 as future ADR-class work.

## Decision Drivers

- **P168** — driver ticket. Captures the missed-risk-class hazard (JTBD-001 compliance failure) and the wasted-effort daily friction (cognitive-load on plugin-maintainer).
- **P167** — parent ticket. Corrected the policy framing (RC1, RC2 valid; RC3 superseded). This ADR's design unblocks P167's transition to verifying via the substantive structural fix.
- **JTBD-001 (Enforce Governance Without Slowing Down)** — primary fit per JTBD review on P168. The missed-risk-class hazard IS a JTBD-001 desired-outcome failure ("Every edit reviewed against relevant policy before it lands"). Consume-catalog closes the mechanism.
- **JTBD-202 (Run Pre-Flight Governance Checks Before Release or Handover)** — secondary. Catalog IS the structured/auditable/ISO-citable artefact JTBD-202 requires. Bootstrap-derived entries with `## Source Evidence` discharge JTBD-202 provenance.
- **JTBD-006 (Progress the Backlog While I'm Away)** — co-secondary BINDING constraint. Bootstrap MUST be idempotent + non-interactive or it breaks `/wr-itil:work-problems` AFK loops (JTBD-006 line 18: "Decisions that would normally require my input are resolved using safe defaults").
- **JTBD-007 (Keep Plugins Current Across Projects)** — touched at install-updates auto-trigger surface. Step 7 final report shows bootstrap line item ("Risk register: bootstrapped N entries from M reports across K themes").
- **ADR-013 Rule 5** (policy-authorised silent proceed) — `RISK-POLICY.md` `## Risk Catalog` section IS the policy authorisation for orchestrator-side auto-invocation of `/wr-risk-scorer:create-risk` on hint consumption. No per-action consent gate.
- **ADR-014** (Governance Skills Commit Their Own Work) — bootstrap commits per ADR-014 grain (one commit per logical unit of work). The wipe pass + re-bootstrap commit is its own ADR-014 unit.
- **ADR-015** (Pure-scorer contract) — pipeline agent stays `Read + Glob` only. Auto-write happens orchestrator-side (calling create-risk), NOT inside the pipeline agent. Architect verdict F.
- **ADR-022** (Problem lifecycle Verification Pending status) — bootstrap-derived entries enter as `Active` (auto-scaffolded — pending review) per ADR-056's existing pending-review pattern. No new lifecycle stage needed.
- **ADR-026** (Agent Output Grounding) — `## Source Evidence` block on bootstrap-derived entries cites originating `.risk-reports/<filename>.md` files. Provenance is load-bearing per architect verdict D.
- **ADR-038** (Progressive disclosure) — bootstrap skill ships with SKILL.md (runtime contract) + REFERENCE.md (deep context).
- **ADR-040** (SessionStart read-mostly contract) — rules out SessionStart as a bootstrap firing surface (architect verdict A1 rejected).
- **ADR-042** (Auto-apply scorer remediations open vocabulary) — orchestrator-side auto-invocation of create-risk on hint consumption is a Rule 5 policy-authorised action (catalog framing IS the policy).
- **ADR-044** (Decision Delegation Contract) — framework-mediated lifecycle authority. Hint-to-register-entry materialisation is a mechanical-stage carve-out (P132 inverse-P078 — do NOT call AskUserQuestion in mechanical stages).
- **ADR-047** — parent ADR (Phase 1 directory scaffold). This ADR is Phase 3 of ADR-047's roadmap (bootstrap from existing reports). One-line forward pointer in ADR-047 `## Out of Scope` cross-references this ADR.
- **ADR-049** (Plugin script resolution via $PATH bin) — bootstrap skill's helper scripts (slug computation; report walker) ride `packages/risk-scorer/bin/` per the canonical naming grammar.
- **ADR-052** (Behavioural-tests default) — bootstrap skill + pipeline consume-catalog protocol + create-risk flag extension all land with behavioural bats coverage. P081 (no structural grep on SKILL.md / ADR content) applies; all 26 fixture cases below are behavioural by construction.
- **ADR-053** (`@windyroad/*` plugin / skill / agent / hook maturity taxonomy) — new `/wr-risk-scorer:bootstrap-catalog` skill ships with a maturity tag per the taxonomy. Initial maturity: `proposed` matching the parent ADR's status.
- **ADR-054** (SKILL.md runtime budget policy) — pipeline.md extension stays within budget (~40-line edit per architect estimate); create-risk SKILL.md +30 lines; new bootstrap-catalog SKILL.md within first-author budget.
- **ADR-055** (Plugin-published artefacts use namespace-prefixed permalinks) — the new skill's published ID is `/wr-risk-scorer:bootstrap-catalog` per the namespace prefix convention.
- **ADR-056** — sibling ADR (Phase 2a queue-write contract). This ADR consumes ADR-056's slug primitive for dedupe; consumes ADR-056's queue-and-drain pattern for orchestrator auto-invoke.
- **ADR-057** (Three-phase declarative-first cluster rollout) — implementation rides a similar Phase-1/2/3 cadence (Commit 1 design+steady-state; Commit 2 bootstrap+install-updates; Commit 3 wipe+validation). The phasing is pragmatic ADR-014 grain, NOT a full ADR-057 declarative-first cluster — but the cadence convention is honoured.

## Considered Options

### A. Bootstrap firing surface

#### A1 — SessionStart hook
Fire on every session start when catalog is empty AND `.risk-reports/` is non-empty. **Rejected.** ADR-047 line 39 already rejected SessionStart for the directory-scaffold case ("too aggressive; SessionStart is read-mostly per ADR-040"). Bootstrap-from-reports is *more* aggressive (generates content, not empty shell) — rejection rationale applies *a fortiori*.

#### A2 — Pipeline agent SKILL.md preamble
Agent self-checks catalog-empty-state on every per-action invocation; runs bootstrap inline if empty. **Rejected.** Pipeline agent tool grant is `Read + Glob` only per ADR-015. Cannot write `docs/risks/`. Also wasteful — bootstrap is one-shot, pipeline runs per-action.

#### A3 — Marker-gated one-shot in pipeline
Same as A2 plus a `.claude/.risk-bootstrap-done` marker so it fires once per project. **Rejected.** Inherits A2's pure-scorer constraint; adds marker-management complexity ADR-047 explicitly avoided ("No marker file is written" — line 87).

#### A4 — New `/wr-risk-scorer:bootstrap-catalog` skill (CHOSEN, on-demand surface)
On-demand skill the user invokes once per project lifetime. Mirrors ADR-036's `scaffold-intake` skill on-demand surface. ADR-047 line 119 explicitly named this as deferred ("Sibling skill `/wr-risk-scorer:scaffold-register`... Add when usage demand surfaces"). P168 IS the demand signal.

#### A5 — Extend `/wr-risk-scorer:create-risk` to detect empty-catalog
Fold bootstrap behaviour into create-risk when invoked on an empty catalog. **Rejected** by parallel reasoning to ADR-047 Option 5: conflates "create-a-risk" with "bootstrap-the-catalog"; only fires when create-risk is invoked, which IS the discoverability gap that produced the 99%-miss-rate regression ADR-047 fixed.

#### A6 — Auto-trigger from `/install-updates` Step 6.5 (CHOSEN, auto-trigger surface)
Extend ADR-047's existing Step 6.5 from "scaffold empty register" to "scaffold + bootstrap from .risk-reports/ when register empty AND reports non-empty". Auto-trigger fires under ADR-013 Rule 5 (catalog framing IS the policy authorisation; existing per-sibling consent gate covers this auto-trigger). User sees bootstrap line item in Step 7 final report (JTBD-007 transparency).

**Decision (A4 + A6 dual-surface)** — mirrors ADR-036's dual-surface pattern (on-demand skill + auto-trigger from a host skill). A4 for users who want to bootstrap mid-session without an install; A6 for the routine case where bootstrap rides the next install-updates run.

### B. Dedupe mechanism — risk-slug as the dedupe key

#### B1 — ADR-056 risk-slug (CHOSEN)
Bootstrap walks `.risk-reports/*.md` once, computes the slug per ADR-056 rules (filename-safe kebab-case; lowercase; drop articles; stable across runs; ≤60 chars; word-boundary truncation), emits one `R<NNN>-<slug>.active.md` per unique slug. Reused without modification.

#### B2 — Theme-clustering at higher level
Cluster the ~327 unique titles into 12-14 themes (per P167 gap analysis) before emitting register entries. **Rejected.** Theme-clustering is a post-hoc human reading of the title-distribution. Using it as the dedupe primitive would require LLM judgement per cluster on every bootstrap run — non-deterministic, hard to test, inconsistent with the deterministic-slug discipline ADR-056 chose.

**Decision (B1)** — reuse ADR-056 slug. NOT a new architectural decision; the slug IS the "dedupe-by-risk-name" primitive ADR-047 deferred. ADR-056 landed AFTER ADR-047 was written; ADR-056's slug resolves the ADR-047 deferral.

### C. Threshold for "warrants standing entry"

#### C1 — ANY slug ≥ 1 time (CHOSEN, no threshold)
Every distinct slug seen in `.risk-reports/` gets a register entry. No frequency floor; no severity floor.

#### C2 — Frequency threshold (e.g., ≥3 occurrences)
Only emit entries for slugs seen ≥3 times. **Rejected.** User direction in ADR-047 line 18 is unconditional ("for each risk mentioned in the .risk-reports, there should be something in the risk register"). Frequency threshold systematically misses low-frequency-high-severity classes — exactly the catalog's most valuable shape. A risk that fires once at residual=15 IS the kind of standing-risk shape the catalog exists for (P168 missed-risk-class hazard framing).

#### C3 — Severity threshold (e.g., Medium+)
Only emit entries when residual ≥ Medium. **Rejected** by parallel reasoning. The catalog's purpose includes documenting low-severity-but-recurring risks where layered controls keep residual within appetite.

**Decision (C1)** — no threshold. Catalog noise is genuinely cheaper to fix than catalog gaps:
- Noisy entry → retire to `R<NNN>.retired.md` per `docs/risks/README.md` line 30 vocabulary; one-commit fix.
- Missing entry → silent under-assessment per P168's symptom; recurs until a future report happens to surface the class again.

Quality control is the **independent-control-paths re-rate** mandated by `RISK-POLICY.md` `## Control Composition` (the rule that landed in commit `9e339d0`). Bootstrap-derived entries compute residuals using the new rule; entries that prove obviously redundant or overspecific can be retired in a follow-up review pass.

### D. Citation back to source `.risk-reports/`

#### D1 — REQUIRED `## Source Evidence` block (CHOSEN)
Bootstrap-derived entries carry an inline `## Source Evidence` block citing originating reports. ADR-026 grounding pattern. Concrete shape:

```markdown
## Source Evidence (bootstrap-derived 2026-MM-DD)

Aggregated from N `.risk-reports/` entries (slug: `<risk-slug>`):
- `.risk-reports/<filename>.md`
- `.risk-reports/<filename>.md`
...

Re-rate when new reports surface against this slug or when controls change.
```

#### D2 — No citation; trust filename
Identify entries as bootstrap-derived only by filename pattern. **Rejected.** Future reviewers cannot tell hand-authored vs bootstrap-derived without source evidence; provenance becomes guesswork (JTBD-202 audit-trail gap). Filename pattern is brittle under retire+rename flows.

**Decision (D1)** — required `## Source Evidence` block. Citations may go dangling at 7-day `.risk-reports/` cleanup (per `docs/risks/README.md` line 11); that's acceptable per ADR-026 grounding-at-time-of-write semantic. The block remains valuable as historical provenance even after the source files are gone.

### E. Consume-catalog protocol — pipeline reads `docs/risks/` first

#### E1 — Pure slug-token-matching against diff
Pipeline reads `docs/risks/`, filters to risks whose slug tokens appear in the diff/commit-message text. **Rejected as primary.** Too brittle — slug "register-drift" wouldn't match a diff that touches `docs/risks/` without using the literal word "drift".

#### E2 — Pure free-form judgement
Pipeline reads `docs/risks/`, agent free-form-judges applicability of each entry. **Rejected as primary.** Loses the dedupe discipline ADR-056 just established; re-introduces the regeneration cost P168 names.

#### E3 — Hybrid filter (CHOSEN)
- **Primary**: slug-token-matching against diff content + commit message + recent prompt context. Fast, deterministic, traceable.
- **Fallback**: free-form judgement on entries the slug-match path missed. Agent reads the entry's `## Description` and judges applicability.
- **Logging**: judgement-path applicability is logged in the report so the next agent can carry it forward.

**Residual reconciliation:**
- The catalog entry's residual is the **lifetime baseline** under the documented controls (the controls present in the project as a whole).
- THIS action's residual is the baseline modulated by the controls present (or absent) in this specific change.
- The pipeline's `RISK_SCORES:` output is per-action by contract — gates per-action commits/pushes/releases. So `RISK_SCORES:` MUST carry the per-action residual, NOT the catalog's lifetime baseline.
- The catalog's residual is meaningful CONTEXT — tells the reviewer "this risk class normally sits at residual=9, but for this change with these controls it's at 2".

**Concrete pipeline.md extension (~40-line edit):**
- New `## Catalog Consumption Protocol` section between `## Pipeline State` and `## Cumulative Risk Report`.
- Risk-item format (`pipeline.md` lines 79-87) gains a `Catalog baseline:` line citing R<NNN> ID + lifetime-baseline residual.
- The judgement path is recorded as `Catalog match:` with values `slug-token` (primary path), `judgement` (fallback path), or `none` (no catalog entry applies).
- The pipeline emits a per-run `CATALOG_HIT_RATE: matched=N missed=M` line for observability — JTBD-001 success metric is hit rate >70% on second-and-subsequent assessments.

**Decision (E3 hybrid)** — captures the deterministic-first, judgement-fallback shape that respects ADR-056's slug primitive without making the agent brittle.

### F. Newly-conceived risk classes back to catalog

#### F1 — Pipeline agent auto-writes `docs/risks/`
Grant pipeline agent `Write` tool; agent edits register entries directly. **Rejected.** Breaks ADR-015 pure-scorer contract. ADR-042 line 41 explicitly cites the boundary: "Pure-scorer contract (ADR-015) — scoring + remediation generation live in the scorer; orchestrator interprets and acts."

#### F2 — Preserve `RISK_REGISTER_HINT:` surface (CHOSEN)
Pipeline emits `RISK_REGISTER_HINT:` per ADR-056. Hook queues per ADR-056. Drain step (this ADR Phase 2b) wires orchestrator-side auto-invocation of `/wr-risk-scorer:create-risk` with prefill flags under ADR-013 Rule 5 (catalog framing IS the policy authorisation).

**Concrete create-risk flag extension (~30-line edit):**
- `/wr-risk-scorer:create-risk` SKILL.md gains `--slug <slug>` and `--prefill <prose>` CLI flags (markdown-style invocation arguments).
- When flags are supplied, the skill skips its existing AskUserQuestion-driven authoring path and writes the entry deterministically:
  - Filename: `R<NNN>-<slug>.active.md` (next R<NNN> per the existing ID-allocation algorithm).
  - Status: `Active (auto-scaffolded — pending review)` per ADR-056 pending-review pattern.
  - Description: prefill verbatim.
  - Inherent / Residual fields: `not estimated — no prior data` per ADR-026 sentinel.
  - `## Source Evidence` block: cites the originating `RISK_REGISTER_HINT:` report path from the queue.
- Existing AskUserQuestion-driven authoring path preserved for human invocation (no flags).

**Orchestrator wire-up (Phase 2b drain step):**
- Each consumer skill (`/wr-itil:work-problems`, `/wr-itil:manage-problem` Step 11, `/install-updates`, `/wr-risk-scorer:assess-release`) gains a "Drain risk-register queue" step that reads `.afk-run-state/risk-register-queue.jsonl`, dedupes by slug, invokes `/wr-risk-scorer:create-risk --slug=<slug> --prefill=<prefill>` per unique slug, truncates the queue per ADR-056 drain contract.

**Decision (F2)** — orchestrator-side auto-invoke. Preserves ADR-015 pure-scorer contract; closes the missed-class hazard via the existing hint surface; uses framework-mediated lifecycle authority per ADR-044 (the catalog framing in `RISK-POLICY.md` is the policy authorisation, so per-class auto-invocation is mechanical, not user-decision).

### G. Agent ownership split

| Behaviour | Owner | Rationale |
|-----------|-------|-----------|
| Bootstrap-from-empty | New `/wr-risk-scorer:bootstrap-catalog` skill (per A4) + auto-trigger from `/install-updates` Step 6.5 (per A6) | One-shot per project lifetime; needs Write tool for `docs/risks/`; user-invocable for discoverability |
| Consume-catalog | Extends `wr-risk-scorer:pipeline` agent prompt (per E3) | Per-action; pure-scorer contract preserved (Read + Glob only) |
| Auto-write of newly-conceived classes | Orchestrator-side auto-invoke of `/wr-risk-scorer:create-risk` with prefill flags (per F2) | Per-pipeline-run-with-hint; ADR-015 pure-scorer contract preserved on agent side; ADR-056 drain contract honoured |

Different invocation cadences (one-shot per project / per-action / per-run-with-hint) → distinct surfaces per ADR-015 skill/agent boundary discipline. All three changes can ship in two commits but they ARE three distinct edits, not one mega-edit.

### H. ADR shape — sibling not amendment

ADR-047's frame is narrowly Phase 1 directory scaffold (line 92: title "Install-updates scaffolds governance artefacts when policy file is present but artefact is missing"). Promoting Phase 2/3 in-place would require rewriting Context/Decision-Drivers/Considered-Options/Decision-Outcome/Confirmation/Reassessment — effectively a new ADR with the same number.

ADR-047's Reassessment Criteria (line 178) already anticipates Phase 2 as a future ADR ("Adopter `docs/risks/` populate-rate stays near zero 3+ months post-Phase-2 release"). The reassessment text presupposes a sibling ADR.

P167's "amend ADR-047" verdict was for the narrower gap-analysis-methodology concern; doesn't extend to P168's behaviour-design scope.

**Decision (sibling ADR)** — this file (ADR-059). ADR-047 gets only a one-line forward-pointer in `## Out of Scope`: `Phase 2/3 superseded by ADR-059 (consume-catalog + bootstrap-from-reports)`.

### I. Wipe scope — separate transition AFTER bootstrap validates

#### I1 — Wipe BEFORE bootstrap (single ticket scope)
Wipe R001-R006 → run bootstrap → land. **Rejected.** Wipe-before risks a window of zero coverage if implementation takes 2 iterations. Violates ADR-042 never-release-above-appetite invariant applied to assessment surface (catalog is part of the assessment surface; an empty catalog under per-action assessment is a known gap).

#### I2 — Wipe AFTER bootstrap, two-pass validation (CHOSEN per architect verdict)
1. Land ADR-059 + bootstrap skill + consume-catalog edits to pipeline + create-risk flag extension + Phase 2b drain wire-up. (Commits 1-2.)
2. Run bootstrap on existing populated catalog as smoke test (output diffs against R001-R006). Verify slug-collapse behaviour against a known set.
3. `git mv R001-R006.active.md → R001-R006.retired.md` with retire-reason "superseded by bootstrap-derived entries (ADR-059) post pre-Control-Composition reset".
4. Run bootstrap on now-empty catalog.
5. Compare bootstrap-derived coverage against the retired R001-R006 set. If gaps surface, file follow-up tickets against ADR-059 Reassessment Criteria.
6. JTBD verdict J4 caveat: `rg 'R00[1-6]' docs/problems/` BEFORE the wipe to detect dangling references in closed tickets. Annotate or preserve IDs in the rebuild as needed.

**Contested decision — JTBD counter-position recorded for traceability**: JTBD verdict on P168 (J4) recommended atomic wipe-in-this-ticket as a coupled commit pair (1: wipe pre-Control-Composition entries; 2: bootstrap from corpus) — making the rebuild legible to JTBD-202 due-diligence readers via a single `git log` window. **Architect verdict prevailed on two-pass validation grounds**: smoke-test on populated state proves consume-catalog + slug-collapse behaviour BEFORE the destructive wipe, eliminating the window-of-zero-coverage risk. The contested decision is recorded so future readers reading only ADR-059 understand the wipe-timing was a contested architectural choice, not a default.

**Decision (I2)** — split. Wipe IS in scope of P168 ticket but lands as a SEPARATE commit AFTER the bootstrap skill + consume-catalog edits land and validate. User direction discharged; only timing differs.

## Decision Outcome

**Chosen design (synthesises verdicts A4+A6 / B1 / C1 / D1 / E3 / F2 / G / H / I2):**

1. **New `/wr-risk-scorer:bootstrap-catalog` skill** — on-demand surface for one-shot bootstrap of `docs/risks/` from `.risk-reports/`. Walks reports, computes slugs per ADR-056, emits one `R<NNN>-<slug>.active.md` per unique slug with `## Source Evidence` block. Maturity tag per ADR-053: `proposed`.
2. **`/install-updates` Step 6.5 extension** — auto-trigger bootstrap when catalog is empty AND `RISK-POLICY.md` is present AND `.risk-reports/` is non-empty. Step 7 final report shows bootstrap line item.
3. **`packages/risk-scorer/agents/pipeline.md` consume-catalog protocol** — hybrid filter (slug-token-match primary; free-form judgement fallback). Risk-item format gains `Catalog baseline:` and `Catalog match:` lines. Per-run `CATALOG_HIT_RATE:` observability line.
4. **`packages/risk-scorer/skills/create-risk/SKILL.md` flag extension** — accept `--slug <slug>` and `--prefill <prose>` flags for orchestrator-driven prefilled invocation. Existing AskUserQuestion-driven authoring path preserved for human invocation.
5. **Orchestrator-side auto-invoke** — Phase 2b drain step in `/wr-itil:work-problems`, `/wr-itil:manage-problem` Step 11, `/install-updates`, `/wr-risk-scorer:assess-release` invokes `/wr-risk-scorer:create-risk --slug --prefill` per ADR-056 queue line. This ADR's Confirmation requires AT LEAST the AFK orchestrator (`/wr-itil:work-problems`) drain to land in Commit 1; other consumers ride subsequent iters.
6. **ADR-047 amendment** — one-line forward pointer in `## Out of Scope`.
7. **Wipe pass** — separate commit AFTER 1-5 land and validate. Two-pass smoke-then-empty test discharges JTBD-202 audit-trail concern via git history.

## Scope

### In scope (this ADR / multi-iteration implementation per Fix Strategy)

**Surface enumeration by commit** (8 distinct edit surfaces total — one-line per surface for ADR-014 grain auditability):

**Commit 1 — design + steady-state surfaces (5 surfaces):**

1. `docs/decisions/059-pipeline-consume-catalog-and-bootstrap-from-reports.proposed.md` — this file.
2. `docs/decisions/047-install-updates-scaffolds-governance-artefacts.proposed.md` — one-line forward-pointer amendment in `## Out of Scope`.
3. `packages/risk-scorer/agents/pipeline.md` — consume-catalog protocol (~40-line edit).
4. `packages/risk-scorer/skills/create-risk/SKILL.md` — `--slug` / `--prefill` flag extension (~30-line edit).
5. `packages/itil/skills/work-problems/SKILL.md` — Phase 2b drain step (the AFK orchestrator first surface). Other consumers (`/wr-itil:manage-problem` Step 11, `/install-updates`, `/wr-risk-scorer:assess-release`) follow in subsequent iters per ADR-014 grain.

Plus behavioural bats fixtures for surfaces 3 (pipeline consume-catalog) and 4 (create-risk flag-driven invocation).

**Commit 2 — bootstrap surface + install-updates auto-trigger (2 surfaces + REFERENCE.md):**

6. `packages/risk-scorer/skills/bootstrap-catalog/SKILL.md` + `REFERENCE.md` — new skill.
7. `scripts/repo-local-skills/install-updates/SKILL.md` — Step 6.5 extension (~20-line edit).

Plus behavioural bats fixtures for both surfaces.

**Commit 3 — wipe + re-bootstrap validation pass (1 surface + retire renames):**

8. Atomic two-commit pair per JTBD verdict J4 (or single commit per architect verdict I2 — final shape determined at commit time by reviewer):
   - `chore(risks): wipe pre-Control-Composition register entries (P167 alignment)` — `git mv docs/risks/R00{1..6}-*.active.md → .retired.md` with retire-reason citing this ADR.
   - `feat(risks): bootstrap register from .risk-reports/ corpus (closes P168)` — runs `/wr-risk-scorer:bootstrap-catalog` on the now-empty catalog; commits the bootstrap output.

Pre-wipe gate: `rg 'R00[1-6]' docs/problems/` to detect dangling references; annotate any references found.

**Total: 8 surface edits across 3 commits, plus bats coverage.** Architect estimate: XL aggregate, multi-iteration.

### Out of scope (deferred to follow-up ADRs / iters)

- **Drain steps in non-orchestrator consumer skills** — `/wr-itil:manage-problem` Step 11 drain; `/install-updates` Step 6.6 drain; `/wr-risk-scorer:assess-release` drain. Ride subsequent iters per ADR-014 grain. This ADR's Confirmation criteria require at least the AFK orchestrator (`/wr-itil:work-problems`) drain.
- **Curation skill `/wr-risk-scorer:review-register`** — drains pending-review entries (assigns scoring + flips Status to plain `Active`). Lands when adopter usage demonstrates demand (per ADR-056 deferral; carried forward).
- **Audit-export skill** — `/wr-itil:export-risk-register` for tech-lead JTBD-202 due-diligence packaging. Deferred per JTBD persona-centring verdict (separate ticket if real tech-lead pull surfaces).
- **Theme-clustering at higher level than ADR-056 slug** — deferred unless slug rules need refinement (signal: slug collisions cause register fragmentation > 5% false positives).
- **Severity / frequency thresholds** — explicitly rejected per Verdict C; not on the deferred list, on the rejected list.
- **Cross-template drift handling for bootstrap-derived entries** — when this repo's `docs/risks/TEMPLATE.md` evolves, bootstrap-derived adopter entries stay frozen. Mirror of ADR-036 / ADR-047 template-drift consequence; same mitigation path (re-invocation diff + scaffold-version metadata).
- **Auto-write at pipeline agent level** — explicitly rejected per Verdict F. Preserves ADR-015 pure-scorer contract.
- **Pre-flight gating on pending-review entries** — JTBD-202 caveat from ADR-056: do NOT hard-block release on pending-review entries. Surface as findings only.
- **TTL purge of bootstrap-derived entries that haven't matched a per-action assessment in N days** — defer until evidence of register fragmentation surfaces.

## Consequences

### Good

- **Closes P168 missed-risk-class hazard.** Pipeline reads catalog first; agent cannot omit a class it surfaced before because the class is in the catalog and the slug-token-match path catches it deterministically.
- **Closes P168 wasted-effort cost.** Per-action assessments stop regenerating risk classes from scratch; catalog hit rate >70% target on second-and-subsequent assessments.
- **Closes P033 99% miss rate at runtime** (alongside ADR-047 Phase 1 + ADR-056 Phase 2a). Bootstrap populates the register from existing reports; new-class detection populates incrementally per per-action runs.
- **Reuses ADR-056 slug primitive.** The architect-design-depth concern from ADR-047 line 113 ("dedupe-by-risk-name") is resolved by ADR-056's slug; ADR-059 consumes it without modification.
- **Preserves ADR-015 pure-scorer contract.** Pipeline agent stays `Read + Glob`. Auto-write happens orchestrator-side via `/wr-risk-scorer:create-risk` flag-driven invocation.
- **AFK-safe per JTBD-006.** Bootstrap is idempotent (file-existence test per slug); install-updates auto-trigger inherits ADR-013 Rule 5 silent proceed; `/wr-risk-scorer:work-problems` AFK loops are unaffected.
- **Provenance via `## Source Evidence` block.** Discharges JTBD-202 traceable-provenance requirement directly. Bootstrap-derived entries cite originating `.risk-reports/` files; future reviewers can audit the bootstrap's reasoning.
- **Two-pass validation discharges JTBD-202 audit-trail concern.** Smoke test on populated catalog before wipe; full re-bootstrap after wipe; git history preserves both states.
- **Pipeline `CATALOG_HIT_RATE:` observability** — adopter sessions can measure catalog effectiveness over time; signal for ADR-059 Reassessment Criteria.

### Neutral

- New `/wr-risk-scorer:bootstrap-catalog` skill adds ONE new skill to the risk-scorer surface count. Within the natural skill-count trajectory ADR-015 anticipates. Maturity tag `proposed` per ADR-053.
- `packages/risk-scorer/agents/pipeline.md` grows by ~40 lines for consume-catalog protocol. Within ADR-054 SKILL.md runtime budget.
- `/wr-risk-scorer:create-risk` SKILL.md grows by ~30 lines for flag-driven path. Within budget.
- `scripts/repo-local-skills/install-updates/SKILL.md` Step 6.5 grows by ~20 lines for auto-trigger. Within budget per ADR-038 (REFERENCE.md takes the depth).
- Bootstrap walks 164 reports — first-time cost (~minutes wall-clock) at install-updates time; amortised once per project lifetime; idempotent re-run produces zero diff.

### Bad

- **Bootstrap is one-shot (not re-runnable for new entries).** After bootstrap fires, new risk classes flow through the ADR-056 hint-and-drain path, NOT through bootstrap. Re-invocation of bootstrap is a no-op (idempotent file-existence). This is correct by design but creates a UX seam: users may expect bootstrap to "catch up" the catalog after long gaps. Mitigation: ADR-059 Reassessment Criteria includes a scheduled re-bootstrap surface if drift accumulates.
- **Citations may go dangling at 7-day `.risk-reports/` cleanup.** Bootstrap-derived entries cite reports that may be auto-purged. Acceptable per ADR-026 grounding-at-time-of-write semantics; the citation block remains valuable as historical provenance.
- **Install-updates auto-trigger ties bootstrap to user invoking install-updates.** Adopters who skip install-updates miss the bootstrap. Mitigation: per-action assessment carries a gentle nudge ("Risk register is empty; run `/install-updates` to bootstrap from `.risk-reports/`") — preserves AFK-safety since the nudge doesn't halt the loop. JTBD verdict J6.
- **Hybrid filter (slug-token-match primary, judgement fallback) requires both paths in the agent prompt.** ~40-line addition is non-trivial. Mitigation: ADR-052 behavioural-tests cover both paths; ADR-054 budget unchanged.
- **Phase 2b drain step lands across multiple consumer skills incrementally.** ADR-014 grain means each consumer skill is its own commit; full coverage rolls out across iters. Mitigation: AFK orchestrator (`/wr-itil:work-problems`) drain is the load-bearing first surface; other consumers add value but aren't gating.
- **Wipe pass deletes existing R001-R006 history at filesystem level.** Mitigation: git history preserves the deletion + rebuild as two commits; git log --follow recovers the trail.
- **JTBD wipe-counter-position not implemented.** JTBD verdict J4 recommended atomic in-ticket wipe; architect verdict I2 prevailed on two-pass validation grounds. The contested decision is recorded in `## Considered Options I` for traceability. Mitigation: if two-pass validation surfaces no gaps, the wipe commits land back-to-back making the JTBD-202 due-diligence experience nearly equivalent (same git log window, just two commits not one).

## Confirmation

### Source review (at implementation time) — 8 file targets

1. `docs/decisions/059-pipeline-consume-catalog-and-bootstrap-from-reports.proposed.md` — this file. Status `proposed`.
2. `docs/decisions/047-install-updates-scaffolds-governance-artefacts.proposed.md` `## Out of Scope` section has one-line forward pointer to ADR-059.
3. `packages/risk-scorer/agents/pipeline.md` has new `## Catalog Consumption Protocol` section. Risk-item format includes `Catalog baseline:` and `Catalog match:` lines. Per-run `CATALOG_HIT_RATE:` line emitted.
4. `packages/risk-scorer/skills/create-risk/SKILL.md` accepts `--slug <slug>` and `--prefill <prose>` flags. Flag-driven path skips AskUserQuestion. Existing human-invoked path preserved.
5. `packages/risk-scorer/skills/bootstrap-catalog/SKILL.md` exists; describes walk-`.risk-reports/`-once + slug-collapse + emit-`R<NNN>-<slug>.active.md` + `## Source Evidence` block. Maturity tag in frontmatter per ADR-053.
6. `packages/risk-scorer/skills/bootstrap-catalog/REFERENCE.md` exists with deep context (slug rules, source-evidence shape, idempotency contract).
7. `scripts/repo-local-skills/install-updates/SKILL.md` Step 6.5 has bootstrap auto-trigger logic. Step 7 final-report integration shows bootstrap line item.
8. `packages/itil/skills/work-problems/SKILL.md` gains a "Drain risk-register queue" step that consumes ADR-056 queue and invokes `/wr-risk-scorer:create-risk --slug --prefill`.

### Behavioural bats fixtures (per ADR-052; P081 behavioural-only assertion)

All fixtures below are **behavioural** per ADR-052 / P081 — each test exercises an observable end-to-end behaviour (slug emitted to queue, citation block populated, `CATALOG_HIT_RATE` line printed, file-existence under empty/populated state, etc.). NO structural grep on SKILL.md content; NO ADR-content asserts; NO "file exists" structural checks that don't exercise behaviour. P081 is the regression guard against test padding via grep-asserts.

- `packages/risk-scorer/agents/test/pipeline-consume-catalog.bats` — 6 cases:
  1. Catalog with 3 entries; diff matches slug for 1; verify pipeline emits `Catalog match: slug-token` for that risk-item.
  2. Catalog with 3 entries; diff doesn't slug-token-match any; verify judgement-fallback path fires AND logs `Catalog match: judgement`.
  3. Catalog with 3 entries; diff has no relevant matches; verify `Catalog match: none` for action-irrelevant entries.
  4. `Catalog baseline: R<NNN> residual=N/25 (Label)` line present in risk-item block when catalog match fires.
  5. `RISK_SCORES:` carries per-action residual NOT catalog lifetime baseline.
  6. `CATALOG_HIT_RATE: matched=N missed=M` line present in every report.

- `packages/risk-scorer/skills/create-risk/test/create-risk-flag-driven.bats` — 4 cases:
  1. `--slug=test-slug --prefill="Test description"` → writes `R<NNN>-test-slug.active.md` with Status `Active (auto-scaffolded — pending review)`, Description = prefill, Inherent / Residual = `not estimated — no prior data`, `## Source Evidence` block citing the originating queue line.
  2. Flag-driven path skips AskUserQuestion (no interactive prompt).
  3. Existing human-invoked path (no flags) preserved — fires AskUserQuestion for full authoring.
  4. ID-allocation algorithm (max of local + origin, +1) honoured under flag path.

- `packages/risk-scorer/skills/bootstrap-catalog/test/bootstrap-catalog.bats` — 6 cases:
  1. Empty catalog + corpus of 5 fixture `.risk-reports/` files producing 3 unique slugs → bootstrap emits 3 `R<NNN>-<slug>.active.md` files. Source-Evidence block in each cites the originating files.
  2. Idempotency: second run produces zero diff (file-existence test per slug; existing files preserved).
  3. Populated catalog (R001-R003 already present with matching slugs) + corpus of 5 fixture files → bootstrap appends to source-evidence blocks of existing files; no new R<NNN> files for matching slugs.
  4. Slug-collapse: 5 fixture files producing the same canonical slug collapse to ONE register entry; source-evidence cites all 5.
  5. Theme-coverage assertion: against the project's actual `.risk-reports/` corpus, ≥80% of the 12-14 themes from P167 gap analysis surface as register entries. (Run as repo-local validation, NOT as adopter test — the assertion is project-specific.)
  6. Empty `.risk-reports/` + present `RISK-POLICY.md` → bootstrap exits cleanly with "no reports to walk" message; no files written.

- `scripts/repo-local-skills/install-updates/test/install-updates-bootstrap-trigger.bats` — 4 cases:
  1. Sibling with `RISK-POLICY.md` + empty `docs/risks/` + non-empty `.risk-reports/` → bootstrap fires; Step 7 report shows bootstrap row.
  2. Sibling with `RISK-POLICY.md` + populated `docs/risks/` + non-empty `.risk-reports/` → bootstrap does NOT fire (catalog already populated); Step 7 report shows skip row with reason.
  3. Sibling with `RISK-POLICY.md` + empty `docs/risks/` + empty `.risk-reports/` → bootstrap does NOT fire (no source corpus); Step 7 report shows skip row with reason.
  4. Sibling without `RISK-POLICY.md` → no bootstrap (Phase 1 ADR-047 gate already covers this).

**Total: 20 behavioural bats cases across 4 fixture files.** Plus 6 work-problems orchestrator drain-step cases tracked under that surface's existing fixture (or new `packages/itil/skills/work-problems/test/work-problems-drain-risk-queue.bats`) — final aggregate ~26 cases.

### Behavioural replay (manual, post-merge) — 5 steps

1. Run `/wr-risk-scorer:bootstrap-catalog` against this repo (catalog populated with R001-R006). Verify it appends to source-evidence blocks rather than emitting new files for matching slugs.
2. Wipe R001-R006 (`git mv ... .retired.md`); run `/wr-risk-scorer:bootstrap-catalog`. Verify N register entries emitted with source-evidence blocks citing originating `.risk-reports/` files.
3. Run `/wr-itil:work-problems` AFK loop. Verify the loop's drain step consumes any queued hints from ADR-056's queue and invokes `/wr-risk-scorer:create-risk --slug --prefill` programmatically. Queue truncates after drain.
4. Run a per-action assessment (`/wr-risk-scorer:assess-wip`). Verify pipeline emits `Catalog match:` and `Catalog baseline:` lines in the risk-item block. Verify `CATALOG_HIT_RATE:` line emitted.
5. Run `/install-updates` against a fresh sibling project with `RISK-POLICY.md` and non-empty `.risk-reports/`. Verify Step 6.5 bootstrap fires; Step 7 final report shows bootstrap row.

## Reassessment Criteria

Revisit this decision if:

- **Catalog hit rate stays below 30% on second-and-subsequent assessments 3+ months post-implementation.** Signal: slug rules are too narrow OR diff-token-matching is too brittle. Tighten / extend the hybrid filter; consider judgement path as primary.
- **Bootstrap fires on adopter project but produces fewer register entries than the gap-analysis-baseline 12-14 themes from P167.** Signal: slug-collapse is too aggressive (over-deduping distinct risk classes). Refine ADR-056 slug rules; add slug-collision-detection.
- **Slug collisions cause register fragmentation > 5% false positives.** Signal: slug rules need refinement OR the substring-match fallback should be the primary slug-match path. Tighten via ADR-056 amendment.
- **Per-action assessment latency exceeds JTBD-001 60-second budget.** Signal: consume-catalog protocol's hybrid filter is too expensive. Reduce judgement-path scope; cache catalog reads; consider scheduled / batched consume-catalog.
- **Adopter `docs/risks/` populate-rate stays near zero 3+ months post-Phase-2b release.** Signal: drain step coverage in consumer skills is insufficient OR ADR-056 hint surface isn't firing as expected. Audit hint-emission rate; expand drain coverage.
- **Auto-scaffolded entries stay pending-review indefinitely.** Signal: curation skill (`/wr-risk-scorer:review-register`) is needed. Build it.
- **Bootstrap one-shot semantics prove too rigid** — users want incremental re-bootstrap after long gaps. Signal: scheduled re-bootstrap UX surfaces. Add a `--force` flag or a scheduled job; revisit one-shot decision.
- **`/wr-risk-scorer:bootstrap-catalog` on-demand surface is unused (install-updates auto-trigger covers all cases).** Signal: redundant safety net. Remove on-demand skill or keep as documented fallback.
- **Citations to dangling `.risk-reports/` files cause confusion.** Signal: provenance-at-time-of-write is insufficient. Add a snapshot mechanism (copy report content into the source-evidence block) or extend the cleanup TTL.
- **Install-updates Step 6.5 auto-trigger fires on adopters who don't want bootstrap.** Signal: false-positive trigger. Add `.claude/.risk-bootstrap-declined` marker honoured by the trigger condition (parallels ADR-036's `.intake-scaffold-declined`).
- **JTBD wipe-counter-position regression** — if architect's two-pass validation surfaces gaps that JTBD's atomic-pair approach would have avoided (signal: register coverage drops measurably between wipe-commit and bootstrap-commit; users complain about visible gap in audit trail). Revisit verdict I2; consider reverting to atomic wipe-pair shape.

## Related

- **P168** — driver ticket; this ADR's Decision Outcome covers P168's Investigation Tasks A-I + J1-J6.
- **P167** — parent ticket; corrected the policy framing this ADR's bootstrap implements at runtime.
- **P033** — original 99%-miss-rate ticket; ADR-059 is part of P033's multi-phase fix (alongside ADR-047 Phase 1 + ADR-056 Phase 2a).
- **P102 / P110** — sibling tickets in the back-channel triplet; consumers of this ADR's auto-write surface.
- **ADR-013** — Rule 5 (policy-authorised silent proceed) authorises the orchestrator-side auto-invoke of create-risk on hint consumption.
- **ADR-014** — single-commit grain authority. Implementation lands across 2-3 commits, NOT one mega-edit.
- **ADR-015** — pure-scorer contract; preserved for pipeline agent.
- **ADR-022** — problem lifecycle; bootstrap-derived entries enter as `Active (auto-scaffolded — pending review)` per ADR-056 pattern.
- **ADR-026** — grounding sentinel for `not estimated — no prior data` scoring fields on bootstrap-derived entries; provenance citation pattern.
- **ADR-036** — direct precedent for dual-surface scaffold pattern (on-demand skill + auto-trigger from host skill).
- **ADR-038** — progressive disclosure; bootstrap skill ships SKILL.md + REFERENCE.md.
- **ADR-040** — SessionStart read-mostly contract; rules out SessionStart firing surface (verdict A1 rejected).
- **ADR-042** — auto-apply scorer remediations; orchestrator-side auto-invoke is a Rule 5 policy-authorised action.
- **ADR-044** — framework-mediated lifecycle authority; hint-to-register-entry materialisation is a P132 mechanical-stage carve-out.
- **ADR-047** — Phase 1 directory scaffold (parent). One-line forward pointer in `## Out of Scope` cross-references this ADR.
- **ADR-049** — plugin script resolution via `$PATH bin/`; bootstrap skill helper scripts ride this convention.
- **ADR-052** — behavioural-tests default; all 26 fixture cases are behavioural per P081.
- **ADR-053** — plugin maturity taxonomy; new bootstrap-catalog skill ships with `proposed` maturity tag.
- **ADR-054** — SKILL.md runtime budget; pipeline.md + create-risk SKILL.md + new bootstrap-catalog SKILL.md all stay within budget.
- **ADR-055** — namespace-prefixed permalinks; new skill's published ID is `/wr-risk-scorer:bootstrap-catalog`.
- **ADR-056** — sibling ADR (Phase 2a queue-write contract). Slug primitive + queue-and-drain pattern reused without modification.
- **ADR-057** — three-phase declarative-first cluster rollout; ADR-059 implementation rides similar Phase-1/2/3 cadence (pragmatic ADR-014 grain, NOT a full ADR-057 cluster).
- **JTBD-001** — primary fit (governance enforced without slowing down). Missed-risk-class hazard IS a JTBD-001 desired-outcome failure.
- **JTBD-006** — AFK transparency + safe-defaults binding constraint. Bootstrap idempotent and non-interactive.
- **JTBD-007** — Step 7 final-report integration on install-updates auto-trigger.
- **JTBD-202** — pre-flight governance check; catalog IS the structured/auditable/ISO-citable artefact.
- **`RISK-POLICY.md`** — `## Risk Catalog` section landed in commit `9e339d0` is the policy this ADR implements at runtime.
- **`packages/risk-scorer/agents/pipeline.md`** — implementation site for consume-catalog protocol.
- **`packages/risk-scorer/skills/create-risk/SKILL.md`** — implementation site for `--slug` + `--prefill` flag extension.
- **`packages/risk-scorer/skills/bootstrap-catalog/SKILL.md`** — new skill implementation site.
- **`scripts/repo-local-skills/install-updates/SKILL.md`** — Step 6.5 auto-trigger extension site.
- **`packages/itil/skills/work-problems/SKILL.md`** — first orchestrator drain step site (Phase 2b first surface).
- **`docs/risks/README.md`** — register index; updated by bootstrap and per-action drain.
- **`docs/risks/TEMPLATE.md`** — bootstrap-derived entries instantiate from this template + Source Evidence block.
- **`.afk-run-state/risk-register-queue.jsonl`** — ADR-056 queue artefact; consumed by Phase 2b drain.
- **`.risk-reports/`** — corpus walked by bootstrap; cited in Source Evidence blocks.
