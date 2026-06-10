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

## Recogniser

**Path patterns** (any match → consider this entry):

- `packages/*/hooks/*.sh` (new file, SessionStart event)
- `packages/*/hooks/*-nudge.sh`, `packages/*/hooks/*-oversight*.sh` (canonical SessionStart nudge naming)
- `packages/*/hooks/hooks.json` (new SessionStart event registration)
- `.changeset/*.md` paired with new SessionStart hook AND no `docs/changesets-holding/` sibling

**Diff-content keywords** (any match → consider):

- `SessionStart`
- `additionalContext`, `hookSpecificOutput`
- `nudge`, `oversight`
- `exit 0` self-suppressing envelope on the SessionStart path
- new-file additions under `packages/*/hooks/` declaring `SessionStart`

**Anti-patterns** (looks like R026 but isn't):

- PreToolUse:Bash matcher (not SessionStart) → score as **R020** Bash-gate class instead
- PreToolUse:Edit/Write hook → score as **R015** generic new-hook class
- Existing SessionStart hook *modification* → standard **R003** (no first-landing modulator)
- New SessionStart hook WITH paired `docs/changesets-holding/` dogfood window → controls firing

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
- 2026-06-08T07:07:17Z: fired in `.risk-reports/2026-06-08T07-07-17-commit.md` (reason: above-appetite-residual)

## Change Log

- 2026-05-31: Auto-scaffolded by Phase 2b drain (ADR-056). Pending human curation.
