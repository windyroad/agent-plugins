# AFK and Subprocess Iteration

Learnings about `/wr-itil:work-problems` AFK loops, `claude -p` subprocess dispatch, and iteration-worker protocols.

> **Sibling briefs** (P145 Tier-3 split): `afk-subprocess-mechanics.md` (dispatch shape, JSON contract, cost metadata, SID quirks) + `afk-subprocess-recovery.md` (SIGTERM flush, iteration-worker discipline, mid-loop escalation). Read all three together.
>
> **[`afk-ratification-hold.md`](./afk-ratification-hold.md)** (split out 2026-07-26, P099 Tier 3 rotation) carries the one thing to read before planning any AFK iteration that intends to fix something: it cannot land the code. ADR-090 + ADR-096 put human ratification at the story's `accepted` gate and there is no AFK path through it, so a fix-implementation iter walks story-map → RFC → story and stops. Plan for authoring the vehicle and queueing the ratification.

## What You Need to Know

- **Born-`confirmed` ADRs are hook-blocked in AFK subprocesses even when the substance was drain-ratified.** The P348 oversight-marker guard denies any Write carrying `human-oversight: confirmed` without a same-session substance-confirm marker (which needs an AskUserQuestion + `wr-architect-mark-oversight-confirmed`). Don't fight it, and don't cite the ADR-091 born-confirmed precedent (that shape needs an interactive event): write `human-oversight: unconfirmed` + an oversight-note quoting the drain ratification; the `/wr-architect:review-decisions` drain promotes it trivially. Witnessed P345 iter 2026-07-05 (ADR-092). <!-- signal-score: 1 | last-classified: 2026-07-15 | first-written: 2026-07-05 -->

> Four older entries (3 × 2026-05-17/05-18 dated + 1 × 2026-05-26 ADR-050 race that duplicates `hooks-and-gates.md`) archived 2026-06-08, the P382 headless `--plugin-dir` entry (2026-06-27) rotated out 2026-07-15, the `socket connection closed` P358 entry (2026-06-10, score 0) archived 2026-06-27, three settled verifying entries (P048/P053 evidence-verify, P053 surface-design-questions, P122/P126 Step 2.5b) archived 2026-06-28, the ADR-020 auto-release-skipped entry (undated, score 0, decayed) archived 2026-07-15, and the 2026-07-04 park-the-re-selected-ticket entry archived 2026-07-26 (Tier 3 rotation — split-by-date; the older 2026-06-28 guard-leak entry was kept in place because it scored signal that session), to `afk-subprocess-archive.md`. Load alongside this file for full history.

## What Will Surprise You

- **The AFK work-problems orchestrator exports `WR_SUPPRESS_OVERSIGHT_NUDGE=1` + `WR_SUPPRESS_PENDING_QUESTIONS=1`, and these LEAK into bats subprocesses spawned by an iter.** Any hook-test suite whose hook self-suppresses on one of those guards must `unset` it in `setup()` or its count/output-emitting tests fail spuriously inside AFK iters while staying green in CI (CI doesn't export the guards). P391 fixed the four nudge suites (jtbd/architect/itil-rfc oversight-nudge + risk-scorer scaffold-nudge); the reference pattern is `itil-pending-questions-surface.bats` (unsets in `setup()` + `teardown()`). Authoring a new nudge-hook bats suite → add the `unset` to setup() up front. (P391, 2026-06-28) <!-- signal-score: +2 | last-classified: 2026-06-28 | first-written: 2026-06-28 -->
