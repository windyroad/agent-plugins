# Risk R022: Phase 3A Shipped Ahead Of Held Phase 2 Dependencies

**Status**: Active (auto-scaffolded — pending review)
**Category**: <!-- pending review — auto-scaffolded from pipeline hint -->
**Identified**: 2026-05-17
**Owner**: pending review
**Last reviewed**: 2026-05-17
**Next review**: 2026-05-17
**Curation**: pending review (auto-scaffolded 2026-05-17)

## Description

Phase 3a populate-script changeset authored into .changeset/ while its Phase 2a + Phase 2b NDJSON-producer dependencies remain held in docs/changesets-holding/; precondition chain 2a→2b→3a→3b inverted at the release queue.

> Auto-scaffolded by the Phase 2b drain (ADR-056) from a `wr-risk-scorer:pipeline`
> RISK_REGISTER_HINT bullet. The description is the agent's prefill; scoring
> fields below carry the ADR-026 ungrounded-output sentinel until human curation.

## Recogniser

**Path patterns** (any match → consider this entry):

- `.changeset/*.md` AND `docs/changesets-holding/*.md` simultaneously where the active bodies cite a later Phase than the held bodies
- `.changeset/*.md` bodies citing `Phase N` while sibling holding bodies cite `Phase N-1`

**Diff-content keywords** (any match → consider):

- `Phase 2a`, `Phase 2b`, `Phase 3a`, `Phase 3b`
- `precondition chain`, `precondition`
- `NDJSON producer`, `producer`, `consumer`
- `inverted at the release queue`

**Anti-patterns** (looks like R022 but isn't):

- Active Phase chain has NO held siblings (all Phases on the active path) → no inversion possible; routine **R005**
- Single-Phase ticket (no chain semantics) → routine **R005**
- Phase 3a + Phase 2 in same active batch (atomic ship) → controls firing; no inversion

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

- 2026-05-17T06:55:25Z: fired in `.risk-reports/2026-05-17T06-55-25-commit.md` (reason: user-stated-precondition)

## Change Log

- 2026-05-17: Auto-scaffolded by Phase 2b drain (ADR-056). Pending human curation.
