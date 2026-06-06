# Risk R025: External Adopter Name In Public Repo Ticket Prose

**Status**: Active (auto-scaffolded — pending review)
**Category**: <!-- pending review — auto-scaffolded from pipeline hint -->
**Identified**: 2026-05-31
**Owner**: pending review
**Last reviewed**: 2026-05-31
**Next review**: 2026-05-31
**Curation**: pending review (auto-scaffolded 2026-05-31)

## Description

P286 ticket body names a specific external adopter project ("exceeds 9" appetite example) in a public-repo-bound docs/problems file; the external-comms gate controls do not cover the docs/problems/*.md Edit/Write path, leaving this disclosure class uncontrolled at that surface

> Auto-scaffolded by the Phase 2b drain (ADR-056) from a `wr-risk-scorer:pipeline`
> RISK_REGISTER_HINT bullet. The description is the agent's prefill; scoring
> fields below carry the ADR-026 ungrounded-output sentinel until human curation.

## Recogniser

**Path patterns** (any match → consider this entry):

- `docs/problems/*.md` (ticket prose written to disk — public repo)
- `docs/risks/*.md` (register entries that might cite external project names)
- `docs/decisions/*.md` (ADR bodies)
- `docs/incidents/*.md`
- `docs/rfcs/*.md`, `docs/stories/*.md`
- `CHANGELOG.md`, `packages/*/CHANGELOG.md`
- (any public-repo-bound `docs/**/*.md` that bypasses the external-comms hook gate)

**Diff-content keywords** (any match → consider):

- Specific external adopter / customer / employer names known to the project
- `external adopter`, `adopter project`, `customer`
- proper-noun project / company names that don't appear in this repo's public README

**Anti-patterns** (looks like R025 but isn't):

- Edit reuses a placeholder / redaction marker (`<adopter-redacted>`, `External Adopter A`, `$ADOPTER`) → controls applied
- Outbound prose (gh issue body / PR body / changeset / advisory) — the external-comms hook DOES gate that surface → score as routine R001 with controls firing
- Internal-only file (not in `docs/`, not published, not in `.changeset/`) → not in the disclosure path

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

- 2026-05-24T16:17:21Z: fired in `.risk-reports/2026-05-24T16-17-21-commit.md` (reason: confidentiality-disclosure)

## Change Log

- 2026-05-31: Auto-scaffolded by Phase 2b drain (ADR-056). Pending human curation.
