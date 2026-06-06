# Risk R016: Release Batch R009 Skill Prose Concentration Above Appetite

**Status**: Active (auto-scaffolded — pending review)
**Category**: <!-- pending review — auto-scaffolded from pipeline hint -->
**Identified**: 2026-05-17
**Owner**: pending review
**Last reviewed**: 2026-05-17
**Next review**: 2026-05-17
**Curation**: pending review (auto-scaffolded 2026-05-17)

## Description

13-changeset P170 Phase 2 release batch dominated by skill-prose-rewrite class on load-bearing surfaces; R009 catalog baseline (8/Medium) reproduces at per-action level and warrants release-cadence treatment per feedback_release_cadence.md

> Auto-scaffolded by the Phase 2b drain (ADR-056) from a `wr-risk-scorer:pipeline`
> RISK_REGISTER_HINT bullet. The description is the agent's prefill; scoring
> fields below carry the ADR-026 ungrounded-output sentinel until human curation.

## Recogniser

**Path patterns** (any match → consider this entry; release-stage class — looks at the cohort, not a single file):

- `.changeset/*.md` (count: ≥5 in the release batch)
- `packages/*/skills/*/SKILL.md` (multiple in the same release cohort — concentration signal)
- `packages/*/skills/*/REFERENCE.md`
- `packages/*/agents/*.md` (when prose-rewrite shape)

**Diff-content keywords** (any match → consider):

- `skill-prose-rewrite`, `release batch`, `release cadence`
- batch-size signals (≥5 changesets, ≥3 SKILL.md files)
- load-bearing surface markers (`PreToolUse`, `gate`, `oversight`)

**Anti-patterns** (looks like R016 but isn't):

- Single SKILL.md edit (batch-size 1) → routine **R009** per-action; no concentration class
- Release batch dominated by structural / refactor changes (not prose-rewrite) → score per-action against the relevant specialisation, not R016
- SKILL/agent-prose with paired promptfoo Tier-A/B coverage across the cohort → R009 modulator firing; concentration class discharged

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

- 2026-05-12T11:56:56Z: fired in `.risk-reports/2026-05-12T11-56-56-commit.md` (reason: above-appetite-residual)

## Change Log

- 2026-05-17: Auto-scaffolded by Phase 2b drain (ADR-056). Pending human curation.
