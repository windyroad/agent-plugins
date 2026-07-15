# Problem 454: wr-risk-scorer restage-commit helper sweeps the whole index/working tree into the commit instead of pathspec-scoping to the supplied paths

**Status**: Open
**Reported**: 2026-07-15
**Priority**: 9 (Medium) — Impact: 3 (Moderate — wrong commit content, silently: unrelated staged paths and even unstaged working-tree modifications folded into commits; collapses planned multi-commit sequences) × Likelihood: 3 (Possible — fires whenever the index holds paths outside the supplied list, which the helper's own driver (Agent-tool boundary clearing/restoring index state) makes common) — derived at capture per Step 4a
**Origin**: inbound-reported (#344)
**Effort**: S — pathspec-scoped commit (`git commit -- <paths>`) or warn/abort when the index holds paths outside the supplied list, + bats for the sweep case (existing `restage-commit.bats` misses it) — cf. verified defect locus `packages/risk-scorer/scripts/restage-commit.sh:121`
**JTBD**: JTBD-002
**Persona**: developer

## Description

The `wr-risk-scorer-restage-commit` helper re-adds the supplied paths but commits the ENTIRE index — paths staged earlier in the session, and even unstaged working-tree modifications, are silently swept into the commit. Observed downstream: a planned two-commit sequence collapsed into one because unrelated files were pre-staged; separately, two modified-but-unstaged files were folded into an unrelated capture commit.

**Verified at capture (2026-07-15)**: `packages/risk-scorer/scripts/restage-commit.sh` line 121 runs bare `git commit "${msg_args[@]}"` — no pathspec — after `git add -- "${paths[@]}"`, so any pre-existing index content outside the supplied paths is swept in. The report is technically accurate.

Fix direction: commit only the supplied paths (`git commit -- <paths>` pathspec form), or warn/abort when the index contains paths outside the supplied list.

## Symptoms

- Two-commit plan collapses to one commit.
- Second restage-commit call errors with an empty-index-diff after the first consumed its paths.
- Unstaged working-tree files swept into an unrelated capture commit.

## Workaround

Ensure the index is clean of unrelated paths before invoking the helper (manual `git status` check).

## Impact Assessment

- **Who is affected**: developer persona — every consumer of the P326 restage-commit wrapper (capture-problem, manage-problem, transition flows).
- **Frequency**: whenever unrelated paths are staged/modified at helper invocation time.
- **Severity**: Moderate — silent wrong-commit-content; recoverable via git surgery but violates ADR-014 unit-of-work grain.
- **Analytics**: downstream repo tracked as P115.

## Root Cause Analysis

### Investigation Tasks

- [ ] Switch line 121 to the pathspec form (`git commit "${msg_args[@]}" -- "${paths[@]}"`) or add an index-superset guard; decide warn vs abort.
- [ ] Extend `packages/risk-scorer/scripts/test/restage-commit.bats` with the sweep case (pre-staged unrelated path + unstaged modification).

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P326 lineage (closed — the helper IS P326's fix artefact; its driver, the Agent-boundary index-clear, is why out-of-list index content arises in practice)

## Related

- Upstream issue #344 (inbound; reporter's downstream ticket P115).
- Hang-off arbitration 2026-07-15 (wr-itil:hang-off-check): PROCEED_NEW — P305 is a cross-process Edit-tool race with a ratified worktree-isolation fix (no concurrency here; deterministic single-process bug); P192 (verifying) is gate-marker lifecycle friction, different failure class. Arbiter independently verified the defect at restage-commit.sh:121.
