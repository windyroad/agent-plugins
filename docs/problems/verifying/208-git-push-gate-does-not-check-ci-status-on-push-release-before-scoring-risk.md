# Problem 208: git-push-gate.sh does not check CI status on push/release before scoring risk

**Status**: Verification Pending
**Reported**: 2026-05-15
**Fix Released**: pending — awaiting orchestrator-owned push/release cadence
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**WSJF**: 3 — (3 × 2.0) / 2 (added 2026-07-26 review)

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

The red-CI deny path correctly prevents unrelated pushes, but its guidance says only
"fix CI" and "no override". It does not explain the existing policy-authorised
recovery path: inspect the failed run, prove the outgoing commits directly repair
that failure, then ask `wr-risk-scorer:pipeline` to classify the change against the
live realised-risk baseline. Agents therefore misclassify an actionable CI repair
as a blocked goal.

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] **Architect call (safe-high-fix-risk)**: routine extension verdict (`wr-architect:agent` 2026-06-06). No new ADR — the change fits the established `{reducing,incident}-*` bypass-marker family (ADR-009) and adds an orthogonal precondition to ADR-065's threshold check. Fail-CLOSED contract enforced on gh exit non-zero, parse error, and unknown auth failure.
- [x] Extend `git-push-gate.sh` to consult `gh run list --branch <current> --limit 1` for the working branch's most recent CI run. `conclusion ∈ {failure, cancelled, timed_out, action_required, startup_failure}` → deny with run URL; `status ∈ {queued, in_progress, pending, requested, waiting}` → deny with reason; gh failure → deny (fail-closed); empty result (no history) → allow (first-push case). One-shot `ci-bypass-${ACTION}` override marker.
- [x] Behavioural test (15 cases in `packages/risk-scorer/hooks/test/ci-status-gate.bats`) covers: success allow, failure/cancelled/timed_out/in_progress/queued deny, empty-history allow, gh-error fail-closed deny, removed-bypass regression, skipped/neutral allow, push:watch + release:watch integration, and incident-release short-circuit (JTBD-201).
- [x] Red-CI push denial names the risk-reducing CI-repair path and explicitly says red CI is not itself a goal blocker.
- [x] Red-CI release denial routes through a CI-repair push and green verification, retaining the live-outage `incident-release` path.

## Fix

Implemented 2026-06-06.

- `packages/risk-scorer/hooks/lib/risk-gate.sh` — new `check_ci_status` helper sibling to `check_risk_gate`. 10s `timeout`-bounded `gh run list` query. Fail-CLOSED on gh exit, parse error, unknown status.
- `packages/risk-scorer/hooks/git-push-gate.sh` — invoked in `push:watch` and `release:watch` branches AFTER existing bypass markers (`reducing-push` / `clean` / `incident-release` / `reducing-release`) and BEFORE `check_risk_gate`.
- One-shot `${RDIR}/ci-bypass-${ACTION}` marker for the documented override.
- `.changeset/p208-ci-status-aware-push-release-gate.md` — patch bump for `@windyroad/risk-scorer`.

Guidance correction implemented 2026-07-23 under RFC-049 / STORY-046:

- Red-CI push denials now direct agents to prove the outgoing commits repair the
  linked failure and obtain the existing independent net-risk-reducing verdict.
- Red-CI release denials now direct agents through repair push, green CI, and
  release retry while preserving the live-outage incident path.
- `.changeset/risk-scorer-red-ci-recovery-guidance.md` queues the patch release.

JTBD notes honoured per `wr-jtbd:agent` review:

- `incident-release` short-circuits BEFORE the CI check (JTBD-201 hotfix path).
- Deny reasons include the conclusion enum value and the run URL for audit trail (JTBD-202).
- Bypass marker is one-shot, matching the established `reducing-push` / `incident-release` semantics (JTBD-002 transparency).

## Fix Released

Released in `@windyroad/itil@0.55.0` on 2026-06-28, via changeset `p208-ci-status-aware-push-release-gate.md`.

Awaiting user verification that the fix behaves as intended in the installed package.

## Related

- **RFC**: RFC-049 (red-CI recovery guidance), ratified with STORY-046.
- **Regression evidence 2026-07-23**: a Codex agent with two local CI-repair commits concluded its goal was blocked because the deny text exposed only incident recovery, manual push, or policy change; after the user clarified that progress on red CI must be a CI-fixing change, the agent resumed correctly.

- **Reported Upstream**: https://github.com/windyroad/agent-plugins/issues/86
- **Pipeline classification**: JTBD-aligned (JTBD-006 + JTBD-202); **safe-high-fix-risk** (cache_audit_note: high-fix-risk-flag); route=safe-and-valid + flag.
- **Affected plugin**: @windyroad/risk-scorer.

## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-046 | STORY-046: Red-CI denial explains the recovery path | in-progress |

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-049 | in-progress | Make the red-CI gate explain the CI-repair recovery path |
