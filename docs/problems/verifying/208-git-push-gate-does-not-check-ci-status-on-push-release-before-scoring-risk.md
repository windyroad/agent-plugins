# Problem 208: git-push-gate.sh does not check CI status on push/release before scoring risk

**Status**: Verifying
**Reported**: 2026-05-15
**Fix Released**: pending — awaiting orchestrator-owned push/release cadence
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

> **safe-high-fix-risk flag** (per dual-axis-risk classifier): `git-push-gate.sh` is a load-bearing release-risk gate. Modifications to it (even hardening ones) need maintainer attention to ensure the new `gh run list` integration doesn't degrade-to-allow on API timeout / auth failure / pending-run states, which would silently weaken the very gate the fix intends to strengthen. The fix-risk class flagged is "Removal of load-bearing safety check" applied inversely — a buggy harden can degrade to a bypass.

## Description

`git-push-gate.sh` (in `packages/risk-scorer/hooks/`) gates `npm run push:watch` and `npm run release:watch` on the wr-risk-scorer pipeline output, but never directly checks whether the latest CI run on the target branch is red. A push that scores low predicted risk can still proceed onto a CI-broken master because the gate consumes only the leading risk signal, not the lagging CI-status signal.

The same gap applies to `npm run release:watch`: a low-risk release can ship onto a master where the most recent CI run was a failure.

## Workaround

User-in-the-loop review: manually inspect `gh run list --branch master --limit 1` before approving every push and release. Works for low-volume cadence; does not scale.

## Impact Assessment

- **Who is affected**: every adopter project running push:watch / release:watch with CI integration.
- **Frequency**: pattern-applies to every push and release attempt.
- **Severity**: High — a red-CI-on-master push lands shipped code on a broken baseline; release ships broken code to npm.

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] **Architect call (safe-high-fix-risk)**: routine extension verdict (`wr-architect:agent` 2026-06-06). No new ADR — the change fits the established `{reducing,incident}-*` bypass-marker family (ADR-009) and adds an orthogonal precondition to ADR-065's threshold check. Fail-CLOSED contract enforced on gh exit non-zero, parse error, and unknown auth failure.
- [x] Extend `git-push-gate.sh` to consult `gh run list --branch <current> --limit 1` for the working branch's most recent CI run. `conclusion ∈ {failure, cancelled, timed_out, action_required, startup_failure}` → deny with run URL; `status ∈ {queued, in_progress, pending, requested, waiting}` → deny with reason; gh failure → deny (fail-closed); empty result (no history) → allow (first-push case). One-shot `ci-bypass-${ACTION}` override marker.
- [x] Behavioural test (16 cases in `packages/risk-scorer/hooks/test/ci-status-gate.bats`) covers: success allow, failure/cancelled/timed_out/in_progress/queued deny, empty-history allow, gh-error fail-closed deny, bypass-marker allow + consume, action-scoped bypass, skipped/neutral allow, push:watch + release:watch integration, incident-release short-circuit (JTBD-201).

## Fix

Implemented 2026-06-06.

- `packages/risk-scorer/hooks/lib/risk-gate.sh` — new `check_ci_status` helper sibling to `check_risk_gate`. 10s `timeout`-bounded `gh run list` query. Fail-CLOSED on gh exit, parse error, unknown status.
- `packages/risk-scorer/hooks/git-push-gate.sh` — invoked in `push:watch` and `release:watch` branches AFTER existing bypass markers (`reducing-push` / `clean` / `incident-release` / `reducing-release`) and BEFORE `check_risk_gate`.
- One-shot `${RDIR}/ci-bypass-${ACTION}` marker for the documented override.
- `.changeset/p208-ci-status-aware-push-release-gate.md` — patch bump for `@windyroad/risk-scorer`.

JTBD notes honoured per `wr-jtbd:agent` review:

- `incident-release` short-circuits BEFORE the CI check (JTBD-201 hotfix path).
- Deny reasons include the conclusion enum value and the run URL for audit trail (JTBD-202).
- Bypass marker is one-shot, matching the established `reducing-push` / `incident-release` semantics (JTBD-002 transparency).

## Related

- **Reported Upstream**: https://github.com/windyroad/agent-plugins/issues/86
- **Pipeline classification**: JTBD-aligned (JTBD-006 + JTBD-202); **safe-high-fix-risk** (cache_audit_note: high-fix-risk-flag); route=safe-and-valid + flag.
- **Affected plugin**: @windyroad/risk-scorer.
