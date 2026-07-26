# Problem 467: work-problems should surface decisions/ratifications continuously (non-blocking), not only batched at loop-end

**Status**: Open
**Reported**: 2026-07-26
**Priority**: 8 (Medium) — Impact: 2 × Likelihood: 4 — derived at capture per Step 4a. Impact 2: UX/throughput improvement, no correctness harm (the loop already progresses + batches at end). Likelihood 4: every AFK loop with a present-or-intermittently-present user accumulates ratifications that could be actioned sooner.
**Origin**: corrective-feedback (user, 2026-07-26)
**Effort**: M — new surfacing mechanism + non-blocking contract; touches work-problems Step 2.5 / outstanding_questions plumbing.
**WSJF**: 4 — (8 × 1.0) / 2
**JTBD**: JTBD-006
**Persona**: plugin-developer

## Description

The AFK loop's incremental design is correct: each fix-shaped iter does the next doable part (RCA, vehicle authoring) and holds the code pending human ratification, then the loop surfaces all queued decisions/ratifications at loop-end (Step 2.4 / Step 2.5) so the next loop can process a bit further. User confirmed this is intended (2026-07-26).

The enhancement the user voiced: *"if there's a way to have the iterator working through the loop, and surface the decisions and ratifications without blocking the loop, that would be even better."* Today the outstanding_questions accumulate and surface only in one batch at loop-end. When the user is present (or intermittently present) mid-loop, they could ratify held vehicles as they arise — unblocking subsequent iters within the SAME loop run — instead of waiting for the whole loop to end and re-invoking. The key constraint: surfacing must NOT block the loop (the iter/orchestrator keeps advancing other tickets while a ratification waits).

## Symptoms

- A held vehicle (e.g. P429 commit-convention reshape, P430 STORY-047) authored early in a loop cannot be ratified until the entire loop ends, so its code fix can't land until a whole new loop run.
- A present user watching the loop sees ratifications pile into a single end-of-loop batch rather than being offered them as they arise.

## Workaround

Current: the loop batches all outstanding_questions at Step 2.4 gate (a) / Step 2.5 and the user ratifies then; each subsequent loop run advances the ratified vehicles one more step.

## Impact Assessment

- **Who is affected**: maintainer running work-problems while present/intermittently present; loop throughput on fix-shaped tickets.
- **Frequency**: every loop that authors held vehicles (currently most fix-shaped iters — see P456 throughput observation).
- **Severity**: Medium (8) — throughput/UX; no correctness harm.
- **Analytics**: 2026-07-26 loop — P429 + P430 both authored held vehicles surfaced only at loop-end.

## Root Cause Analysis

### Investigation Tasks

- [ ] Design a non-blocking continuous-surface mechanism: emit a ratification-available signal as each iter queues one, without the orchestrator waiting on it (the loop keeps dispatching other dispatchable tickets).
- [ ] Define how a mid-loop ratification result re-enters the loop (re-scan the now-unblocked vehicle on the next Step 1) without violating the iter subprocess boundary (ADR-032).
- [ ] Reconcile with Step 2.4 gate (a) loop-end batch — continuous surface should supplement, not replace, the end-of-loop drain.

## Dependencies

- **Composes with**: P135 (loop-end outstanding_questions surface — the mechanism this extends), P342 (retro auto-ticket carve-out), P348 (oversight-unconfirmed drain at gate (a)), P456 (fix-shaped-ticket selector / throughput), P401 (queued-elicitation caller-side wiring — same "route queued items into the loop's surface" shape).

## Related

- Captured via `/wr-itil:capture-problem` during a `/wr-itil:work-problems` session (2026-07-26) after the user clarified the intended incremental loop design and voiced the non-blocking-surface enhancement.
- Related theme (session memory): a governance action with no automatic cadence never happens — a non-blocking continuous surface is a stronger cadence than batch-at-loop-end for the present-user case.
