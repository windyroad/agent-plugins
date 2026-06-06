# Risk R013: Rfc 001 Chain Atomicity Paired Capability Unmet

**Status**: Active (auto-scaffolded — pending review)
**Category**: <!-- pending review — auto-scaffolded from pipeline hint -->
**Identified**: 2026-05-17
**Owner**: pending review
**Last reviewed**: 2026-05-17
**Next review**: 2026-05-17
**Curation**: pending review (auto-scaffolded 2026-05-17)

## Description

User-stated precondition "entire RFC-001 commit chain ships or doesn't" with held Slices 2-3 framework code as paired capability not graduated; persists until RFC-001 reaches closed post-Slice-5 forward-dogfood

> Auto-scaffolded by the Phase 2b drain (ADR-056) from a `wr-risk-scorer:pipeline`
> RISK_REGISTER_HINT bullet. The description is the agent's prefill; scoring
> fields below carry the ADR-026 ungrounded-output sentinel until human curation.

## Recogniser

**Path patterns** (any match → consider this entry):

- `docs/rfcs/RFC-001-*.md` (specifically RFC-001)
- `docs/changesets-holding/*.md` (where bodies cite RFC-001 Slices 2 or 3)
- `.changeset/*.md` (where bodies cite RFC-001 Slices 4 or 5 while siblings remain held)
- `packages/*/{skills,agents,hooks}/*` files altering RFC-001 framework surfaces

**Diff-content keywords** (any match → consider):

- `RFC-001`, `Slice 2`, `Slice 3`, `Slice 4`, `Slice 5`
- `framework code`, `paired capability`, `forward-dogfood`
- `entire RFC-001 commit chain` (user-stated precondition phrasing)

**Anti-patterns** (looks like R013 but isn't):

- RFC-001 closed (post-Slice-5 graduation) → no longer applies; retire this entry
- Other RFC chain (RFC-002+) → score as **R012** (general RFC chain atomicity), not RFC-001-specific R013
- Single-Slice tweak that doesn't alter the framework surface → routine R005

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

- 2026-05-06T12:15:35Z: fired in `.risk-reports/2026-05-06T12-15-35-commit.md` (reason: user-stated-precondition)

## Change Log

- 2026-05-17: Auto-scaffolded by Phase 2b drain (ADR-056). Pending human curation.
