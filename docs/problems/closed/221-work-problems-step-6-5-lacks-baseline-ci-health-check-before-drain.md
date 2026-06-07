# Problem 221: work-problems Step 6.5 lacks baseline CI health check before drain

**Status**: Closed
**Reported**: 2026-05-15
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Closed as no longer relevant

**Closed**: 2026-06-08 (work-problems AFK iter — superseded by **P208**; the baseline CI-health gate the ticket asked for is now structurally inherited by Step 6.5's drain via the push-gate fix shipped 2026-06-06).

**Evidence shape**: ADR-079 Phase 2 shape 3 (duplicate-of-X / sibling-fix-supersedes; P208 named in this ticket's Related/sibling line as the coordination target) + shape 2 (work-shipped via different surface — push-gate, not Step 6.5 SKILL prose).

**Why superseded — wiring is end-to-end**:

1. **P221's ask** (Step 6.5 must check CI health before drain): Step 6.5 Drain action invokes the literal shell commands `npm run push:watch` and (conditionally) `npm run release:watch` per `packages/itil/skills/work-problems/SKILL.md` lines 805–806.
2. **P208's fix** (`fe51ed4` 2026-06-06 `fix(risk-scorer): P208 push/release gate consults CI status before scoring`): extended `packages/risk-scorer/hooks/git-push-gate.sh` lines 54 + 109 to call a new `check_ci_status` helper in `packages/risk-scorer/hooks/lib/risk-gate.sh` for BOTH `npm run push:watch` (line 36 regex match) AND `npm run release:watch` (line 90 regex match).
3. The helper queries `gh run list --branch <current> --limit 1 --json status,conclusion,databaseId,url` and denies on `conclusion ∈ {failure, cancelled, timed_out, action_required, startup_failure}` (named with run URL for audit trail) or `status ∈ {queued, in_progress, pending, requested, waiting}` — matching this ticket's Investigation Task #3 ("Extend Step 6.5 with a baseline CI-health check that halts drain on `conclusion: failure` / `conclusion: cancelled`") **exactly**.
4. **Fail-CLOSED on gh exit non-zero / parse error** (`packages/risk-scorer/hooks/lib/risk-gate.sh` lines 213 + 252) — matches this ticket's Investigation Task #2 architect-call requirement ("design the CI-health gate to fail-CLOSED on API/auth/pending").
5. **Coordination with P208** (Investigation Task #2 explicit ask): satisfied by the fix landing on the push-gate surface — P208 is the sibling identified in this ticket's Related section as the resolve-together target.
6. **First-push edge case** (the safe-high-fix-risk concern about over-blocking on transient CI flake): handled by P208's `${RDIR}/ci-bypass-${ACTION}` one-shot marker (lib/risk-gate.sh lines 175–180) + empty-CI-history natural-allow (lines 219–223; no marker required) — over-blocking risk addressed without under-blocking.
7. **`incident-release` short-circuit preserved** (JTBD-201 hotfix path): orders the incident-release marker BEFORE the CI check at `git-push-gate.sh` lines 98–101 — the safe-high-fix-risk load-bearing AFK drain concern is honoured.
8. **Behavioural coverage**: 16 bats in `packages/risk-scorer/hooks/test/ci-status-gate.bats` cover success / failure / cancelled / timed_out / in_progress / queued deny, empty-history allow, gh-error fail-closed deny, bypass-marker allow-and-consume, action-scoped bypass, skipped / neutral allow, push:watch + release:watch integration, and incident-release short-circuit. Step 6.5's drain action invokes these exact commands, so the bats coverage transitively pins Step 6.5's CI-health-before-drain contract via the push-gate.

**No code change for P221 itself.** The fix path P221 originally proposed (extend the SKILL prose with a duplicate `gh run list` check) would have layered orchestrator-side scripting on top of a hook-side check that already fires — adding test-surface coverage without adding behaviour, and creating a divergence-risk between SKILL prose and hook implementation. The hook-side fix is the structurally correct locus per P208's architect verdict (PASS, no new ADR — fits ADR-009 bypass-marker family + orthogonal to ADR-065 threshold).

**Lifecycle**: KE → Closed direct per **ADR-079 lifecycle extension** (Open|Known Error → Closed bypasses Verifying when no fix was released as a separate ship; the gating fix shipped on P208's commit, not on a P221-specific commit).

**Upstream**: https://github.com/windyroad/agent-plugins/issues/62 should be closed with the same resolution body (sibling upstream #86/P208 already addresses it).

**Reversible** via `/wr-itil:transition-problem 221 known-error`.

> **safe-high-fix-risk flag** (per dual-axis-risk classifier): the proposed CI-health gate sits on the AFK-critical drain path. A wrong implementation could (a) over-block legitimate drains on transient CI flake, OR (b) under-block and let drain proceed against broken main. Not a "removal of load-bearing safety check" — it ADDS one — but it sits on a critical path so the maintainer should weigh failure modes + coordinate with sibling P208/#86 before accepting.

## Description

`/wr-itil:work-problems` Step 6.5 ("Release-cadence check") decides whether to drain the changeset queue based on local risk scores only. It never checks the health of the latest `main` pipeline run before invoking `npm run push:watch`. When `main` is already red for reasons outside the local risk scope, the drain may proceed and compound the breakage.

## Workaround

User-in-the-loop: check `gh run list --branch main --limit 1` before authorising an AFK loop or after Step 6.5 has fired.

## Impact Assessment

- **Severity**: High — drains can compound red-CI breakage; AFK promise broken.

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] **Architect call (safe-high-fix-risk)**: design the CI-health gate to fail-CLOSED on API/auth/pending; coordinate with P208/#86 push-gate hardening.
- [ ] Extend Step 6.5 with a baseline CI-health check that halts drain on `conclusion: failure` / `conclusion: cancelled`.

## Related

- **Reported Upstream**: https://github.com/windyroad/agent-plugins/issues/62
- **Pipeline classification**: **safe-high-fix-risk** (cache_audit_note: high-fix-risk-flag); route=safe-and-valid + flag.
- **Affected plugin**: @windyroad/itil + @windyroad/risk-scorer.
- **Sibling**: P208/#86 (push-gate CI-status gap — closely related; resolve together).
