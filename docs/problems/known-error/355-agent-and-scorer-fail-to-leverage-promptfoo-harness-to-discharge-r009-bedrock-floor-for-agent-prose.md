# Problem 355: agent + risk-scorer fail to leverage the promptfoo behavioural harness (RFC-012/ADR-075) to discharge the R009 bedrock floor for agent/skill-prose changes

**Status**: Known Error (root cause confirmed; fix shipped in AFK iter 2026-06-04 via RFC-019 — R009 catalog amendment + `packages/risk-scorer/agents/pipeline.md` control-vocabulary extension + first reference slice `packages/itil/skills/report-upstream/eval/promptfooconfig.yaml` + the held P270 changeset reinstated from holding on the new discharge path; awaiting `@windyroad/itil` + `@windyroad/risk-scorer` patch release for `Verifying-by-release` transition per ADR-022 P143 fold-fix)
**Reported**: 2026-06-04 (user correction, FFS-class: *"FFS we built the harness. Have you forgotten?"*)
**Release vehicle**: `.changeset/wr-itil-p355-promptfoo-discharges-r009-prose-floor.md` (`@windyroad/itil` patch) + `.changeset/wr-risk-scorer-p355-pipeline-credits-promptfoo-for-r009.md` (`@windyroad/risk-scorer` patch)
**Priority**: 12 (High) — Impact: 4 (Significant — the R009 "no behavioural harness for agent-prose" floor is the dominant above-appetite driver for every orchestrator-layer SKILL/ADR-prose change this session: P344, P351, P308, P270 all hit 8/25 and got moved-to-holding on a floor the project ELIMINATED when it shipped promptfoo. Every one of those holds may be unnecessary) × Likelihood: 4 (Likely — fires on every prose-surface risk assessment until the scorer + agent internalise the harness as the discharge path)
**Origin**: internal
**Persona**: developer
**JTBD**: JTBD-001
**Effort**: M (risk-scorer agent.md + RISK-POLICY R009 catalog entry amendment to name promptfoo Tier-A/B as the behavioural-harness control that discharges the floor + agent-side habit)
**WSJF**: 6.0 (12 × 1.0 / 2)

## Description

User correction 2026-06-04 (FFS-class): *"FFS we built the harness. Have you forgotten?"* — in response to the agent proposing a default-OFF feature-flag as the mitigation for the P270 push's R009 bedrock floor (8/25 above appetite), when the actual mitigation is the promptfoo behavioural harness shipped THIS SESSION (RFC-012 / ADR-075, which closed P012).

The R009 (functional-defects-in-shipped-behaviour) bedrock floor sits at 8/25 with the standing justification "the irreducible residual is the LLM-prose verdict surface, which has no behavioural harness yet (P176 / P012)". That justification was TRUE until RFC-012 S6 landed the promptfoo SKILL-prose eval harness + ADR-075 amended scope to cover both agent-prose AND skill-prose. P012 is CLOSED. The harness EXISTS.

So the R009 bedrock floor for agent/skill-prose changes is no longer irreducible: a promptfoo Tier-A (deterministic) + Tier-B (llm-rubric pass^k) eval for the changed prose IS the behavioural evidence that discharges the floor. The agent + the risk-scorer both failed to reach for it — the agent proposed a feature-flag workaround; the scorer scored 8/25 citing the absent-harness floor that is no longer absent.

This is a forgot-our-own-capability class: the project built a tool to solve exactly this problem, then immediately failed to use it when the problem recurred.

## Symptoms

- Risk-scorer scores agent/skill-prose changes at the R009 bedrock floor (8/25) citing "no behavioural harness for the LLM-prose surface".
- Agent proposes workarounds (feature-flags, move-to-holding-for-time, default-off gating) instead of writing a promptfoo eval.
- Above-appetite holds accumulate (P344, P351, P308, P270 this session) on a floor the project eliminated.
- The promptfoo harness (RFC-012, ADR-075) sits unused for the exact surface it was built for.

## Workaround

Write a promptfoo eval for the changed prose by hand; cite it as the R009 behavioural-harness control in the next risk assessment.

## Impact Assessment

- **Who is affected**: every orchestrator-layer SKILL/ADR-prose change's risk assessment. Persona: developer. JTBD: JTBD-001 (enforce governance without slowing down — the unnecessary holds slow delivery).
- **Frequency**: every prose-surface change scored against R009. 4+ instances this session alone (P344/P351/P308/P270).
- **Severity**: High. The whole point of building the harness (RFC-012, substantial multi-iter investment) was to discharge this floor. Not using it wastes the investment AND accumulates unnecessary holds.
- **Analytics**: count of holds attributed to R009-bedrock-no-harness since RFC-012 landed = the unnecessary-hold backlog.

## Root Cause Analysis

### Hypotheses

1. **RISK-POLICY R009 catalog entry not updated post-RFC-012**: the R009 entry (`docs/risks/R009-*.active.md`) still names the absent harness as the irreducible floor. The scorer reads the catalog; the catalog is stale; the scorer floors at 8.

2. **risk-scorer agent.md doesn't name promptfoo as the R009 discharge control**: the agent's control vocabulary for R009 lists bats (deterministic) but not promptfoo Tier-A/B (behavioural prose). So the agent can't credit a promptfoo eval as a likelihood-reducing control.

3. **Agent (orchestrator) habit**: the agent reaches for workarounds (flags, holds) rather than "write the eval that discharges the floor" because the harness is new and not yet in the reflexive toolkit.

4. **No standing reminder that P012 closed / harness exists**: nothing surfaces "the behavioural-harness gap is closed; use promptfoo for prose surfaces" at risk-assessment time.

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Amend `docs/risks/R009-*.active.md`: the behavioural-harness-absent floor is discharged by a promptfoo Tier-A/B eval (RFC-012/ADR-075) for the changed prose. Update the residual baseline + control list.
- [ ] Amend `packages/risk-scorer/agents/*.md` (pipeline agent): add promptfoo Tier-A/B as an R009 likelihood-reducing control for agent/skill-prose surfaces.
- [ ] Re-assess the holds taken this session on the R009-no-harness floor (P344, P351, P308, P270): can they reinstate now if a promptfoo eval is written for each? (Likely follow-on per-hold work.)
- [ ] Agent-habit: at risk-assessment time for prose surfaces, the discharge path is "write the promptfoo eval", not "flag/hold/defer".

## Fix Strategy

**Kind**: improve (catalog + agent-vocabulary correction) + the immediate P270 application

**Shape**:

1. **R009 catalog amendment** (`docs/risks/R009-*.active.md`): name promptfoo Tier-A/B (RFC-012/ADR-075) as the behavioural-harness control that discharges the previously-irreducible LLM-prose floor. The floor was irreducible PRE-RFC-012; post-RFC-012 a promptfoo eval is the discharge.

2. **risk-scorer agent.md amendment**: add promptfoo Tier-A/B to the R009 control vocabulary for agent/skill-prose surfaces.

3. **Immediate P270 application**: write a promptfoo eval for the ADR-024 external-comms-gated auto-file behaviour; cite it; re-score P270 push (expected to drop below appetite); reinstate the P270 changeset from holding.

4. **Re-assess sibling holds** (P344, P351, P308): each can reinstate if a promptfoo eval is written. Per-hold follow-on.

## Dependencies

- **Blocks**: efficient delivery of every orchestrator-layer prose change (currently all hold unnecessarily on the discharged floor).
- **Blocked by**: (none — the harness exists).
- **Composes with**: RFC-012 (the harness this ticket says to USE), ADR-075 (promptfoo adoption + amended SKILL-prose scope), P012 (closed — the harness-gap ticket), P176 (agent-side coverage gap — partially addressed by RFC-012), P324 (no-behavioural-harness-for-agent-verdicts — the RFC-012 driver), the R009 standing risk entry, the held cohort P344/P351/P308/P270.

## Related

- 2026-06-04 user correction (FFS-class, this capture's authoring context): *"FFS we built the harness. Have you forgotten?"*
- **RFC-012** — the promptfoo agent-prose + SKILL-prose eval harness this ticket says to leverage. Shipped this session; closed P012.
- **ADR-075** — promptfoo adoption decision (amended 2026-06-02 to cover SKILL prose).
- **P012** (closed) — the master harness-gap ticket; closed by RFC-012 S6.
- **P324** — no behavioural harness for agent-verdicts — RFC-012's driving problem.
- **P176** — agent-side I2 coverage gap; behavioural enforcement awaits the harness (now exists).
- **P344 / P351 / P308 / P270** — the held cohort this session, all on the R009-no-harness floor that is now discharged. Candidates for reinstate-after-eval.
- **R009** (`docs/risks/R009-functional-defects-in-shipped-behaviour.active.md`) — the standing risk entry whose floor justification is stale post-RFC-012.

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-019 | proposed | P355 — promptfoo Tier-A/B eval discharges the R009 bedrock floor for SKILL/agent-prose surfaces |
