# Risk R029: R009 Agent Prose Verdict Surface No Llm Harness

**Status**: Active (auto-scaffolded — pending review)
**Category**: <!-- pending review — auto-scaffolded from pipeline hint -->
**Identified**: 2026-05-31
**Owner**: pending review
**Last reviewed**: 2026-05-31
**Next review**: 2026-05-31
**Curation**: pending review (auto-scaffolded 2026-05-31)

## Description

New jtbd `[Unratified Dependency]` verdict-prose ships at 8/25 Medium; LLM agent-prose surface has no behavioural harness (P176/P012), keeping R009 above the 4/Low appetite — standing class until the master prose harness lands.

> Auto-scaffolded by the Phase 2b drain (ADR-056) from a `wr-risk-scorer:pipeline`
> RISK_REGISTER_HINT bullet. The description is the agent's prefill; scoring
> fields below carry the ADR-026 ungrounded-output sentinel until human curation.

## Recogniser

**Path patterns** (any match → consider this entry; the R009 prose-surface specialisation):

- `packages/*/agents/*.md` (any agent verdict surface)
- `packages/*/skills/*/SKILL.md` (when SKILL prose itself drives a verdict — same harness gap)
- Absence of paired `packages/*/agents/*/eval/promptfooconfig.yaml`
- Absence of paired `packages/*/agents/test/*.bats` (or equivalent harness)

**Diff-content keywords** (any match → consider):

- `verdict`, `agent-prose`, `verdict surface`
- `LLM judge`, `LLM-driven verdict`
- `P176`, `P012` (driver tickets)
- absence of paired `eval/`, `promptfoo`, harness signals

**Anti-patterns** (looks like R029 but isn't):

- Agent.md edit WITH paired `eval/promptfooconfig.yaml` AND `npx promptfoo eval` passes → R009 prose-floor discharged per ADR-075 + RFC-012; score normally
- Pure structural prose change (formatting, heading) with no verdict-semantics shift → routine **R009** refactor modulator
- Specifically jtbd build-upon-guard verdict → score as **R028** (specialisation)
- Specifically architect verdict surface (RFC-010) → score against the architect-side instance

## Inherent Risk

Impact × Likelihood *before* controls.

- **Impact**: not estimated — no prior data
- **Likelihood**: not estimated — no prior data
- **Inherent Score**: not estimated — no prior data
- **Inherent Band**: not estimated — no prior data

## Controls

- pending review — controls to be enumerated during curation.

## Residual Risk

Impact × Likelihood *after* controls.

- **Impact**: not estimated — no prior data
- **Likelihood**: not estimated — no prior data
- **Residual Score**: not estimated — no prior data
- **Residual Band**: not estimated — no prior data
- **Within appetite?**: pending — scoring not estimated

## Treatment

pending review — treatment decision deferred until scoring is curated.

## Monitoring

- **Trigger to re-assess**: any new pipeline hint with this risk_slug
- **Metrics**: count of `.risk-reports/` entries citing this slug

## Related

- Criteria: `RISK-POLICY.md`
- Realised-as: <!-- link to docs/problems/P<NNN> when known -->
- Treatment ADRs: <!-- link to docs/decisions/ADR-<NNN> when treatment lands -->

## Evidence Log

Auto-populated from `.risk-reports/` via Phase 2b drain.

- 2026-05-27T12:31:50Z: fired in `.risk-reports/2026-05-27T12-31-50-commit.md` (reason: above-appetite-residual)

## Change Log

- 2026-05-31: Auto-scaffolded by Phase 2b drain (ADR-056). Pending human curation.
