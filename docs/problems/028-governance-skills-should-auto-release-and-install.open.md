# Problem 028: Governance skills should auto-release and auto-install after completing fixes

**Status**: Open
**Reported**: 2026-04-16
**Priority**: 9 (Med) — Impact: Moderate (3) x Likelihood: Likely (3)

## Description

When a governance skill (e.g., `manage-problem work`) completes a fix — commits, creates a changeset, and closes the problem — it stops there. The user must then manually trigger `npm run push:watch`, merge the release PR via `npm run release:watch`, pull the marketplace, and reinstall the affected plugins before the fix takes effect in their Claude Code session.

This contradicts the lean release principle (ADR-014) and the "governance must not interrupt flow" constraint (JTBD-001 / JTBD-005). The fix is functionally complete but not usable until the user discovers and completes a 4-step release+install sequence.

Observed: after P027 fix was committed and closed, user stated "this should have released by itself. Maybe even installed."

## Symptoms

- After a governance skill fix is committed, the user must manually run `npm run push:watch`, then `npm run release:watch`, then pull the marketplace cache, then `claude plugin install` to pick up the new code.
- The problem closure commit includes a changeset but the release pipeline is not triggered automatically.
- The installed plugin continues running the old code until the manual install step is completed.

## Workaround

Run manually: `npm run push:watch` → merge PR via `npm run release:watch` → `claude plugin install <package>@windyroad --scope project`.

## Impact Assessment

- **Who is affected**: Solo-developer persona (JTBD-001, JTBD-005) — every governance skill fix session
- **Frequency**: Every time a governance skill fix is completed and released
- **Severity**: Medium — fix is complete but unusable; the 4-step manual sequence is friction that directly contradicts the "fast governance" premise
- **Analytics**: Observed this session after P027 fix

## Root Cause Analysis

### Preliminary Hypothesis

1. **Governance skills don't include a release step.** SKILL.md step 11 (commit) and the lean release principle (ADR-014) define committing as the terminal action — there is no subsequent "push, release, reinstall" step defined in the skill.
2. **No post-commit hook or automation** triggers the release pipeline after a governance commit.
3. **Plugin reinstall is manual.** `claude plugin install` must be run in a shell; no in-session trigger exists.

### Investigation Tasks

- [ ] Determine whether `push:watch` + `release:watch` + `plugin install` can be appended to the governance skill's step 11 (commit) as a standard post-commit sequence
- [ ] Check whether `claude plugin install` can be called from within the skill (via Bash) without session restart side-effects
- [ ] Consider whether this belongs in SKILL.md as a new step 12, or as a shared post-release hook across all governance skills
- [ ] Evaluate risk: auto-push + auto-release is irreversible — determine if a confirmation gate is appropriate

## Related

- ADR-014: `docs/decisions/014-governance-skills-commit-their-own-work.proposed.md` — lean release principle; this problem is the natural extension
- JTBD-001: `docs/jtbd/solo-developer/JTBD-001-enforce-governance.proposed.md` — "under 60 seconds" target
- JTBD-005: `docs/jtbd/solo-developer/JTBD-005-assess-on-demand.proposed.md` — must not leave task context
- P027: `docs/problems/027-manage-problem-work-flow-is-expensive.known-error.md` — preceded this; P027 fix required manual release+install
