# Risk R087: Oversight Content Hash Ignores Body Status Mirror False Unratified

**Status**: Active (auto-scaffolded — pending review)
**Category**: <!-- pending review — auto-scaffolded from pipeline hint -->
**Identified**: 2026-08-21
**Owner**: pending review
**Last reviewed**: 2026-08-21
**Next review**: 2026-08-21
**Curation**: pending review (auto-scaffolded 2026-08-21)

## Description

Released itil@0.60.0 `oversight_content_hash` excludes frontmatter `status:` and normalises criterion ticks but not the `**Status**:` body mirror every story template carries, so accepting a genuinely-ratified story drifts its hash and the no-implement gate blocks its own implementation; standing residual above appetite (Impact 3 x Likelihood 5 almost-certain, reproduced by two controlled experiments); fix reverted deliberately because changing the algorithm invalidates 30 stored hashes, whose discharge is either P348 hollow-marker mass re-marking or a maintainer-owned legacy-hash fallback decision.

> Auto-scaffolded by the Phase 2b drain (ADR-056) from a `wr-risk-scorer:pipeline`
> RISK_REGISTER_HINT bullet. The description is the agent's prefill; scoring
> fields below carry the ADR-026 ungrounded-output sentinel until human curation.

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

- 2026-07-29T13:40:46Z: fired in `.risk-reports/2026-07-29T13-40-46-commit.md` (reason: above-appetite-residual)

## Change Log

- 2026-08-21: Auto-scaffolded by Phase 2b drain (ADR-056). Pending human curation.
