# Problem 277: P165 README-refresh hook doesn't distinguish iter-staged from cross-turn-staged tickets when AFK subprocess + orchestrator main turn share working tree

**Status**: Open
**Reported**: 2026-05-19
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**Type**: technical

## Description

During session 8 iter 2 (P269), the orchestrator main turn captured P270 via `/wr-itil:capture-problem` while iter-2 P269 was running in background subprocess. P270 was auto-staged into iter-2's git working tree (the orchestrator + iter share the same tree). When iter-2's fold-fix commit ran, the P165 README-refresh hook detected P270 as a staged-ticket-without-README-refresh and BLOCKED the commit — even though P270 was not iter-2's work, but the orchestrator main turn's concurrent capture.

`git restore --staged` cleared the index to preserve iter-2's ADR-014 grain. But the underlying defect remains: P165 hook treats ALL staged ticket changes as "this commit's work" without distinguishing iter-grain from cross-turn-grain.

**Proposed fix shape**: P165 should either (a) filter the staged set to the commit-author's intended grain (e.g. read the commit message for ticket-ID hints and match staged tickets to that) OR (b) surface staged-but-not-author-intended files for explicit user-acknowledged dismissal.

## Symptoms

(deferred to investigation)

## Workaround

`git restore --staged` before iter-commit retry. Awkward — iter learns about the cross-turn-stage from P165 BLOCK message and acts reactively.

## Impact Assessment

- **Who is affected**: any AFK iter running concurrently with orchestrator-main-turn captures.
- **Frequency**: every concurrent capture → iter-commit cycle.
- **Severity**: (deferred to investigation) — initial: moderate.

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Investigate root cause — `packages/itil/hooks/lib/readme-refresh-detect.sh` treats every staged ticket as this commit's grain
- [ ] Design candidate (a): parse commit message for ticket-ID hints
- [ ] Design candidate (b): snapshot-diff against iter-start ref
- [ ] Create reproduction test

## Dependencies

- **Composes with**: P165 (parent README-refresh hook), P268 (substring-match defect sibling), P119 (create-gate marker), ADR-014, ADR-032

## Related

(captured 2026-05-19 from /wr-itil:work-problems session 8 iter 2 (P269) deviation-approval queue, user-directed via AskUserQuestion at Step 2.5)

- P165 — parent README-refresh discipline hook
- P268 — sibling-defect substring-match fix
- P272-P275 — P165 sibling-hook cluster
- ADR-014, ADR-032 — grain contracts the cross-turn case violates
