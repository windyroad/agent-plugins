# Risk R027: New Sessionstart Hook Shipped Without Dogfood Window

**Status**: Active (auto-scaffolded — pending review)
**Category**: <!-- pending review — auto-scaffolded from pipeline hint -->
**Identified**: 2026-05-31
**Owner**: pending review
**Last reviewed**: 2026-05-31
**Next review**: 2026-05-31
**Curation**: pending review (auto-scaffolded 2026-05-31)

## Description

Graduating p283 oversight changeset ships architect-oversight-nudge.sh SessionStart hook to adopters with the held-changeset dogfood control deliberately removed; release residual 6/25 Medium. Standing class (R003 first-landing modulator); already partially scaffolded as R015/R019/R021 — recommend consolidating into R003's per-action modulator table rather than a new entry.

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

- 2026-05-25T21:32:11Z: fired in `.risk-reports/2026-05-25T21-32-11-commit.md` (reason: above-appetite-residual)

## Change Log

- 2026-05-31: Auto-scaffolded by Phase 2b drain (ADR-056). Pending human curation.
