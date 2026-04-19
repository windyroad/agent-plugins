# Problem 057: `git mv` + Edit + `git add` staging-ordering trap drops content edits from the commit

**Status**: Open
**Reported**: 2026-04-20
**Priority**: 6 (Medium) — Impact: Minor (2) x Likelihood: Possible (3)
**Effort**: S — clarifying note in one SKILL.md step + light bats coverage
**WSJF**: 6.0 — (6 × 1.0) / 1

## Description

`git mv <old> <new>` stages the rename into the index immediately. If a subsequent `Edit` tool call modifies `<new>` and then `git add <other-files>` + `git commit` runs without re-staging `<new>`, the commit captures only the rename — the edit to `<new>` stays unstaged and lands in the NEXT commit (or not at all if the session ends first).

This is adjacent to the BRIEFING line noting "Write fails after git mv — must Read the renamed file first" but is a distinct trap: the Read + Edit succeeds, the commit proceeds, and no error surfaces. The missing content shows up only when the next commit pulls it in or when the user spots the omission in review.

Observed 2026-04-19 iter 1: P054 verifying.md rename landed in commit `45e9c71` with `Status: Open` and no `## Fix Released` section — the Edit had populated both fields in the working tree, but `git add docs/problems/054-*.verifying.md` was implicit (via a rename-only stage from the earlier `git mv`) and did NOT include the subsequent Edit. The content fix only landed in iter 2's commit `b2f1646` alongside P046's changes, which made P046's commit confusingly also touch P054.

## Symptoms

- A governance-doc transition commit (`.open.md` → `.verifying.md` or `.known-error.md`) ships the rename but not the `## Fix Released` or `Status: Verification Pending` content updates.
- The missing content shows up in an unrelated later commit, cross-polluting the audit trail.
- Users reviewing the fix commit see `Status: Open` on a ticket supposedly being transitioned to Verification Pending, producing confusion.
- `manage-problem` SKILL.md Step 7 does not currently document the re-stage-after-Edit requirement.

## Workaround

After `git mv`, always re-stage the file explicitly after any Edit:

```bash
git mv docs/problems/<NNN>-<title>.open.md docs/problems/<NNN>-<title>.verifying.md
# ... Edit the file to update Status and add ## Fix Released section ...
git add docs/problems/<NNN>-<title>.verifying.md
git add <other-files>
git commit -m "..."
```

Or use `git add -u` to stage all tracked file modifications before commit.

## Impact Assessment

- **Who is affected**: every `manage-problem` transition that uses `git mv` followed by content edits (Open → Known Error, Known Error → Verification Pending, Verification Pending → Closed). Also any ADR status transition in `create-adr` that uses the same pattern.
- **Frequency**: every transition commit. Session-dependent: heavy-commit sessions (the 2026-04-19 AFK loop had four transitions) increase exposure.
- **Severity**: Minor — recoverable in the next commit, no data loss. But it corrupts the commit audit trail (the fix commit looks incomplete; the rehabilitation commit touches unrelated tickets).
- **Analytics**: observed twice in this session-pair (iter 1 of 2026-04-19 AFK loop, caught during iter 2's stage).

## Root Cause Analysis

### Structural

`git mv` is a convenience for `git rm <old> && git add <new>`. The index state after `git mv` is "rename from <old> to <new> with content == <old>'s content". Subsequent Edits to `<new>` change the working tree but NOT the index. A `git commit` with no additional `git add <new>` commits the rename against the OLD content. This is standard git behaviour, not a bug in git.

The trap is that the SKILL.md workflow doesn't make this explicit. Step 7 of `manage-problem` currently says:

```
git mv docs/problems/<NNN>-<title>.open.md docs/problems/<NNN>-<title>.known-error.md
```

Then "Update the 'Status' field in the file to 'Known Error'." — but no explicit `git add` after the edit. Reader assumes the rename stage carries content edits (it doesn't).

### Fix strategy

Add a one-line note in `manage-problem` SKILL.md Step 7 (for each transition arrow) and in `create-adr` SKILL.md Step 6 (supersession). Example wording:

> **After the `Edit` tool modifies the renamed file, re-stage it explicitly: `git add <new>`. `git mv` alone stages only the rename; subsequent content edits must be added again before commit.**

Light bats doc-lint assertion: grep SKILL.md for "re-stage" or "git add" near the `git mv` line.

Longer-term: `manage-problem`'s Step 11 commit convention could include a reminder in the add step: `git add all created/modified files for this operation (including files renamed via git mv, if edited after the rename)`.

### Investigation Tasks

- [x] Reproduce: observed 2026-04-19 iter 1 (P054 verifying.md rename without content edit landed in 45e9c71).
- [ ] Amend `manage-problem` SKILL.md Step 7: one-line re-stage reminder per transition arrow.
- [ ] Amend `create-adr` SKILL.md Step 6: same reminder for supersession renames.
- [ ] Add bats doc-lint assertion: `git mv` lines in both SKILL.md files are followed by explicit `git add` guidance.
- [ ] Consider whether Step 11 commit convention should add an explicit `git add -u` recommendation as a safety net. Follow-up, not blocking.

## Related

- **BRIEFING.md** (updated 2026-04-20) — new note describing the trap.
- **P054** (Verifying) — the observed incident. Iter 1 commit `45e9c71` captured rename-only; iter 2 commit `b2f1646` carried the content edit alongside P046.
- `packages/itil/skills/manage-problem/SKILL.md` — primary fix target (Step 7).
- `packages/architect/skills/create-adr/SKILL.md` — secondary fix target (Step 6 supersession).
- **ADR-014** (governance skills commit their own work) — the commit-ordering rule that this trap violates when the re-stage is missed.
- **ADR-022** (Problem lifecycle Verification Pending) — the `.verifying.md` transition is a common trigger for this trap.
