# Problem 033: No persistent risk register for ISO 31000 / ISO 27001 compliance

**Status**: Verification Pending
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
