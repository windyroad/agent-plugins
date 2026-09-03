# Problem 533: Duplicate ticket IDs are silently swallowed by the README reconciler

**Status**: Verification Pending
**Reported**: 2026-09-03
**Priority**: 8 (Medium) — Impact: 2 × Likelihood: 4 — derived at capture from the description per Step 4a
**Origin**: internal
**Effort**: M — derived at capture per Step 4a
**JTBD**: JTBD-006
**Persona**: plugin-developer

## Description

Two sessions can independently claim the same problem-ticket number, leaving one ID on two files in different states. Observed: ticket 238 existing as both open and verifying, created by different sessions.

`packages/itil/scripts/reconcile-readme.sh` builds its filesystem-truth map keyed by ID, so when two files claim one ID the second enumerated file silently overwrites the first. The drift checker then trips on whichever file survived, and reports ordinary-looking `DRIFT` / `STALE` / `MISSING` rows that give no indication an ID clash is the actual cause. The reader is left chasing a phantom README inconsistency.

The reconciler should detect the clash explicitly and renumber the later claimant automatically, resolving which ticket claimed the number first from main's git history when creation order is otherwise ambiguous.

## Symptoms

- The README drift checker reports drift rows for a ticket whose README row looks correct, because the row describes the file that was overwritten in the map rather than the one that survived.
- `ls docs/problems/*/238-*` returns two files in different state directories.
- No output anywhere names the clash.

## Workaround

Renumber one of the clashing tickets by hand: pick the later claimant, `git mv` it to a free ID, and rewrite its own ID references plus every reference to it from other documents.

## Impact Assessment

- **Who is affected**: anyone reading the drift report — most often an AFK orchestrator picking the next ticket, which burns iterations on a drift row it cannot resolve.
- **Frequency**: whenever two sessions capture a ticket concurrently without fetching in between. Worktrees and background iters make this routine rather than rare.
- **Severity**: the backlog stays navigable, but the drift signal that is supposed to be trustworthy silently lies about its cause.
- **Analytics**: none collected.

## Root Cause Analysis

`FS_STATUS["$id"]` is a plain associative-array assignment inside both enumeration loops, so a repeated ID is last-writer-wins with no collision check. The per-state subdir loop runs after the flat loop deliberately (ADR-031 authoritative state), which makes the overwrite correct for the cross-layout migration race it was designed for — but wrong for two genuinely distinct tickets.

### Investigation Tasks

- [x] Detect the clash: record every file per ID and emit a `CLASH` drift row when an ID has more than one.
- [x] Renumber the later claimant under an opt-in `--fix-clashes` flag, allocating the next free ID via the ADR-019 `max(local, origin) + 1` rule.
- [x] Resolve creation order from main's git history (first-add commit time), falling back to mtime outside a repo.
- [x] Rewrite every resolvable reference to the renumbered ticket across the docs corpus; report the genuinely ambiguous ones (user direction 2026-09-03).
- [x] Wire the flag into the `/wr-itil:reconcile-readme` skill so the fix is reached automatically when the drift it explains is detected.

## Fix Released

**Release vehicle**: `@windyroad/itil@2.2.0`, published 2026-09-03 (commit `622c7330`, merged as `ab8da4a0e`).

The reconciler emits a `CLASH` row naming both claimants; `classify-readme-drift` short-circuits on it so no working-tree rename can make a clash look deferrable; `--fix-clashes` renumbers the later claimant, resolving who claimed first from the first-add commit on the resolved base ref and allocating `max(local, origin) + 1`; and `/wr-itil:reconcile-readme` Step 1a reaches for the flag when a clash is present. Covered by 33 reconciler bats, 19 classifier bats, 21 skill-contract bats, and a promptfoo SKILL-prose eval observed 3/3.

**Likely verified?** no — not observed. No clash exists in the corpus right now (the reported pair was resolved before this ticket was captured), so the repair path has not run against real data. Verification is the next clash the reconciler meets, or a deliberate reproduction.

## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-085 | STORY-085: See the ID clash instead of the drift it causes | accepted |

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: the ID-allocation surface in `/wr-itil:capture-problem` and `/wr-itil:manage-problem`, which is where a clash originates.

## Related

Captured via `/wr-itil:capture-problem`. The hang-off check surfaced P136, P151 and P152 as candidates — all three mention `reconcile-readme.sh` only incidentally (as an audit inventory item, as a path-resolution example, and as prior art respectively), none is about the reconciler's ID-keyed truth model, so this was captured as a sibling rather than absorbed. Its natural composes-with edges are the reconciler script itself and the next-ID allocation surface; `/wr-itil:review-problems` can cluster it later if a common parent emerges.

Follow-up, not in this fix: `max(local, origin) + 1` cannot land on a number that exists locally or on the remote, but it can reuse one that was deleted from both. ADR-115 solved that same reuse hazard for story-map IDs by taking the maximum over git history as well. Problem-ticket allocation stays on the local-plus-origin rule for now, because STORY-085 pins it; worth revisiting together with the note below.

ADR-019 owns the next-ID allocation rule this ticket's renumber must obey. ADR-019 predates both the per-state subdirectory layout and the same-working-tree concurrency vector that produces this clash — its guard is origin-facing only — so it is worth reassessing alongside the fix.
