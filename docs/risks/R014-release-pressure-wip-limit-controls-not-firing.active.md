# Risk R014: Release Pressure Wip Limit Controls Not Firing

**Status**: Active (auto-scaffolded — pending review)
**Category**: <!-- pending review — auto-scaffolded from pipeline hint -->
**Identified**: 2026-05-17
**Owner**: pending review
**Last reviewed**: 2026-05-17
**Next review**: 2026-05-17
**Curation**: pending review (auto-scaffolded 2026-05-17)

## Description

I002 declares release-pressure / WIP-limit controls failing to fire — 32-commit unpushed backlog standing risk pending paired remediation

> Auto-scaffolded by the Phase 2b drain (ADR-056) from a `wr-risk-scorer:pipeline`
> RISK_REGISTER_HINT bullet. The description is the agent's prefill; scoring
> fields below carry the ADR-026 ungrounded-output sentinel until human curation.

## Recogniser

**Path patterns** (any match → consider this entry; this is a process-state class rather than a file-edit class):

- `.risk-reports/*-push.md` (push-stage reports where unpushed-commit count is the load-bearing signal)
- `RISK-POLICY.md` (WIP-limit thresholds + appetite)
- `docs/incidents/*.md` (I002 driver-incident class)

**Diff-content keywords** (any match → consider):

- `WIP-limit`, `release-pressure`, `unpushed backlog`
- numeric thresholds in commit-count signals (e.g., `>20 unpushed`)
- `I002`, `feedback_release_cadence`

**Anti-patterns** (looks like R014 but isn't):

- Single commit / small batch → no WIP-limit triggered; routine R005
- Large batch graduated atomically by orchestrator (held cohort releasing intentionally) → controls firing; not WIP-limit failure
- Commit-time view only (no push-cumulative lens) → score against R009/R003 inherent, not R014

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

- 2026-05-10T12:39:35Z: fired in `.risk-reports/2026-05-10T12-39-35-commit.md` (reason: user-stated-precondition)

## Change Log

- 2026-05-17: Auto-scaffolded by Phase 2b drain (ADR-056). Pending human curation.
