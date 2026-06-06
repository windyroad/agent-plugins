# Risk R028: Jtbd Build Upon Guard Agent Prose Verdict Residual Above Appetite

**Status**: Active (auto-scaffolded — pending review)
**Category**: <!-- pending review — auto-scaffolded from pipeline hint -->
**Identified**: 2026-05-31
**Owner**: pending review
**Last reviewed**: 2026-05-31
**Next review**: 2026-05-31
**Curation**: pending review (auto-scaffolded 2026-05-31)

## Description

New jtbd [Unratified Dependency] agent-prose verdict (RFC-011/P323) carries R009 bedrock residual 8/25 above 4/Low appetite; irreducible part is the LLM-driven verdict surface with no behavioural harness (P176/P012); twin of released RFC-010 architect surface.

> Auto-scaffolded by the Phase 2b drain (ADR-056) from a `wr-risk-scorer:pipeline`
> RISK_REGISTER_HINT bullet. The description is the agent's prefill; scoring
> fields below carry the ADR-026 ungrounded-output sentinel until human curation.

## Recogniser

**Path patterns** (any match → consider this entry):

- `packages/wr-jtbd/agents/*.md` (specifically the build-upon-guard / jtbd verdict surface)
- `packages/*/agents/*.md` when the prose declares an `[Unratified Dependency]` verdict label
- Adjacent `packages/wr-jtbd/skills/*/SKILL.md` calling the build-upon-guard verdict

**Diff-content keywords** (any match → consider):

- `[Unratified Dependency]`, `Unratified Dependency`
- `build-upon-guard`, `verdict`, `verdict-prose`
- `RFC-011`, `P323`, `P176`, `P012`

**Anti-patterns** (looks like R028 but isn't):

- Architect verdict surface (not jtbd) → twin **RFC-010 / different agent** — score against the architect-side instance, not R028
- Agent with paired promptfoo Tier-A/B eval per ADR-075 / RFC-012 → R009 prose-floor discharged; controls firing
- Pure refactor of agent.md prose (no verdict-semantics shift) → routine **R009** refactor modulator

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

- 2026-05-27T08:30:39Z: fired in `.risk-reports/2026-05-27T08-30-39-commit.md` (reason: above-appetite-residual)

## Change Log

- 2026-05-31: Auto-scaffolded by Phase 2b drain (ADR-056). Pending human curation.
