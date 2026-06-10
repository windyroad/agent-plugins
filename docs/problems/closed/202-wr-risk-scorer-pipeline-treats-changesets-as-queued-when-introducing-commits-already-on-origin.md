# Problem 202: wr-risk-scorer:pipeline treats changesets as queued when introducing commits are already on origin

**Status**: Closed

## Closed — verification confirmed

- **Closed on**: 2026-06-10
- **Closed by**: /wr-itil:review-problems Step 4 verification queue batch 2 — user-confirmed
- **Observed evidence**: every release-risk scoring this session (~12 releases including P213 5-package patch + P301 + P293 + P295 + P314 + P324 phases 1-6 + P080 + P129 + P172 + P184 + P175) correctly distinguished pending changesets (in `.changeset/`) from already-published. No false-positive "queued" counts blocking releases observed across the full release cadence.
**Reported**: 2026-05-15
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Description

When the `wr-risk-scorer:pipeline` subagent scores Layer 1 (release risk), it reads `.changeset/*.md` files in the working tree and treats their descriptions as "pending consumer-facing changes". It does not verify whether the underlying commits that introduced each changeset have already been pushed to `origin/<base>`. This produces a false-high score in a common state: the maintainer pipeline (changesets-action) has already landed the feature commits to master, the changesets are on origin, and the working tree is waiting for the next release-PR merge to npm.

The error is asymmetric. False-high release risk routes downstream consumers (`/wr-itil:work-problems` Step 6.5 above-appetite branch, `/wr-itil:manage-problem` Step 12 release path, ADR-042 auto-apply remediation loop) into either halting the loop or surfacing phantom remediations (e.g. `move-to-holding` on changesets whose code has already shipped). None of these are correct when the underlying commits are already live.

## Symptoms

- Live example, 2026-05-02 AFK loop on a downstream repo. After iter 2 landed three docs-only commits, Step 6.5 invoked `wr-risk-scorer:pipeline`.
- First call assumed `.changeset/*.md` descriptions correspond to local-only work and computed release risk above appetite, triggering the above-appetite-remediation branch.
- Manual inspection revealed the changesets' introducing commits had been on origin since the prior release PR; the release-PR merge to npm was the only pending step.
- The auto-remediation loop's `move-to-holding` step would have moved live changesets into the holding area, fragmenting the release.

## Workaround

Manually inspect the changesets' git history before trusting the Layer 1 score. Use `git log --oneline -- .changeset/` cross-referenced against `git log origin/<base>..HEAD -- .changeset/` to distinguish queued from already-pushed changesets.

## Impact Assessment

- **Who is affected**: every maintainer running `wr-risk-scorer:pipeline` in a tree where some changesets are already on origin awaiting release-PR merge.
- **Frequency**: every Layer 1 score in the changesets-action holding pattern.
- **Severity**: High — false-high release-risk routes load-bearing automation (work-problems above-appetite, ADR-042 auto-apply) into incorrect branches.

## Root Cause Analysis

`pipeline-state.sh --unreleased` emitted a single `Pending changesets: N` line based purely on the count of `.changeset/*.md` files in the working tree. The script never partitioned changesets by introducing-commit provenance, so the pipeline agent received an undifferentiated count and treated every changeset as a pending consumer-facing change. The architectural signal "pending consumer-facing change at THIS commit's surface" should be `commits-introducing-changesets-that-are-NOT-on-origin/<base>`, not `changesets-in-working-tree`.

### Investigation Tasks

- [x] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Pipeline subagent: before counting a `.changeset/*.md` as "pending", check whether its containing commit is on `origin/<base>`. If on origin, treat it as already-released-pending-merge-PR (not pending-consumer-facing-change at THIS commit's surface).
- [x] Architectural call: where does the "pending consumer-facing change" signal live? Likely needs to be `commits-introducing-changesets-that-are-NOT-on-origin`, not `changesets-in-working-tree`.
- [x] Behavioural test: synthetic fixture with changesets on origin + working tree → assert Layer 1 score does NOT count them as queued.

## Fix Strategy

Two-surface refinement within the existing Layer-1 scoring contract (no new ADR; architect PASS + JTBD PASS 2026-06-05):

1. **`packages/risk-scorer/hooks/lib/pipeline-state.sh`** — partition `.changeset/*.md` files by introducing-commit provenance. For each changeset, run `git log <DEFAULT_BRANCH>..HEAD -- <file>`: non-empty output OR untracked status ⇒ **Pending**; empty output AND tracked ⇒ **Queued**. Emit two distinct lines (`Pending changesets (commits unpushed): N` and `Queued changesets (commits already on origin): N`) so the agent receives the partition directly in structured context.

2. **`packages/risk-scorer/agents/pipeline.md`** — amend the Layer-1 scoring contract with a `### Layer 1 changeset partition (P202)` subsection clarifying that Queued changesets contribute zero release-risk at this commit's surface. Score only the Pending count (plus any unreleased diff content). Forbid emitting `RISK_REMEDIATIONS:` lines (such as `move-to-holding`) targeting queued-on-origin changesets — their commits have already shipped and `git mv`'ing them into `docs/changesets-holding/` would fragment the release without reducing actual risk.

3. **Behavioural test** (ADR-052) — `packages/risk-scorer/hooks/test/pipeline-state-changeset-partition.bats` with 5 fixtures covering: straddle (queued+pending), all-on-origin (Queued > 0, Pending = 0), all-local (Pending > 0, Queued = 0), untracked-counts-as-pending, and no-changesets-emits-no-breakdown.

## Fix Released

Fix committed and released as part of the work-problems AFK iteration on 2026-06-05. Awaiting user verification.

## Dependencies

- **Blocks**: (none — but the false-high score blocks accurate work-problems Step 6.5 routing).
- **Blocked by**: (none)
- **Composes with**: P121 (parent? — same pipeline scoring logic), ADR-042 auto-apply, ADR-018 release-cadence, work-problems Step 6.5.

## Related

- **Reported Upstream**: https://github.com/windyroad/agent-plugins/issues/121 (filed 2026-05-13 from a downstream project's adopter session).
- **Pipeline classification** (review-problems Step 4.5e): JTBD-alignment=aligned-with-existing-JTBD (JTBD-202 + JTBD-006 + JTBD-301); dual-axis-risk=safe-low-fix-risk; route=safe-and-valid.
- **Affected plugin**: @windyroad/risk-scorer.
