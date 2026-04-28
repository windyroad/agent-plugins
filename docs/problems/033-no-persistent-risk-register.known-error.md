# Problem 033: No persistent risk register for ISO 31000 / ISO 27001 compliance

**Status**: Known Error
**Reported**: 2026-04-17
**Priority**: 9 (Med) — Impact: Moderate (3) x Likelihood: Possible (3)
**Effort**: L
**WSJF**: 4.5 — (9 × 2.0) / 4 → now known-error

## Description

The risk scorer performs per-change pipeline risk assessment against `RISK-POLICY.md` thresholds, but there is no persistent risk register — a living inventory of identified risks with owners, treatment plans, and residual risk tracking. Both ISO 31000 (general risk management) and ISO 27001 (information security) expect a risk register as a core artifact.

`RISK-POLICY.md` defines the *criteria* (impact/likelihood scales, appetite). `.risk-reports/` contains point-in-time snapshots. `docs/problems/` tracks ITIL problems. None of these is a risk register.

The user wants this kept lean — ideally a `docs/risks/` directory with one file per risk and a `README.md` index (mirroring the `docs/problems/` pattern), rather than a heavyweight spreadsheet or database.

## Symptoms

- No single place to see all standing risks, their current treatment status, and residual scores
- RISK-POLICY.md defines what to measure but not what has been measured
- ISO 31000 clause 6.4.2 (risk treatment) and ISO 27001 clause 6.1.2/6.1.3 (risk assessment / Statement of Applicability) have no backing artifact
- Pipeline risk reports in `.risk-reports/` are ephemeral — they assess a change, not a standing risk

## Workaround

Until the register is populated, risks are implicitly captured across `RISK-POLICY.md` impact examples, problem tickets, and pipeline reports. The scaffolding (directory + README + TEMPLATE) now exists — risks can be added one-by-one as they are identified; there is no requirement to populate the register exhaustively up front.

## Impact Assessment

- **Who is affected**:
  - Tech-lead persona — needs auditability; a risk register is a standard audit artifact
  - Solo-developer persona (JTBD-001 Enforce Governance Without Slowing Down) — governance tooling should model risk management, not just risk scoring
- **Frequency**: Every audit or compliance review; every time someone asks "what are our standing risks?"
- **Severity**: Medium — the pipeline scorer still works; the gap is in persistent risk tracking, not in per-change assessment
- **Analytics**: Identified during discussion of ISO 31000 and ISO 27001 requirements this session

## Root Cause Analysis

### Confirmed Root Cause

The risk-scorer plugin was designed for pipeline risk (per-change scoring at commit/push/release gates). A persistent risk register was never in scope — the plugin solves "is this change risky?" not "what risks does this project carry?" The absence is structural, not accidental: there is no directory, template, or skill targeting standing-risk capture.

### Investigation Tasks

- [x] Design a lean `docs/risks/` directory structure: one `.md` file per risk, `README.md` index with risk matrix summary — **Done**. Pattern mirrors `docs/problems/`: `R<NNN>-<kebab-title>.<status>.md` with status suffixes `.active.md` / `.accepted.md` / `.retired.md`. README carries the register table, retired table, ISO mapping, and relationship-to-other-artefacts diagram.
- [x] Define the risk file template: ID, title, category (ISO 27001 infosec / ISO 31000 general), inherent score, controls, residual score, owner, treatment (accept/mitigate/transfer/avoid), review date — **Done**. `docs/risks/TEMPLATE.md` documents the full field set with inherent vs residual scoring, Controls section citing implementation sources (files or ADRs), Treatment section (Accept/Mitigate/Transfer/Avoid), Monitoring triggers, and Change Log.
- [x] Decide whether risk register management belongs in the risk-scorer plugin or a new plugin — **Deferred to future work**. Current scaffolding is pure docs; no skill is needed for v1 (users add risks manually via file creation, same as ADRs). If/when automation is required, decision can be made then with a concrete use case. Not a blocker for the register to be useful.
- [x] Decide whether the risk-scorer `update-policy` skill should seed the register from RISK-POLICY.md impact examples — **No for v1**. RISK-POLICY.md "Severe" examples (e.g., "publishes packages with malicious/broken bin scripts", "leaks npm auth tokens via CI logs") are candidate risks but seeding them mechanically risks false-positives. Leave seeding manual until a curated first-pass of risks has been written; then consider automation.
- [x] Consider whether the register should be auto-populated from problem tickets — **No — inverse direction is correct**. Problems are concrete defects that may be *realisations* of standing risks; each risk's `Realised-as` section links to relevant problems. Auto-populating risks from problems would conflate the two levels. Manual curation preserves the distinction.

### Fix Strategy

Lean scaffolding only — no automation for v1:

1. Create `docs/risks/` directory
2. Create `docs/risks/README.md` as the register index with empty register/retired tables, ISO mapping, structural diagram, and "How to add/review" instructions
3. Create `docs/risks/TEMPLATE.md` documenting the risk file format
4. Leave the register empty — populate incrementally as risks are identified (same philosophy as ADRs and problems)

Future work (not in scope for this problem):
- Skill to create/review risks (analogous to `create-adr` / `manage-problem`)
- Linkage from risk-scorer pipeline reports to the register (e.g., above-appetite reports suggest candidate risks)
- ISO 27001 Statement of Applicability derived from the register

## Fix Released

Implemented 2026-04-17:
- `docs/risks/README.md` — register index with ISO 31000 / ISO 27001 clause mapping, empty register and retired tables, structural relationship diagram, and authoring/review instructions
- `docs/risks/TEMPLATE.md` — per-risk file template covering inherent risk, controls, residual risk, treatment (Accept/Mitigate/Transfer/Avoid), monitoring, related artefacts, and change log

Awaiting user verification that the scaffolding matches intent before populating the register with initial risks.

## Related

- `RISK-POLICY.md` — defines risk criteria but not the risk inventory
- `.risk-reports/` — ephemeral per-change assessments
- `docs/problems/` — ITIL problem management (similar directory-of-files pattern reused here)
- `docs/risks/README.md` — the new register index
- `docs/risks/TEMPLATE.md` — per-risk file template
- `packages/risk-scorer/` — current risk scoring plugin; could host a future register-management skill
- P034 (`docs/problems/034-centralise-risk-reports-for-cross-project-skill-improvement.open.md`) — centralising ephemeral `.risk-reports/` to `~/.claude/`; may share the same centralised storage infrastructure
- P102 (`docs/problems/102-no-invocation-surface-for-risk-register.open.md`) — follow-up ticket captures the deferred population mechanism. Surfaced 2026-04-22 after the user observed the register had stayed empty for 5 days in Verification Pending. P033's Fix Strategy explicitly deferred the invocation surface to "future work"; P102 is that future work made concrete.

## Regression Evidence (2026-04-28 — user-surfaced verification failure)

User-directed reopen during interactive `/wr-itil:manage-problem` session. User report verbatim: *"have a look at the sibling projects that we install into. None of them have risks documented in doc/risks, so that feature isn't working"*. User confirmed *"yes, P033 is what I'm talking about"* — direct verification failure of the P033 / P102 / P110 fix triplet (all currently in Verifying).

### Sibling-project survey (2026-04-28)

Surveyed 7 adopter projects on the user's machine (those with `@windyroad/*` plugins enabled in `.claude/settings.json`):

| Project | RISK-POLICY.md | docs/risks/ scaffolded | docs/risks/*.md count | .risk-reports/ count |
|---------|---------------|------------------------|----------------------|---------------------|
| addressr-mcp | yes | NO | 0 | 32 |
| addressr-react | yes | NO | 0 | 20 |
| addressr | yes | yes (scaffolded but empty) | 0 | 37 |
| bbstats | yes | yes | 3 | 74 |
| luxury-escapes-interview | no | NO | 0 | 0 |
| very-fetching | yes | NO | 0 | 22 |
| windyroad | yes | NO | 0 | 70 |

**Aggregate**: 6/7 projects have `RISK-POLICY.md`. ALL 6 have `.risk-reports/` accumulating (per-change risk-scoring is working). Only **1/6 has populated `docs/risks/`** (bbstats with 3 risks). 4/6 don't even have `docs/risks/` scaffolded. The risk REGISTER is not getting populated despite ~285 cumulative pipeline risk reports across all six projects suggesting plenty of register-worthy events.

### Why the fix triplet hasn't closed the gap

The Verification Queue claims P033 / P102 / P110 are fixed:
- **P033** — `docs/risks/` directory + README + TEMPLATE scaffolded (passive scaffolding via `/wr-risk-scorer:create-risk` skill). But the scaffolding doesn't auto-fire on adopter projects — 4/6 don't have the directory at all.
- **P102** — `/wr-risk-scorer:create-risk` skill ships as the invocation surface. But the skill is opt-in — agents/users have to know to invoke it. No discovery path on adopter projects.
- **P110** — `RISK_REGISTER_HINT:` passive trigger from `wr-risk-scorer:pipeline` agent emits hints that should prompt register entry creation. But the hint is consumed at the orchestrator/assistant level — agents in adopter sessions either don't see it or don't act on it (every adopter session that produced a `.risk-reports/` entry was a candidate; 285 cumulative reports vs ~3 register entries = ~99% miss rate).

**The actual gap**: there is no install-updates-time scaffolding of `docs/risks/` in adopter projects, AND there is no on-pipeline-fire behavioural enforcement that creates a register entry when above-appetite residual / confidentiality / user-stated-precondition signals fire. The triplet shipped the *plumbing* but not the *trigger that actually pulls the register into existence*.

### Fix candidates

1. **Install-updates Step X**: when an adopter project has `RISK-POLICY.md` but no `docs/risks/`, scaffold the directory + README + TEMPLATE on next install-updates run. Idempotent (skip if `docs/risks/` exists). Composes-with ADR-036 (downstream OSS intake scaffold) but at a different surface.
2. **Post-pipeline-fire enforcement**: when `wr-risk-scorer:pipeline` emits `RISK_REGISTER_HINT:`, the calling skill (e.g. `/wr-risk-scorer:assess-release`, `/wr-itil:work-problems` Step 6.5, `/wr-itil:manage-problem` Step 11) MUST follow up with an explicit `/wr-risk-scorer:create-risk` invocation. Today the hint is advisory; the consumption is unenforced.
3. **Pipeline back-channel** (P110 candidate b — re-evaluate): the `wr-risk-scorer:pipeline` agent itself writes the register entry (not just hint) when above-appetite residual fires. Trades agent-side autonomy for guaranteed population. Architect-design call.
4. **Behavioural test**: a contract assertion that a session producing a `.risk-reports/` entry above appetite ALSO produces a `docs/risks/R<NNN>-*.active.md` entry within the same session. Today there is no such assertion, so the gap persists.

### Implications for P033 / P102 / P110

All three should arguably reopen alongside P033. Per ADR-022, "Verification Pending" means "fix released, awaiting user verification" — the user has now verified the fix DOESN'T work. Reverting to Known Error is the correct lifecycle move. P102 and P110 are siblings that need the same treatment for the same reason; an architect-design call decides whether to bundle the reopen-and-fix in one ticket or split.

### Next iter shape

This ticket (P033 known-error) drives the next implementation iter. Architect verdict on which fix candidate(s) to ship — lean toward (1) install-updates scaffolding (cheap, idempotent, immediate adopter-project benefit) AND (2) post-pipeline-fire enforcement (closes the trigger gap that's the root cause of the 99% miss rate). Defer (3) and (4) to follow-on iters if (1) + (2) prove insufficient.


### User direction refinement (2026-04-28, mid-investigation): 1:N report→register mapping

Verbatim user direction: *"for each risk mentioned in the .risk-reports, there should be something in the risk register"*.

This refines the fix scope and elevates **Fix candidate 3 (pipeline back-channel)** to load-bearing. The contract:

- Every `.risk-reports/<timestamp>.md` entry that identifies an inherent risk (regardless of residual classification) MUST correspond to a `docs/risks/R<NNN>-*.active.md` entry.
- The mapping is **N reports : 1 register entry** — recurring risks (e.g. "session-context-budget-exhaustion" appearing in 50+ reports across many sessions) collapse to ONE register entry that all matching reports cite.
- The register entry is the **standing-risk record**; the reports are point-in-time evidence. The register tracks the inherent/residual scoring, controls applied, and treatment decision; the reports are timestamps proving the risk has fired.
- New register entries SHOULD be created automatically by the `wr-risk-scorer:pipeline` agent when a report identifies a risk that doesn't yet have a register entry. Existing entries SHOULD have their evidence-log updated (a new "fired-on" timestamp + a citation back to the report file).

**Fix-implementation implications**:

- The P110 RISK_REGISTER_HINT mechanism is necessary but not sufficient — hints alone preserve the 99% miss rate observed in the survey. The pipeline agent itself must take action.
- Architect-design call: does the pipeline agent (a) write the register entry directly, or (b) emit a structured directive that the calling skill (`/wr-risk-scorer:assess-release`, etc.) MUST consume by invoking `/wr-risk-scorer:create-risk` before continuing? Trade-off: agent-side autonomy vs. orchestrator-side enforcement.
- The fix needs an audit step: a one-time backfill pass over existing `.risk-reports/` to identify all distinct risks (deduplicate by risk-name) and create register entries for each one. Without this, the register stays empty even after the trigger lands. The backfill is per-project (each adopter project runs it once on next session start, gated by a marker so it doesn't re-fire).
- Behavioural test (Fix candidate 4 elevation): contract assertion that every risk-id appearing in `.risk-reports/*.md` has a matching `docs/risks/R<NNN>-*.md` entry. This becomes a load-bearing test, not just a future polish item.
- Install-updates scaffolding (Fix candidate 1) remains needed for the 4/6 projects that don't even have `docs/risks/` — the back-channel can't write into a non-existent directory.

**Effort re-estimate**: original L estimate may need to inflate to XL given the new scope (back-channel + backfill + behavioural test + install-updates scaffolding + cross-plugin coordination between risk-scorer, install-updates, and any consumer skill). Architect verdict at next-iter time confirms or trims.

