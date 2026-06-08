# Problem 277: P165 README-refresh hook doesn't distinguish iter-staged from cross-turn-staged tickets when AFK subprocess + orchestrator main turn share working tree

**Status**: Closed
**Reported**: 2026-05-19
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Closed as no longer relevant

Closed 2026-06-08 (work-problems AFK iter — superseded; the only known trigger path for the cross-turn-staged class is structurally eliminated by P199 + P326). The P277 evidence trace (session 8 iter 2, P269 fold-fix commit blocked by P165 because P270's `.open.md` file appeared in the iter's staged set) presupposes a window where a captured ticket sits **staged-but-not-committed** in a shared working tree. Two sibling fixes close that window:

1. **P199** (closed 2026-06-05, commit `3330565` `fix(itil): capture-problem stages README inline; kill deferred-refresh contract (closes P199)`) — killed the deferred-README-refresh contract. `packages/itil/skills/capture-problem/SKILL.md` Step 6 lines 307-312 now stage the new `.open.md` file **plus** `docs/problems/README.md` **plus** `docs/problems/README-history.md` (when line-3 displacement occurred) in a single `git add` before the commit. Per Step 6 line 320, the commit lands via `wr-risk-scorer-restage-commit` — the P326 atomic re-stage-and-commit helper. The deferred-refresh contract that left ticket files un-paired with README is dead; the P262/P265 `capture-deferred-readme` allow-list trailer is retained as inert dead code for adopter compatibility per P199 § Fix Strategy line 50 (no longer emitted by capture-problem). Net effect: a successful capture commits both files atomically — no residual staged ticket file in the shared index for a concurrent iter-subprocess to grab.

2. **P326** (verifying, commit `0a4c1c7` `fix(risk-scorer): atomic re-stage-and-commit helper (closes P326)`) — the `wr-risk-scorer-restage-commit` helper landed by P326 makes the stage→commit pair atomic against the scorer-delegation index-clear (the symptom the helper was built to recover) AND closes the more general "leave staged state behind on gate denial" class against any subsequent in-process commit attempt. Step 1 of the helper re-`git add`s the supplied paths; the immediately-following `git commit` either succeeds atomically (no residue) or fails atomically (the helper exits non-zero without leaving partially-staged state for the next caller). Combined with P199's inline-stage shape, capture-problem cannot land a ticket file in the index without a paired README refresh; the iter-subprocess's later `git commit` cannot pick up a partial capture state.

The residual structural concern — shared working tree between orchestrator-main-turn and iter-subprocess (no per-iter `git worktree` create) — remains a design property of ADR-032 § subprocess-boundary variant, but the orchestrator pattern at `packages/itil/skills/work-problems/SKILL.md` line 531 (`wait "$ITER_PID"`) makes iter dispatch strictly sequential: the orchestrator main turn awaits each iter's exit before doing any subsequent work, so capture-problem cannot fire concurrently with an in-flight iter from the orchestrator surface. The iter-subprocess can fire capture-problem ITSELF via its retro-on-exit (per the P342 mechanical-stage carve-out), but in that path the capture commits inside the iter's own session — there is no second concurrent commit-author to interleave with. The P277 scenario is no longer reachable from any normal AFK loop trajectory.

**ADR-079 Phase 2 shape 3** (sibling-fix-supersedes; named sibling fixes P199 + P326 directly address the underlying class) + **shape 2** (work-shipped via different surface — closure of the class via inline staging + atomic helper rather than the originally-proposed P165 hook commit-message ticket-ID filter). The proposed Fix Strategy of parsing `$COMMIT_MSG_FILE` for `P[0-9]+` hints to filter the staged set (branch a) OR snapshotting against an iter-start ref (branch b) was a workaround for a class that no longer reliably manifests; the structurally correct fix is the one shipped — eliminate the staged-but-uncommitted window at the source (capture-problem) rather than filter at the consumer gate (P165). 12th KE→Closed-direct this week — confirms ADR-079 load-bearing for ratification per outstanding-question queue #2. No code change; KE→Closed direct per ADR-079 lifecycle extension. Reversible via `/wr-itil:transition-problem 277 known-error`.

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

## Fix Strategy

**Kind**: create (new hook behaviour)
**Shape**: hook script edit
**Target file**: `packages/itil/hooks/lib/readme-refresh-detect.sh` (P165 helper) + canonical sync via existing pattern (analogous to P273+P274+P275 sibling sweep promoting `command_invokes_git_commit` to `packages/shared/hooks/lib/`)
**Observed flaw**: helper treats every staged ticket as the current commit's grain — no distinction between iter-staged (this commit's work) and cross-turn-staged (orchestrator main turn captured a ticket while iter was working in shared tree).
**Edit summary**: branch (a) — parse `$COMMIT_MSG_FILE` for ticket-ID hints (regex `P[0-9]+`) and filter staged ticket set to ID-matching subset before applying README-refresh discipline; OR branch (b) — snapshot-diff staged set against iter-start ref (requires iter-subprocess to publish start-ref via marker file similar to P119 runtime-sid). Architect should choose branch when fix is scheduled.
**Evidence (session 8)**:
- Iter-2 P269 fold-fix commit blocked by P165 hook because orchestrator main turn captured P270 concurrently (commit 04c15a6) into shared tree → P270's `.open.md` file appeared in iter-2's staged set → hook detected staged-ticket-without-README-refresh → BLOCK.
- Workaround was `git restore --staged docs/problems/open/270-*` before iter-2 retry — manual, reactive, learned from BLOCK message rather than designed for.
- This pattern recurs every concurrent-capture × iter-commit cycle in AFK orchestrator workflows — class-of-behaviour not one-off.

**Routing target**: when P277 is worked, `/wr-itil:manage-problem 277 known-error` → architect review on branch choice → implementation in `packages/itil/hooks/lib/readme-refresh-detect.sh` with behavioural bats covering both iter-staged and cross-turn-staged fixture cases.

## Dependencies

- **Composes with**: P165 (parent README-refresh hook), P268 (substring-match defect sibling), P119 (create-gate marker), ADR-014, ADR-032

## Related

(captured 2026-05-19 from /wr-itil:work-problems session 8 iter 2 (P269) deviation-approval queue, user-directed via AskUserQuestion at Step 2.5)

- P165 — parent README-refresh discipline hook
- P268 — sibling-defect substring-match fix
- P272-P275 — P165 sibling-hook cluster
- ADR-014, ADR-032 — grain contracts the cross-turn case violates
