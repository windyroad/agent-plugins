# Risk R042: Hook Source Change Direct To Changeset No Dogfood Window

**Status**: Active (auto-scaffolded — pending review)
**Category**: <!-- pending review — auto-scaffolded from pipeline hint -->
**Identified**: 2026-06-10
**Owner**: pending review
**Last reviewed**: 2026-06-10
**Next review**: 2026-06-10
**Curation**: pending review (auto-scaffolded 2026-06-10)

## Description

R003-class hook-source change to load-bearing push/release gate landing direct-to-`.changeset/` without held-area dogfood window — canonical 8/Medium pattern recurring across P082, P344, P351, P352, P204, P206, P208; existing R003 catalog covers it but the per-action modulator firing across 7+ recent changesets suggests the catalog baseline assumes a control (held-area) that orchestrator iters consistently skip, warranting a tighter default or a dedicated R<NNN> sub-class entry tracking the recurrence rate.

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

- 2026-06-06T12:23:22Z: fired in `.risk-reports/2026-06-06T12-23-22-commit.md` (reason: above-appetite-residual)

## Change Log

- 2026-06-10: Auto-scaffolded by Phase 2b drain (ADR-056). Pending human curation.
