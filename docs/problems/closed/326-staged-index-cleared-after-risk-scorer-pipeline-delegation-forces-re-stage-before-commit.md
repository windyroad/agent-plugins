# Problem 326: Staged index is cleared after a `wr-risk-scorer:pipeline` Agent delegation — forces a re-`git add` before the commit lands

**Status**: Closed
**Reported**: 2026-05-28
**Priority**: 3 (Medium) — Impact: 2 x Likelihood: 3 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Description

The ADR-014 commit-gate flow is: `git add <paths>` → delegate to `wr-risk-scorer:pipeline` (Agent tool) to score + write the bypass/score marker → `git commit`. Observed repeatedly this session (2026-05-28): after the scorer delegation returns, the previously-staged paths are **no longer staged** — `git commit` reports `Changes not staged for commit` / `no changes added to commit`, and a second `git add <paths>` + `git commit` is required to land it.

Net effect: every commit that routes through the risk-scorer delegation pays an extra `git add` round-trip. Low-severity individually, but it fired on ~3-4 commits this session (the README reconcile, the P324 capture, and others), and it's silent — the commit *looks* like it should work after scoring, then fails on staging, which is easy to misread as a gate issue rather than an index-state issue.

## Symptoms

- `git add X` → delegate to `wr-risk-scorer:pipeline` → `git commit` → `Changes not staged for commit` (the staged set was emptied during the delegation).
- Re-running the identical `git add X` + `git commit` immediately succeeds (the score/bypass marker from the delegation is still valid), confirming the only thing lost was the staging, not the score.

### Recurrence — 2026-05-30 session (run-retro evidence)

Fired again 3+ times during the ADR-076 / ADR-077 session: Slice 1 ADR-077 commit `846b5f2`, README reconcile `1da2ef5`, Slice 2 ADR-077 commit `9832593`. Each required a re-`git add` after the RISK-POLICY-staleness gate denial cleared the index. Wrapper-helper fix-strategy (e.g. `wr-risk-scorer-commit` that encapsulates `git add` + delegate + re-add + `git commit`) would eliminate the round-trip; route via Step 4b Stage 2 Option 3.

### New symptom — `wr-risk-scorer-restage-commit` rejects rename-source path (P222 closure iter, 2026-06-08)

The Verifying wrapper landed by Option C above carries a NEW failure mode that the existing test fixture does not cover: when the caller passes BOTH the rename-source AND rename-destination paths in the `-- <paths>` list (mirroring the SKILL Step 11 prose at line 995 "git add all created/modified files — **including any file renamed via `git mv` that was then modified by the `Edit` tool**"), the helper's Step 1 `git add -- <paths>` propagates the `git add` exit on the source path because `git mv` already removed the source from the working tree.

**Reproduction in P222 closure iter (2026-06-08)**:

```
$ wr-risk-scorer-restage-commit -m "<msg>" -- \
    docs/problems/README-history.md \
    docs/problems/README.md \
    docs/problems/closed/222-manage-problem-skill-should-auto-commit-ticket-file-changes.md \
    docs/problems/known-error/222-manage-problem-skill-should-auto-commit-ticket-file-changes.md
fatal: pathspec 'docs/problems/known-error/222-manage-problem-skill-should-auto-commit-ticket-file-changes.md' did not match any files
$ # Recovered by removing the deleted source path from the -- list:
$ wr-risk-scorer-restage-commit -m "<msg>" -- \
    docs/problems/README-history.md \
    docs/problems/README.md \
    docs/problems/closed/222-manage-problem-skill-should-auto-commit-ticket-file-changes.md
[main 7be3cc0] docs(problems): close P222 — superseded by ADR-014
```

**SKILL-prose-vs-wrapper-contract gap**: `packages/itil/skills/manage-problem/SKILL.md` Step 11 line 995 instructs the agent to `git add` "all created/modified files — **including any file renamed via `git mv` that was then modified by the `Edit` tool**" — implying both rename endpoints. The wrapper instead requires ONLY the rename-destination because `git mv` already staged the source's deletion in the index. Agents reading the SKILL prose without prior `wr-risk-scorer-restage-commit` experience hit this on first try.

**Mitigation options for the next iter on this ticket** (do not pre-commit; capture for evidence-based prioritisation):
- (a) Amend SKILL.md Step 11 line 995 to clarify "rename-destination only; the rename-source is already staged for deletion by `git mv` and MUST be omitted from the wrapper's `-- <paths>` list". One-sentence clarification; touches only one SKILL file.
- (b) Amend the wrapper to detect rename-source paths via `git diff --cached --diff-filter=R --name-status --raw` and silently filter them out of the `git add -- <paths>` call. Wrapper-side handling; covers all callers without per-SKILL prose maintenance burden.
- (c) Add a behavioural fixture to `packages/risk-scorer/scripts/test/restage-commit.bats` covering the "rename-source + rename-destination both passed → wrapper handles gracefully" case to pin whichever option is chosen.

**Impact**: low (single-iter recoverable in one retry) but the SKILL-prose-vs-wrapper-contract gap is structural — any KE→Closed-direct iter passing both rename endpoints hits the same wall. This iter is the second KE→Closed-direct in 24 hours with the same shape (P218 closure iter `46d5d56` had the same git-mv pattern). Either the SKILL prose is misleading or the wrapper is over-strict; the evidence-based reassessment is the next P326 iter's call.

## Workaround

Re-`git add` the exact paths immediately before `git commit`, after the scorer delegation returns. (This session applied it ~3-4×.)

## Impact Assessment

- **Who is affected**: anyone following the ADR-014 stage→score→commit flow (every governance commit that hits the risk gate); the AFK orchestrator pays it per iter commit.
- **Frequency**: every scorer-delegated commit. High this session.
- **Severity**: low (recoverable in one re-stage) but recurring + silent — wastes a round-trip and can be misdiagnosed as a gate failure.

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority/Effort at next /wr-itil:review-problems.
- [ ] Determine the mechanism: does the `wr-risk-scorer:pipeline` agent run a `git` operation (e.g. `git reset`, `git stash`, a worktree inspect) that clears the index? OR does the PreToolUse commit-gate *deny* path reset staging? OR does the Agent-tool subprocess boundary not preserve the parent index? Reproduce: `git add` a file, delegate to the scorer, `git status` before any commit attempt — confirm whether staging is already cleared by the delegation alone (vs by a blocked commit attempt). (DEFERRED — root cause work parked. The wrapper-helper fix-strategy below mitigates the silent re-add round-trip without requiring the mechanism to be diagnosed first.)
- [ ] If the scorer agent is clearing the index, fix it to be index-non-destructive (read-only assessment must not `git add`/`reset`/`stash` the user's staging). If it's the deny path, make the deny non-destructive. If it's the Agent-boundary, document the re-stage as a required step in the ADR-014 flow (and consider a wrapper). (Wrapper landed via the Fix Strategy below; the deeper mechanism-fix can ride a future iter.)

## Fix Strategy

**Option C — wrapper helper `wr-risk-scorer-restage-commit`** (workaround-codified at the post-Agent-delegation seam, NOT a root-cause fix):

Author `packages/risk-scorer/scripts/restage-commit.sh` with surface `wr-risk-scorer-restage-commit -m "<msg>" [-m "<trailer>"] -- <path1> [<path2>...]`. The helper:
1. Runs `git add -- <paths>` (propagates `git add` exit on bad paths).
2. Asserts `git diff --cached --name-only` is non-empty — exits 1 if staging is still empty after the re-add (caller's signal to investigate path correctness vs. the silent-index-clear mechanism).
3. Runs `git commit "${msg_args[@]}"` with the accumulated `-m` flags (supports repeated trailers like `RISK_BYPASS: capture-deferred-readme`).

ADR-049 PATH shim at `packages/risk-scorer/bin/wr-risk-scorer-restage-commit` generated from the canonical ADR-080 template via `scripts/sync-shim-wrappers.sh`. ADR-052 behavioural-fixture coverage at `packages/risk-scorer/scripts/test/restage-commit.bats` (12 tests covering single + multi-path commits, multiple `-m` trailers, missing `-m`/`--`/paths, empty-staging assertion, `git mv` + Edit P057 compose, no-touch-bystander).

SKILL.md surfaces adopt the helper in the post-Agent-delegation commit step:
- `packages/itil/skills/manage-problem/SKILL.md` Step 11 — replaces the `git commit -m "..."` line with `wr-risk-scorer-restage-commit -m "..." -- <paths>`; eliminates the silent re-add round-trip on every governance commit through that surface.
- `packages/itil/skills/capture-problem/SKILL.md` Step 6 — replaces the `git commit -m "..." -m "RISK_BYPASS: capture-deferred-readme"` line with the equivalent `wr-risk-scorer-restage-commit -m "..." -m "RISK_BYPASS: capture-deferred-readme" -- <path>`; trailer-mechanic preserved.
- `packages/itil/skills/transition-problem/SKILL.md` Step 8 — adds a documented `wr-risk-scorer-restage-commit` line at the commit-gate seam covering rename + Edit + README + history.md in the same call (composes with P057 staging discipline + P134 rotation).

The ADR-014 commit-gate flow is preserved — same gate ordering (work → score → commit), same primitives (`git add`, scorer delegation, `git commit`), same bypass-marker mechanism. Only the post-Agent-delegation `git add` + `git commit` 2-call dance collapses into 1 atomic `wr-risk-scorer-restage-commit` call. Adopter-safe: the helper ships in `@windyroad/risk-scorer` and lands on `$PATH` via the ADR-049 shim grammar on every adopter install.

**Release vehicle**: `.changeset/p326-restage-commit-helper.md` (`@windyroad/risk-scorer` patch + `@windyroad/itil` patch).

## Dependencies

- **Composes with**: P192 (risk-pipeline gate forces repeat rescoring round-trips when the working tree changes between scorer and commit — sibling scorer-delegation friction; this is the *staging-cleared* facet, P192 is the *rescore* facet), P057 / P125 / P273 (git staging traps — different mechanism: those are `git mv`+Edit re-stage; this is scorer-delegation index-clear).

## Related

- captured via /wr-itil:capture-problem during the 2026-05-28 run-retro Step 2b pipeline-instability scan (category: subagent-delegation friction + repeat-work friction); observed ~3-4× this session on governance commits.

## Fix Released

Released in `@windyroad/risk-scorer` (next patch) + `@windyroad/itil` (next patch) via `.changeset/p326-restage-commit-helper.md`.

Mitigation: new `wr-risk-scorer-restage-commit` bash helper (ADR-049 PATH shim) bundles `git add <paths>` + non-empty-staging assertion + `git commit "${msg_args[@]}"` into a single atomic call. SKILL.md surfaces (manage-problem Step 11, capture-problem Step 6, transition-problem Step 8) now invoke the helper at the post-Agent-delegation commit seam, eliminating the silent re-add round-trip P326 documented. ADR-052 behavioural-fixture coverage: `packages/risk-scorer/scripts/test/restage-commit.bats` 12/12 GREEN — single-path + multi-path commits, multiple `-m` trailers (e.g. `RISK_BYPASS:`), missing-`-m`/missing-`--`/no-paths error paths, empty-staging assertion, `git mv` + Edit P057 compose, no-touch-bystander.

Awaiting user verification — next time the user (or an AFK iter) lands a governance commit through `/wr-itil:manage-problem` Step 11 / `/wr-itil:capture-problem` Step 6 / `/wr-itil:transition-problem` Step 8, the commit should land in a single atomic call without the re-add round-trip the ticket Description observed.

Exercise evidence from this iter: the bats fixture's "single path: re-stages and commits (the P326 happy path)" and "rename via git mv survives the re-stage-and-commit (P057 + P326 compose)" tests both GREEN; the helper successfully composes with the P057 staging trap (rename + Edit content survives the single re-stage + commit call).

Open follow-up (deferred, not a P326 sibling): the underlying mechanism — does the Agent-tool boundary clear the parent index, or does the scorer agent run a destructive git operation, or does the deny path reset staging? — remains uninvestigated. The wrapper-helper mitigation closes the user-visible round-trip; root-cause diagnosis can ride a future iter without blocking this fix.
