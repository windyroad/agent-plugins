# Risk R021: New User Facing Surface No Dogfood Window

**Status**: Active (auto-scaffolded — pending review)
**Category**: <!-- pending review — auto-scaffolded from pipeline hint -->
**Identified**: 2026-05-17
**Owner**: pending review
**Last reviewed**: 2026-05-17
**Next review**: 2026-05-17
**Curation**: pending review (auto-scaffolded 2026-05-17)

## Description

New user-facing diagnostic surface (`wr-itil-skill-invocations`) ships without in-repo dogfood window; R009 specialisation where exit-0-always envelope shrinks impact but the no-prior-evidence likelihood floor holds residual at Medium. Recurring shape: applies to every new ITIL script/bin shim under `packages/itil/scripts/` + `packages/itil/bin/`.

> Auto-scaffolded by the Phase 2b drain (ADR-056) from a `wr-risk-scorer:pipeline`
> RISK_REGISTER_HINT bullet. The description is the agent's prefill; scoring
> fields below carry the ADR-026 ungrounded-output sentinel until human curation.

## Recogniser

**Path patterns** (any match → consider this entry):

- `packages/*/scripts/*.sh` (new file — user-invokable diagnostic surface)
- `packages/*/bin/*` (new shim wrapper)
- `packages/itil/scripts/*.sh`, `packages/itil/bin/*` (the canonical instance class)
- `.changeset/*.md` (paired with new user-facing shim AND no `docs/changesets-holding/` sibling)

**Diff-content keywords** (any match → consider):

- `wr-itil-*`, `wr-*-skill-invocations`, diagnostic shim names
- `#!/usr/bin/env bash` on a new-file shim under `bin/`
- `exit 0` self-suppressing envelope on the shim's outer path
- new-file additions under `packages/*/{scripts,bin}/`

**Anti-patterns** (looks like R021 but isn't):

- Hook surface (under `packages/*/hooks/`) → score as **R015 / R020 / R026** (hook class) — different runtime envelope
- Existing shim *modification* → standard **R009** (no first-landing modulator)
- Internal-only helper script (not user-invokable, not shimmed in `bin/`) → routine **R009**
- New user-facing shim WITH paired `docs/changesets-holding/` dogfood window → controls firing

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

- 2026-05-16T12:30:21Z: fired in `.risk-reports/2026-05-16T12-30-21-commit.md` (reason: above-appetite-residual)

## Change Log

- 2026-05-17: Auto-scaffolded by Phase 2b drain (ADR-056). Pending human curation.
