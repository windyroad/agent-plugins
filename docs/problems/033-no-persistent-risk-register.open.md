# Problem 033: No persistent risk register for ISO 31000 / ISO 27001 compliance

**Status**: Open
**Reported**: 2026-04-17
**Priority**: 9 (Med) — Impact: Moderate (3) x Likelihood: Possible (3)

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

Risks are implicitly captured across RISK-POLICY.md impact examples, problem tickets, and pipeline reports. No unified view exists.

## Impact Assessment

- **Who is affected**:
  - Tech-lead persona — needs auditability; a risk register is a standard audit artifact
  - Solo-developer persona (JTBD-001 Enforce Governance Without Slowing Down) — governance tooling should model risk management, not just risk scoring
- **Frequency**: Every audit or compliance review; every time someone asks "what are our standing risks?"
- **Severity**: Medium — the pipeline scorer still works; the gap is in persistent risk tracking, not in per-change assessment
- **Analytics**: Identified during discussion of ISO 31000 and ISO 27001 requirements this session

## Root Cause Analysis

### Preliminary Hypothesis

The risk-scorer plugin was designed for pipeline risk (per-change scoring at commit/push/release gates). A persistent risk register was never in scope — the plugin solves "is this change risky?" not "what risks does this project carry?"

### Investigation Tasks

- [ ] Design a lean `docs/risks/` directory structure: one `.md` file per risk, `README.md` index with risk matrix summary
- [ ] Define the risk file template: ID, title, category (ISO 27001 infosec / ISO 31000 general), inherent score, controls, residual score, owner, treatment (accept/mitigate/transfer/avoid), review date
- [ ] Decide whether risk register management belongs in the risk-scorer plugin or a new plugin
- [ ] Decide whether the risk-scorer `update-policy` skill should seed the register from RISK-POLICY.md impact examples
- [ ] Consider whether the register should be auto-populated from problem tickets (problems with security implications → infosec risks)

## Related

- `RISK-POLICY.md` — defines risk criteria but not the risk inventory
- `.risk-reports/` — ephemeral per-change assessments
- `docs/problems/` — ITIL problem management (similar directory-of-files pattern the user wants to reuse)
- `packages/risk-scorer/` — current risk scoring plugin; may host the register management
- P034 (`docs/problems/034-centralise-risk-reports-for-cross-project-skill-improvement.open.md`) — centralising ephemeral `.risk-reports/` to `~/.claude/`; may share the same centralised storage infrastructure
