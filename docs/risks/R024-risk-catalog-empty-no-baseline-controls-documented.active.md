# Risk R024: Risk Catalog Empty No Baseline Controls Documented

**Status**: Active (auto-scaffolded — pending review)
**Category**: <!-- pending review — auto-scaffolded from pipeline hint -->
**Identified**: 2026-05-17
**Owner**: pending review
**Last reviewed**: 2026-05-17
**Next review**: 2026-05-17
**Curation**: pending review (auto-scaffolded 2026-05-17)

## Description

docs/risks/ is empty while .risk-reports/ has accumulated corpus; bootstrap needed so per-action assessments can ground in catalog baselines

> Auto-scaffolded by the Phase 2b drain (ADR-056) from a `wr-risk-scorer:pipeline`
> RISK_REGISTER_HINT bullet. The description is the agent's prefill; scoring
> fields below carry the ADR-026 ungrounded-output sentinel until human curation.

## Recogniser

**Path patterns** (any match → consider this entry; this is an adopter-bootstrap-state class, not a per-edit class):

- `docs/risks/` (empty or near-empty: zero or one `R*.active.md` file)
- `.risk-reports/` (accumulated: ≥5 `*.md` reports)
- `RISK-POLICY.md` (present — policy exists but no register)

**Diff-content keywords** (any match → consider):

- `catalog empty`, `register empty`, `no baseline`
- `bootstrap`, `bootstrap-catalog`
- `per-action`, `baseline controls`

**Anti-patterns** (looks like R024 but isn't):

- Register populated (≥ ~5 `R*.active.md` entries) → no longer applies; retire this entry for the adopter
- Register present but `RISK-POLICY.md` absent → score as different bootstrap-state class (no appetite criteria)
- Per-action assessment that grounds in catalog baselines → controls firing; not catalog-empty class

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

- 2026-05-17T08:39:08Z: fired in `.risk-reports/2026-05-17T08-39-08-commit.md` (reason: user-stated-precondition)

## Change Log

- 2026-05-17: Auto-scaffolded by Phase 2b drain (ADR-056). Pending human curation.
