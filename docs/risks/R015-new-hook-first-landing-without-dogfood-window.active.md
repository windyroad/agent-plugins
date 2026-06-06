# Risk R015: New Hook First Landing Without Dogfood Window

**Status**: Active (auto-scaffolded — pending review)
**Category**: <!-- pending review — auto-scaffolded from pipeline hint -->
**Identified**: 2026-05-17
**Owner**: pending review
**Last reviewed**: 2026-05-17
**Next review**: 2026-05-17
**Curation**: pending review (auto-scaffolded 2026-05-17)

## Description

New PreToolUse:Bash commit-gate hook landing direct to `.changeset/` instead of `docs/changesets-holding/`; R003 new-hook-landing modulator drives release-layer residual above appetite (8/25 Medium) despite full bats + architect/JTBD/risk-scorer green inside iter subprocess.

> Auto-scaffolded by the Phase 2b drain (ADR-056) from a `wr-risk-scorer:pipeline`
> RISK_REGISTER_HINT bullet. The description is the agent's prefill; scoring
> fields below carry the ADR-026 ungrounded-output sentinel until human curation.

## Recogniser

**Path patterns** (any match → consider this entry):

- `packages/*/hooks/*.sh` (new file, not modification — git-add-newfile signal)
- `packages/*/hooks/hooks.json` (new hook event registration)
- `.changeset/*.md` (when paired with new-hook source change AND no `docs/changesets-holding/` sibling)

**Diff-content keywords** (any match → consider):

- `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop`, `SessionStart`
- new-file additions (`new file mode` markers in diff)
- absence of paired `docs/changesets-holding/<hook>.md`

**Anti-patterns** (looks like R015 but isn't):

- Modification of existing hook → standard **R003** (no first-landing modulator)
- New hook with paired `docs/changesets-holding/` dogfood window → controls firing; score as routine R003
- New hook that only touches test fixtures (`packages/*/hooks/test/*.bats`) → score as **R009** test-coverage class

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

- 2026-05-11T13:29:38Z: fired in `.risk-reports/2026-05-11T13-29-38-commit.md` (reason: above-appetite-residual)

## Change Log

- 2026-05-17: Auto-scaffolded by Phase 2b drain (ADR-056). Pending human curation.
