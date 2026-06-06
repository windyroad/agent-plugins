# Risk R023: Release Coordination Changeset Drift Phase 3A Ahead Of Phase 2

**Status**: Active (auto-scaffolded — pending review)
**Category**: <!-- pending review — auto-scaffolded from pipeline hint -->
**Identified**: 2026-05-17
**Owner**: pending review
**Last reviewed**: 2026-05-17
**Next review**: 2026-05-17
**Curation**: pending review (auto-scaffolded 2026-05-17)

## Description

Phase 3a release-coordination drift: dependent script ships before its NDJSON producers; held-area pattern available but not applied; symmetric-cohort hold is the controlling remediation.

> Auto-scaffolded by the Phase 2b drain (ADR-056) from a `wr-risk-scorer:pipeline`
> RISK_REGISTER_HINT bullet. The description is the agent's prefill; scoring
> fields below carry the ADR-026 ungrounded-output sentinel until human curation.

## Recogniser

**Path patterns** (any match → consider this entry; sibling specialisation of R022 — focus on R005 release coordination):

- `.changeset/*.md` (with Phase markers in body — `Phase Na`, `Phase Nb`)
- `docs/changesets-holding/*.md` (held siblings)
- Dependent source files (`packages/*/scripts/populate-*.sh`) shipping while NDJSON producers stay held

**Diff-content keywords** (any match → consider):

- `Phase 2a`, `Phase 2b`, `Phase 3a` (Phase-marker phrasing)
- `symmetric-cohort hold`, `cohort hold`
- `release coordination`, `release queue`
- `dependent script`, `producer`, `consumer`

**Anti-patterns** (looks like R023 but isn't):

- Pure dependency-graph violation INSIDE a Phase (no chain across Phases) → routine **R005**
- Atomic-cohort ship (all dependencies in same active batch) → controls firing; symmetric-cohort hold applied
- Dependent script + producers all in `docs/changesets-holding/` together → controls firing
- Specifically RFC-001 chain context → score as **R012/R013** RFC chain atomicity instead

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

- 2026-05-17T06:55:25Z: fired in `.risk-reports/2026-05-17T06-55-25-commit.md` (reason: above-appetite-residual)

## Change Log

- 2026-05-17: Auto-scaffolded by Phase 2b drain (ADR-056). Pending human curation.
