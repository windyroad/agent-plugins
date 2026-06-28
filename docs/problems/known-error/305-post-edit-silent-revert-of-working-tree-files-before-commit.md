# Problem 305: Post-Edit silent revert of working-tree files before commit — potential silent-work-loss hazard

**Status**: Known Error
**Reported**: 2026-05-26
**Priority**: 6 (Med) — Impact: 3 (Moderate) x Likelihood: 2 (Possible) — re-rated 2026-06-08 from earlier deferred 3
**Origin**: internal
**Effort**: M (ticket update; substantive fix M-L pending fix-strategy ratification)

## Description

Surfaced during the P258 AFK iter (2026-05-26). Edit-tool writes to several files (`docs/briefing/`, `docs/decisions/063`, `docs/problems/open/263`) returned **success**, but the edits were **reverted before commit** — a subsequent grep showed the written content gone (grep=0). Re-applying the edit + an **immediate `git add`** persisted it; the committed work was verified intact in the iter's commit. The same-iter edits to the primary ticket (258) survived without re-apply.

Recurrence observed 2026-06-08 during the P228 fix iter: SKILL.md edits at ~14:20 silently reverted to pre-iter state by 14:28; the harness emitted a "modified either by the user or by a linter, intentional" system reminder; recovery was re-apply at 14:34 which persisted. Flagged in retro Pipeline Instability section as ungrounded at the time.

## Symptoms

- Edit tool reports success; subsequent grep / Read of the target file shows the content absent or reverted to pre-edit state.
- Re-apply + immediate `git add` persists; without the immediate stage the edit is lost.
- Harness emits "modified either by the user or by a linter, intentional" system reminder on the next read — Claude Code's built-in external-modification signal.
- Affects governance docs under `docs/briefing/`, `docs/decisions/`, `docs/problems/`, AND shippable code under `packages/<plugin>/skills/*/SKILL.md` (P228 iter empirical).

## Root Cause Analysis

**Confirmed 2026-06-08**: parallel `claude -p` iteration subprocess dispatch on a shared working tree, with overlapping file edits, produces last-writer-wins clobber on the Edit tool's read-modify-write cycle.

### Evidence

`.afk-run-state/` JSON timing for the P228 retro mystery:

| Iter | json mtime | duration_ms | inferred start | overlap window |
|------|------------|-------------|----------------|----------------|
| P213-fix (`iter-p213-fix.json`) | 14:41 | 2,570,430 (~42.8 min) | ~13:58 | 13:58 → 14:41 |
| P228-fix (`iter-p228-fix.json`) | 14:58 | 3,567,758 (~59.5 min) | ~13:58 | 13:58 → 14:58 |

The 14:28 mystery revert sits squarely inside the 13:58 → 14:41 parallel window. Both iters were live `claude -p` subprocesses simultaneously editing files in the same working tree.

The mechanism: the Edit tool reads the target file at edit-time, computes `old_string` → `new_string` substitution, writes the result back. Without cross-process locking, two parallel iters that:

1. Both Read the file at time T0 (both see content C0)
2. Iter A Edits the file at T1 (disk now has C1 = patch_A(C0))
3. Iter B Edits the file at T2 (disk now has C2 = patch_B(C0) — A's patch lost; B's read was stale)

— produce the observed "silent revert" symptom. The harness's "modified by user or linter" reminder fires when iter A subsequently Reads the file at T3 and sees C2 instead of its expected C1.

### Dispatch evidence

`.afk-run-state/dispatch-iter1.sh` line 18 backgrounds `claude -p ... &` and polls the PID. The orchestrator (work-problems Step 5) can dispatch multiple `dispatch-iterN.sh` scripts concurrently — the per-iter dispatcher does not serialize against sibling iters. Confirmed empirically by the P213-fix + P228-fix overlap above.

### What is NOT the cause

Investigation ruled out the following candidates:

- **External formatter / watcher**: no `.prettierrc*`, `.eslintrc*`, `lint-staged`, husky, or `.vscode/settings.json` autoformat settings present. The repo carries no on-save formatter.
- **Sync scripts (`scripts/sync-*.sh`)**: invoke-only (manual `npm run sync:*` or CI); never auto-fire during AFK iters.
- **Editor / LSP auto-revert**: would not explain the harness's own "modified ... intentional" signal — that signal fires for ALL out-of-band writes, not just editor writes; the parallel-iter hypothesis explains the signal without requiring an editor open over the file.
- **Single-iter harness file-state race**: rejected because the workaround (re-apply + immediate `git add`) succeeds on the second attempt within the same iter — a same-iter race would recur.

### Investigation Tasks

- [x] Re-rate Priority and Effort at next /wr-itil:review-problems. — done 2026-06-08 (3 → 6).
- [x] Reproduce: identify whether an external formatter/watcher, editor auto-format, or a harness race causes the post-Edit revert. — done 2026-06-08; parallel `claude -p` iter race on shared working tree.
- [ ] Ratify a fix strategy (substance-confirm pending — see Fix Strategy below).
- [x] Assess blast radius: which file types/paths are affected (docs/ only, or source too?). — done; affects ALL paths, including shippable code under `packages/*/skills/*/SKILL.md` (P228 evidence).
- [ ] Implement the ratified fix in a follow-up iter.
- [ ] Add a behavioural reproduction test once the fix strategy is ratified (test shape depends on the chosen mechanism).

## Workaround

Re-apply the Edit + immediately stage with `git add <path>`. Once staged, subsequent parallel writes from sibling iters cannot silently clobber — `git add` snapshots into the index, and a subsequent working-tree clobber is observable via `git status` rather than silent. The agent's mid-iter recovery in the P228 iter followed this pattern.

This workaround is manual / agent-discovered after the fact. It does not automatically catch silent reverts that the agent never re-Reads.

## Fix Strategy

Three candidate fix surfaces, all requiring ADR ratification before implementation per ADR-074 (Confirm a decision's substance before building dependent work). The substance-confirm question is queued to `.afk-run-state/outstanding-questions.jsonl` (category: direction) for loop-end interactive batched surfacing — DO NOT build on any of these options until the user picks.

**Option A — Serialize iter dispatch** (smallest blast radius): work-problems Step 5 dispatches one `claude -p` subprocess at a time; waits for `ITERATION_SUMMARY` + completion before launching the next. Eliminates the race by removing concurrency. Cost: AFK loop wall-clock roughly doubles (no overlap of API time across iters). Composes with the existing P121 idle-timeout SIGTERM. The simplest mechanical fix.

**Option B — Per-iter `git worktree`** (largest correctness envelope): each `claude -p` iter operates in a dedicated `git worktree` (e.g., `.afk-worktrees/iter-NNN/`); commits land on a short-lived branch; orchestrator merges back at iter completion. Fully eliminates shared-WT contention across all tools (not just Edit). Cost: complex orchestration; merge-conflict resolution surface; per-iter disk + setup time; potential plugin-cache divergence per worktree.

**Option C — Post-Edit verification helper** (advisory + auto-recover): a `verify-edit-persisted` helper any iter SKILL invokes after critical Edits (`Read` the file → diff against expected content → re-apply + `git add` on miss). Detects + recovers without eliminating the race. Cost: SKILL.md contract change across every iter-bearing skill; requires the iter agent to remember to call the helper; doesn't catch reverts of files the iter never re-Reads.

**Recommendation (architect FLAG, not ratified)**: Option A is the simplest mechanical correction with the smallest blast radius and clearest invariant (no parallel iters = no race). Wall-clock cost is real but bounded; Options B + C add complexity without strictly eliminating the underlying mechanism. Surface for user ratification.

### User ratification 2026-06-17 — Option B (per-iter git worktree) chosen

User ratified **Option B (per-iter git worktree)** via AskUserQuestion during the 2026-06-17 outstanding-questions drain. Rationale: full isolation gives true parallelism without shared-tree race; complexity is accepted as worth the correctness envelope. The bundler-class change (P304/RFC-023) is sympathetic to per-worktree builds — they can coordinate.

Next step: capture an RFC (per ADR-060) tracing P305 + the orchestrator changes — per-iter worktree setup, branch creation per iter, merge-back protocol, plugin-cache divergence handling (each worktree may bind a different cached plugin version unless explicitly aligned). Options A and C are now rejected as the going-forward shape.

## Dependencies

- **Blocks**: any future AFK iter that edits shared files in parallel (the recurrence class).
- **Blocked by**: substance-confirm ratification on Option A / B / C (queued to outstanding_questions, ADR-074).
- **Composes with**: P258 (the iter that surfaced this); P228-fix + P213-fix parallel iters (2026-06-08 recurrence evidence); P192 + P213 (work-problems Step 5 dispatcher surface — fix landing surface for Option A); ADR-032 (subprocess-isolation contract — Options A/B both interact with the AFK iteration-isolation invariant).

## Related

- P258 — the AFK iter that surfaced this (2026-05-26).
- P228 implementation iter retrospective `docs/retros/2026-06-08-p228-impl-iter.md` — recurrence evidence; documents the 14:28 mystery in Pipeline Instability section.
- ADR-032 — AFK iteration isolation via subprocess boundary. Options A / B both touch this contract; B reshapes it (worktree-per-iter is a stronger isolation primitive than process-per-iter).
- ADR-074 — Confirm a decision's substance before building dependent work. The propose-fix surface here defers implementation until the user ratifies one of A / B / C.

(captured 2026-05-26 during the P283 prong-2 drain surfacing — user-directed "capture an investigation ticket"; investigation completed 2026-06-08 during the P305 work-problems iter)

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-033 | proposed | Per-iter git worktree isolation for AFK iter dispatch (P305 Option B) |
