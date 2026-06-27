---
status: proposed
rfc-id: per-iter-git-worktree-isolation-afk-iter-dispatch
reported: 2026-06-27
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P305]
adrs: []
jtbd: []
stories: []
---

# RFC-033: Per-iter git worktree isolation for AFK iter dispatch (P305 Option B)

**Status**: proposed
**Reported**: 2026-06-27
**Problems**: P305
**ADRs**: (none)
**JTBD**: (none)

## Summary

Trace P305's ratified fix (Option B — per-iter git worktree). Each `claude -p` AFK
iteration subprocess operates in a dedicated `git worktree` so parallel iters no longer
share a working tree, eliminating the last-writer-wins Edit clobber that produces P305's
"post-Edit silent revert" symptom. Commits land on a short-lived per-iter branch; the
orchestrator merges back at iter completion. Option B was ratified by the user 2026-06-17
over Options A (serialise dispatch) and C (post-Edit verification helper) for the full
correctness envelope: true parallelism without the shared-tree race.

## Driving problem trace

- **P305** (Post-Edit silent revert of working-tree files before commit) — RCA confirmed
  parallel `claude -p` iter dispatch on a shared working tree produces last-writer-wins
  clobber on the Edit tool's read-modify-write cycle (two iters Read C0, A writes C1, B
  writes patch_B(C0) losing A's patch). Per-iter worktree isolation removes the shared
  surface the race depends on, so the symptom cannot occur. P305 § Fix Strategy "User
  ratification 2026-06-17 — Option B" names "capture an RFC (per ADR-060) tracing P305 +
  the orchestrator changes" as the going-forward step; this RFC is that trace.

## Scope

(deferred — populate at /wr-itil:manage-rfc accepted transition)

Anticipated surface (to be decomposed into stories at the accepted transition, not
ratified here): work-problems Step 5 dispatcher worktree setup/teardown; branch-per-iter
creation + merge-back protocol; plugin-cache divergence handling (each worktree may bind a
different cached plugin version unless explicitly aligned); interaction with the ADR-032
subprocess-isolation contract (worktree-per-iter is a stronger isolation primitive than
process-per-iter — reshapes ADR-032's post-subprocess `git status --porcelain` state-re-read
model; this design choice SHOULD be recorded as an ADR-032 amendment, confirmed via
AskUserQuestion per ADR-074, before the orchestrator changes land); sympathetic coordination
with the RFC-023 bundler-class change (P304).

## Tasks

- [ ] (deferred — populate at /wr-itil:manage-rfc accepted transition)

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook per ADR-060 Phase 1 item 12)

## Related

(captured via /wr-itil:capture-rfc; expand at next /wr-itil:manage-rfc invocation)

- P305 — driving problem; ratified Option B 2026-06-17.
- ADR-032 — AFK iteration isolation via subprocess boundary; Option B reshapes it to worktree-per-iter.
- ADR-074 — confirm a decision's substance before building; Option B substance ratified before this RFC.
- RFC-023 — bundler-based shared code (P304); sympathetic to per-worktree builds.
