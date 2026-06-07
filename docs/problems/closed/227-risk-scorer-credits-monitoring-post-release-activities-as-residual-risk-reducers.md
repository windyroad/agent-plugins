# Problem 227: Risk scorer credits monitoring/post-release activities as residual-risk reducers

**Status**: Closed (superseded — agent-prose category-error fix already shipped 2026-04-18 commit `0edec54`)
**Reported**: 2026-05-15
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Description

The risk-scorer agent's residual-risk computation lists post-release activities (monitoring, rollback readiness) as "controls" that reduce the residual score. This is a category error: a control reduces inherent risk *before* a change ships (a test that exercises the failure mode locally); monitoring is detection-after-fact and doesn't reduce the probability of the bad outcome occurring.

## Investigation Tasks

- [x] Re-rate Priority and Effort at next /wr-itil:review-problems — moot at closure (Closed tickets excluded from WSJF ranking).
- [x] Audit risk-scorer agent prompts + RISK-POLICY.md: only pre-shipping controls credit the residual reduction. Monitoring + rollback readiness belong in a separate "detection-and-recovery" category that doesn't lower the residual score. — **Shipped** in commit `0edec54` (2026-04-18, `fix(risk-scorer): monitoring is not a control`) across `packages/risk-scorer/agents/{pipeline,plan,wip}.md`.
- [x] Behavioural test asserting monitoring-only controls don't reduce residual. — **Shipped** in same commit as `packages/risk-scorer/agents/test/risk-scorer-monitoring-not-a-control.bats` (6 assertions, 2 per agent file).

## Related

- **Reported Upstream**: https://github.com/windyroad/agent-plugins/issues/56
- **Pipeline classification**: safe-low-fix-risk; route=safe-and-valid.
- **Affected plugin**: @windyroad/risk-scorer.

## Closed as superseded — agent-prose fix already shipped

**Closed on**: 2026-06-08 (via `/wr-itil:work-problems` AFK iter)

**Superseding commit**: `0edec54` `fix(risk-scorer): monitoring is not a control` (2026-04-18, ~four weeks BEFORE P227 was reported). The commit message identified the same category error verbatim: *"Scorers defaulted to crediting them because they are risk-management activities — but they only detect failures after they have reached users. Crediting them reduced residual risk scores without actually reducing the risk of a failure reaching production. 329-report corpus analysis across consumer projects showed this producing false confidence in risky releases."*

P227 (reported 2026-05-15) was a duplicate observation of the same defect; the upstream-mirror intake batch (#56) imported it without the duplicate check catching that the fix was already in main.

**Evidence shape** (ADR-079 Phase 2 shape 3 — duplicate-of-X / shape 2 — work-shipped-confirmed; ADR-026 cite + persist + uncertainty):

- **Cite (pipeline agent)**: `packages/risk-scorer/agents/pipeline.md` lines 365-370 — "**Monitoring is not a control.** Monitoring, alerting, dashboards, and any other post-release detection activity MUST NOT be credited as a control that reduces residual risk. Post-release detection does NOT reduce pre-release risk — it only shortens the time to notice a failure after it has already reached users. A genuine control exercises the failure scenario BEFORE the change ships: a test, a CI gate, a feature flag, a preview verification, an architect review, an installer dry-run. Monitoring and rollback readiness may be listed separately as 'post-release follow-ups' outside the residual risk computation, but MUST NOT appear in a Controls list and MUST NOT reduce any inherent risk score." This prose carves out exactly the "detection-and-recovery" category P227 Investigation Task #2 asked for — post-release follow-ups can be listed, but outside the residual computation.
- **Cite (plan agent)**: `packages/risk-scorer/agents/plan.md` lines 78-82 — identical rule, scoped to plan-level residual risk. Symmetric coverage so per-plan scoring is not a back-door around the per-action rule.
- **Cite (wip agent)**: `packages/risk-scorer/agents/wip.md` lines 112-115 — identical rule, scoped to wip-state risk-nudge. Symmetric coverage so per-edit nudge is not a back-door around the per-action rule.
- **Cite (behavioural test)**: `packages/risk-scorer/agents/test/risk-scorer-monitoring-not-a-control.bats` — 6 grep assertions (2 per agent file: "monitoring is not a control" present + "post-release detection forbidden as risk reduction" present). Tagged ADR-005 / P011 Permitted Exception (structural assertions on the LLM-prose surface; promptfoo Tier-A/B eval is the behavioural follow-up under RFC-012 / ADR-075 if the prose were ever to drift). The test file's setup block already references P038 (the historical-numbering equivalent of this issue) as the driver — the bats correctly anticipated the duplicate-observation surface.
- **Cite (RISK-POLICY.md)**: P227 Investigation Task #2 also asked for the policy to make the distinction explicit. RISK-POLICY.md § "Control Composition" line 169 already constrains rollback-class controls: *"Most controls reduce likelihood, not impact. A control that constrains blast radius (rollback, version pinning, audit log) MAY reduce impact by 1 band — only with explicit rationale in the risk file's `## Treatment` section."* The "explicit rationale" requirement keeps rollback-capability (a design-class control) distinct from rollback-readiness (post-release follow-up, which the agent prompts forbid). The agent-prose prohibition is the load-bearing surface; the policy carries the impact-band qualifier.
- **Persist**: this closure section + the cited commit SHA + the agent-prose line ranges + the bats file path form the durable audit trail. Reversibility: re-open by `git mv` back to `docs/problems/known-error/` and remove this section if the "monitoring is not a control" prose is later weakened or removed (any such weakening becomes the regression signal; the bats would also fail).
- **Uncertainty**: external-comms.md and inbound-report.md (the two `:external-comms` / `:inbound-report` sibling agents) do not carry the "monitoring is not a control" prose. This is by design — those agents do not score per-action diff residual; they assess prose content for confidentiality leaks (outbound) or two-axis attack-intent + fix-risk (inbound). The category error P227 named applies only to per-action diff scoring, which is the pipeline/plan/wip surface. No coverage gap on the two intentionally-narrow-scope sibling agents.

The Description above describes the exact defect class that `0edec54` closed. No further work on P227 advances the system state beyond what the agent-prose fix + behavioural bats already delivered. KE→Closed direct per ADR-079 lifecycle extension (ADR-079 Phase 2 shape 3 duplicate-of-X + shape 2 work-shipped). No code change. Upstream issue https://github.com/windyroad/agent-plugins/issues/56 should be closed with the same resolution body. Reversible via `/wr-itil:transition-problem 227 known-error`.
