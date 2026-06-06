# Risk R030: New Deny Surface Shipped Direct To Changeset No Dogfood

**Status**: Active (auto-scaffolded — pending review)
**Category**: <!-- pending review — auto-scaffolded from pipeline hint -->
**Identified**: 2026-05-31
**Owner**: pending review
**Last reviewed**: 2026-05-31
**Next review**: 2026-05-31
**Curation**: pending review (auto-scaffolded 2026-05-31)

## Description

external-comms-gate adds `git commit -m` deny surface shipping direct-to-.changeset without held-area dogfood window; R003 modulator + R009 bedrock floor stack at 8/Medium; precedent R015/R019/R020 already capture adjacent patterns

> Auto-scaffolded by the Phase 2b drain (ADR-056) from a `wr-risk-scorer:pipeline`
> RISK_REGISTER_HINT bullet. The description is the agent's prefill; scoring
> fields below carry the ADR-026 ungrounded-output sentinel until human curation.

## Recogniser

**Path patterns** (any match → consider this entry):

- `packages/*/hooks/*.sh` (PreToolUse, with new `permissionDecision: "deny"` matcher)
- `packages/*/hooks/external-comms*.sh` (canonical instance — external-comms gate)
- `.changeset/*.md` (paired with new deny-surface AND no `docs/changesets-holding/` sibling)

**Diff-content keywords** (any match → consider):

- `permissionDecision`, `"deny"`, `deny surface`
- `git commit -m` (canonical instance matcher target)
- `external-comms-gate`, `external-comms`
- new-file additions OR new-matcher additions to existing hook adding deny semantics

**Anti-patterns** (looks like R030 but isn't):

- Existing deny-surface *modification* (e.g. expanding an allowlist) → standard **R003**
- Deny surface WITH paired `docs/changesets-holding/` dogfood window → controls firing; routine R003
- Advisory-only (no deny — `additionalContext` only) → score as **R026/R015** new-hook class, not deny-surface class
- Deny surface scope narrowing / loosening (R003 reductions) → score as routine R003 modification

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

- 2026-05-31T06:39:25Z: fired in `.risk-reports/2026-05-31T06-39-25-commit.md` (reason: above-appetite-residual)

## Change Log

- 2026-05-31: Auto-scaffolded by Phase 2b drain (ADR-056). Pending human curation.
