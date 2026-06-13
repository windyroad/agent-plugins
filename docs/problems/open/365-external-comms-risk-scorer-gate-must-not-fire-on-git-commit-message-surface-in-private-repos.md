# Problem 365: external-comms risk-scorer gate must not fire on git-commit-message surface in private repos

**Status**: Open
**Reported**: 2026-06-11
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-001, JTBD-101
**Persona**: plugin-developer

## Description

External-comms risk-scorer gate must NOT fire on `git-commit-message` surface in private repositories. Cross-project witness from `a separate private adopter repo` (private repo) where the gate blocked a commit message draft, surfacing the BLOCKED stderr directive identical to the public-repo path. Commit messages in private repos are not external-facing comms by any policy class and the gate fire is a pure false-positive class.

Sibling-class to P364 (marker-derivation friction on commit-message surface) but a distinct visibility-class bug — the marker mismatch is a hash drift, this one is a scope drift: the gate should check repo visibility (e.g. `gh repo view --json visibility -q .visibility` returning `PRIVATE` / `INTERNAL`) before firing on git-commit-message surface and silent-pass when repo is non-public.

User direction 2026-06-11: *"this MUST NOT fire for private repos"*.

Fix locus: wr-risk-scorer external-comms hook / agent `SURFACE: git-commit-message` branch — repo-visibility precondition gate before marker-derivation.

## Symptoms

(deferred to investigation)

- Witnessed in `a separate private adopter repo` (private repo) — gate fired on commit-message surface, BLOCKED with the same stderr directive seen in the public agent-plugins repo.

## Workaround

(deferred to investigation)

- `BYPASS_RISK_GATE=1` env override at commit time (documented existing escape hatch; coarse-grained — bypasses ALL surfaces not just commit-messages).

## Impact Assessment

- **Who is affected**: (deferred to investigation) — every adopter on a private/internal repo who hits the gate at commit time.
- **Frequency**: (deferred to investigation) — fires on every gated commit (PreToolUse).
- **Severity**: (deferred to investigation) — false-positive friction class; no security implication (private repo content stays private).
- **Analytics**: (deferred to investigation).

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Locate the `SURFACE: git-commit-message` branch in the external-comms hook + agent prompt
- [ ] Add repo-visibility precondition check using `gh repo view --json visibility -q .visibility` (or git-config / remote-URL inference fallback for offline cases)
- [ ] Decide policy: silent-pass entirely on PRIVATE+INTERNAL, OR pass-but-still-mark-reviewed?
- [ ] Behavioural bats: PRIVATE repo → silent-pass; INTERNAL repo → silent-pass; PUBLIC repo → existing behaviour preserved
- [ ] Document the policy in RISK-POLICY.md (or whichever policy doc covers the surface-by-surface visibility)

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P364 (sibling-class marker-derivation friction on the SAME surface) — both should be fixed together if practical.

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)
- P364 — sibling class on the same surface (marker-derivation friction; hash-drift class). This ticket is the scope-drift class.
- P353 — original marker-derivation friction precedent.
