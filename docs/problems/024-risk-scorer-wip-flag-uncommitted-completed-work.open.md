# Problem 024: Risk-scorer WIP mode should flag uncommitted completed work and encourage commits

**Status**: Open
**Reported**: 2026-04-16
**Priority**: 8 (Medium) — Impact: Minor (2) x Likelihood: Likely (4)

## Description

The risk-scorer WIP mode (`packages/risk-scorer/agents/wip.md`) assesses risk of uncommitted changes by reading the current diff and codebase context. However, it does not distinguish between "work in progress" (genuinely incomplete changes) and "completed work that hasn't been committed yet" (finished changes sitting in the working tree).

When a governance skill completes a unit of work (e.g., manage-problem transitions a problem to Known Error, or implements a SKILL.md fix) but does not commit, the risk-scorer WIP assessment should:
1. Detect that the changes represent completed work (not WIP)
2. Flag the uncommitted state as risk — completed work in the working tree is at risk of loss
3. Encourage the user (or skill) to commit immediately to reduce WIP and feed the pipeline

Currently, the WIP scorer treats all uncommitted changes equally. It doesn't apply back-pressure to encourage committing completed work, missing an opportunity to reinforce the lean release principle.

## Symptoms

- Risk-scorer WIP assessments after a governance-skill completes work do not distinguish "done but uncommitted" from "genuinely in progress".
- No `RISK_VERDICT` signal encourages committing completed work — the scorer only flags risk of the changes themselves, not risk of leaving them uncommitted.
- The pipeline (commit → risk-score → release) stalls silently when completed work isn't committed, because the scorer has no visibility into work that should be flowing.

## Workaround

User commits manually. The risk-scorer then assesses the committed changes normally.

## Impact Assessment

- **Who is affected**:
  - Solo-developer persona (JTBD-002 Ship with Confidence) — uncommitted completed work is a pipeline blind spot.
  - Tech-lead persona — no audit trail of when work was completed vs when it was committed.
- **Frequency**: Every time a governance skill completes work without committing (which is the current default per P023).
- **Severity**: Low. The pipeline still works once the user commits. This is an optimisation to reduce WIP dwell time.
- **Analytics**: Observed this session — after P021 manage-problem fix, changes sat uncommitted with no risk-scorer signal to commit.

## Root Cause Analysis

### Investigation Tasks

- [ ] Read `packages/risk-scorer/agents/wip.md` — understand the current WIP assessment template and what signals it reads.
- [ ] Determine how the WIP scorer could detect "completed work" vs "WIP". Candidates: presence of problem-file transitions in the diff, SKILL.md edits paired with problem-doc updates, git status showing only governance artefact changes.
- [ ] Design a `RISK_VERDICT` signal for "completed-work-uncommitted" — e.g., `RISK_VERDICT: COMMIT` (a new verdict type, distinct from CONTINUE/PAUSE).
- [ ] Ensure this integrates with P023 (once governance skills commit automatically, this scorer signal becomes a safety net for cases where auto-commit is skipped or fails).

## Related

- `packages/risk-scorer/agents/wip.md` — WIP assessment agent
- P023: `docs/problems/023-governance-skills-should-commit-completed-work.open.md` — governance skills should commit; this problem is the scorer-side complement
- JTBD-002: `docs/jtbd/solo-developer/JTBD-002-ship-with-confidence.proposed.md`
- RISK-POLICY.md — risk appetite and pipeline gate framing
