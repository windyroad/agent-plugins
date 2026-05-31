# Risk R026: New Sessionstart Hook First Landing No Dogfood Window

**Status**: Active (auto-scaffolded — pending review)
**Category**: <!-- pending review — auto-scaffolded from pipeline hint -->
**Identified**: 2026-05-31
**Owner**: pending review
**Last reviewed**: 2026-05-31
**Next review**: 2026-05-31
**Curation**: pending review (auto-scaffolded 2026-05-31)

## Description

New SessionStart nudge hook (architect-oversight-nudge.sh) lands direct into package without held-area dogfood; R003 new-hook modulator + absent dogfood control hold commit/push residual at 8/25 Medium. Distinct from R020 (PreToolUse:Bash gate class) — this is the SessionStart additionalContext class with exit-0-always self-suppressing envelope.

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

- 2026-05-24T22:06:33Z: fired in `.risk-reports/2026-05-24T22-06-33-commit.md` (reason: above-appetite-residual)

## Change Log

- 2026-05-31: Auto-scaffolded by Phase 2b drain (ADR-056). Pending human curation.
