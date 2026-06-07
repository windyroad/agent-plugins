# Problem 223: Risk scorer ignores release-risk accumulation across commits

**Status**: Closed (Superseded)
**Reported**: 2026-05-15
**Closed**: 2026-06-08 (work-problems AFK iter — 3-layer cumulative pipeline contract already shipped)
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Description

The risk-scorer assesses commit and push risk per-action but does not enforce release-risk accumulation. Plan reviews recommend incremental commits but only per-action scoring exists, no aggregate. Release risk drifts unbounded across unreleased commits.

## Resolution

**Closed as Superseded 2026-06-08.** Investigation found the requested contract ("extend pipeline subagent to aggregate release-risk across unreleased commits + flag when aggregate exceeds appetite") is fully implemented in the current pipeline subagent + RISK-POLICY + governance ADRs. The reported gap ("only per-action scoring exists, no aggregate; release risk drifts unbounded") is structurally impossible against the current contract.

**Layer 1 (release) aggregation across unreleased commits — `packages/risk-scorer/agents/pipeline.md` lines 42-52** (the P202 changeset partition):

> The UNRELEASED CHANGES section emits TWO distinct changeset counts:
> - `Pending changesets (commits unpushed): N` — changesets whose introducing commit is in `origin/<base>..HEAD` (local) OR is untracked. These ARE pending consumer-facing changes at THIS commit's surface and count toward Layer 1 release risk as before.
> - `Queued changesets (commits already on origin): N` — changesets whose introducing commit is already on `origin/<base>`. … contribute zero release-risk at THIS commit's surface…
> When computing Layer 1 release risk, score only the Pending count (plus any unreleased diff content).

**3-layer cumulative scoring contract — pipeline.md lines 80-110** (the Cumulative Risk Report):

> ### Layer 1: Unreleased Changes (release risk) — Residual risk: N/25
> ### Layer 2: Unreleased + Unpushed (push risk) — Cumulative residual risk: N/25
> ### Layer 3: Unreleased + Unpushed + Uncommitted (commit risk) — Cumulative residual risk: N/25
> Commit score >= push score >= release score (risk accumulates upward).

**Score File Values — pipeline.md lines 129-132**:

> - Commit score: Layer 3 cumulative (highest)
> - Push score: Layer 2 cumulative
> - Release score: Layer 1

**Above-appetite flag mechanism — pipeline.md lines 178-189**:

> When ANY cumulative score exceeds appetite (> 4), the verbal verdict is **STOP**. … Emit a structured `RISK_REMEDIATIONS:` block after the `RISK_SCORES:` line.

The structured `RISK_REMEDIATIONS:` block (pipeline.md lines 191-209) carries explicit downstream back-pressure:

> Include downstream back-pressure in the remediation list:
> - **Commit**: If adding this commit would push the push queue risk >= 5, include a remediation to split the commit.
> - **Push**: If pushing would push the release queue risk >= 5, include a remediation to release first.

**Appetite threshold — `RISK-POLICY.md` line 71**:

> Threshold: 4 (Low) — Pipeline gates block when cumulative residual risk exceeds 4.

**Orchestrator-level response — ADR-018 (Inter-iteration release cadence for AFK loops)** codifies the risk-driven cadence (release when accumulated commit/push/release risk reaches appetite) and the `work-problems` Step 6.5 within-appetite drain wires it into the AFK orchestrator surface. The lean release principle (ADR-014) + WIP commit verdict (ADR-016) + pure-scorer contract (ADR-015) compose with the layered scoring at pipeline.md to close the loop end-to-end.

**Auto-apply remediation surface — ADR-042 (Auto-apply scorer remediations, open vocabulary)**: the orchestrator consumes the above-appetite `RISK_REMEDIATIONS:` block and applies remediation actions (split-commit, release-first, move-to-holding) without re-asking the user. Rule 2 ADR-061 (graduation criteria) handles the symmetric flow when held material falls back within appetite.

**Empirical witness from this AFK loop**: every pipeline scorer invocation has emitted the canonical `RISK_SCORES: commit=N push=N release=N` block with Layer 1 capturing release-risk-across-unreleased-commits. The contract is end-to-end live; the wire is not theoretical.

**No code change**. Closed without a release.

## Workaround

N/A — no underlying defect.

## Impact Assessment

- **Severity**: None — ticket premise was satisfied by contracts already shipped before the ticket was captured.

## Root Cause Analysis

### Investigation Tasks

- [x] Re-rate Priority and Effort at next /wr-itil:review-problems — n/a, closed as superseded.
- [x] Extend pipeline subagent to aggregate release-risk across unreleased commits + flag when aggregate exceeds appetite — already implemented per pipeline.md lines 42-52 (P202 changeset partition) + lines 80-110 (Layer 1/2/3 cumulative scoring) + lines 178-189 (above-appetite `RISK_REMEDIATIONS:` flag) + RISK-POLICY.md line 71 (appetite threshold 4) + ADR-018/015/042 (orchestrator-level cadence + pure-scorer contract + auto-apply remediations). Not implemented as a separate change; rejected as superseded by existing contract.

### Misread design that drove the original capture

The ticket was captured 2026-04-24 via the upstream-mirror intake batch when the Layer 1 release-risk aggregation contract had already been in pipeline.md for some time. The P202 Pending-vs-Queued partition (which sharpens Layer 1 to the consumer-facing surface only) landed independently. Both the layered scoring and the appetite-flag mechanism predate this ticket.

## ADR-079 dependency note

This is the 8th KE→Closed-direct closure this week (sibling P216 / P217 / P218 / P222 / P224 / P225 / P227) — confirms ADR-079 Phase 2 ADR-supersession evidence shape is load-bearing for ratification per outstanding-question queue #2. ADR-079 itself remains `proposed` without `human-oversight: confirmed`; ratification queued via `/wr-architect:review-decisions` at natural loop end per the AFK pin (`feedback_dont_stop_afk_loop_to_checkpoint`).

## Related

- **Reported Upstream**: https://github.com/windyroad/agent-plugins/issues/60 — upstream issue should be closed as superseded with this resolution body.
- **Pipeline classification**: safe-low-fix-risk; route=safe-and-valid.
- **Affected plugin**: @windyroad/risk-scorer.
- **Hardened by**: [[P202]] (Pending vs Queued changeset partition), [[ADR-018]] (inter-iteration release cadence — orchestrator drain trigger), [[ADR-042]] (auto-apply remediations — open vocabulary), [[ADR-061]] (graduation criteria — symmetric reinstate).
