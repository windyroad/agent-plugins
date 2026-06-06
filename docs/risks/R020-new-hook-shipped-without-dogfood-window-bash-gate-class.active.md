# Risk R020: New Hook Shipped Without Dogfood Window Bash Gate Class

**Status**: Active (auto-scaffolded — pending review)
**Category**: <!-- pending review — auto-scaffolded from pipeline hint -->
**Identified**: 2026-05-17
**Owner**: pending review
**Last reviewed**: 2026-05-17
**Next review**: 2026-05-17
**Curation**: pending review (auto-scaffolded 2026-05-17)

## Description

P232 Bash polling-antipattern PreToolUse hook landing for first time without held-area dogfood; R003 new-hook modulator pushes residual to 8/Medium

> Auto-scaffolded by the Phase 2b drain (ADR-056) from a `wr-risk-scorer:pipeline`
> RISK_REGISTER_HINT bullet. The description is the agent's prefill; scoring
> fields below carry the ADR-026 ungrounded-output sentinel until human curation.

## Recogniser

**Path patterns** (any match → consider this entry):

- `packages/*/hooks/*.sh` (new file, PreToolUse:Bash matcher)
- `packages/*/hooks/hooks.json` (new `PreToolUse:Bash` registration)
- `.changeset/*.md` (paired with new Bash-gate AND no `docs/changesets-holding/` sibling)

**Diff-content keywords** (any match → consider):

- `PreToolUse:Bash`, `"matcher": "Bash"`, `Bash|Write|Edit`
- `polling-antipattern`, `polling`, `sleep`, `until`
- new-file additions under `packages/*/hooks/` declaring `PreToolUse:Bash`

**Anti-patterns** (looks like R020 but isn't):

- Existing Bash-gate modification (no new-hook landing) → standard **R003**
- SessionStart additionalContext hook → score as **R026/R027** (SessionStart class — exit-0-always envelope differs)
- PreToolUse hook with non-Bash matcher (e.g. Write/Edit/Read) → score as **R015** generic new-hook class
- New Bash-gate WITH paired `docs/changesets-holding/` dogfood window → controls firing; routine R003

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

- 2026-05-16T12:03:11Z: fired in `.risk-reports/2026-05-16T12-03-11-commit.md` (reason: above-appetite-residual)

## Change Log

- 2026-05-17: Auto-scaffolded by Phase 2b drain (ADR-056). Pending human curation.
