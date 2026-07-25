# Problem 451: work-problems Step 5 iter/pre-flight dispatch exceeds the interactive-harness 10-minute foreground Bash ceiling (SIGTERM + 0-byte JSON)

**Status**: Open
**Reported**: 2026-07-15
**Priority**: 9 (Medium) — Impact: 3 (Moderate — the loop cannot make forward progress on any ticket whose iter exceeds 10min when orchestrated foreground from an interactive session; partial pre-flight writes need revert-and-proceed recovery) × Likelihood: 3 (Possible — every iter/pre-flight over 10min under interactive orchestration; observed 2026-07-03 at exactly 600s) — derived at capture per Step 4a
**Origin**: inbound-reported (#327)
**Effort**: M — rearchitect Step 5 dispatch to the harness background primitive (`run_in_background: true`, detached across turns, re-invokes on completion) instead of an in-call poll loop; composes with P427's per-ticket lock design
**WSJF**: 4.5 — (9 × 1.0) / 2 (added 2026-07-26 review)
**JTBD**: JTBD-006
**Persona**: developer

## Description

`/wr-itil:work-problems` Step 5 dispatches each iteration (and the Step 0b/0c/0d pre-flights) to a `claude -p` subprocess wrapped in a backgrounded poll loop inside a single Bash call, assuming the orchestrator can foreground-wait up to `WORK_PROBLEMS_IDLE_TIMEOUT_S` (default 3600s). The interactive Claude Code harness caps a single foreground Bash call at 10 minutes, so any iter or pre-flight running longer is SIGTERM'd at ~600s with a 0-byte JSON file (the P147 stuck-before-emit class) and no iter work lands.

Observed 2026-07-03: the Step 0b review-problems pre-flight subprocess died at exactly 10min (exit 143, empty JSON), forcing the P358 non-blocking revert-and-proceed path (reverting partial `.upstream-cache.json` + audit-log writes). The poll-loop shape is designed for a host permitting unbounded foreground shell waits; the interactive harness is not that host.

## Symptoms

- Step 0b pre-flight: exit 143, 0-byte JSON, at ~600s wall-clock.
- Any manage-problem iter dispatched as a single foreground Bash call is capped at 10min regardless of `WORK_PROBLEMS_IDLE_TIMEOUT_S`.

## Workaround

Dispatch long subprocesses via the harness background primitive (Bash `run_in_background: true`), which runs detached across turns and re-invokes the orchestrator on completion.

## Impact Assessment

- **Who is affected**: developer persona — anyone running work-problems foreground from an interactive session.
- **Frequency**: every >10min iter/pre-flight under interactive orchestration.
- **Severity**: Moderate — silent forward-progress failure with metadata loss (0-byte JSON).
- **Analytics**: downstream repo tracked as P110.

## Root Cause Analysis

### Investigation Tasks

- [ ] Rework Step 5 (and Step 0b/0c/0d pre-flight) dispatch to the background-primitive shape; define the completion re-invocation contract.
- [ ] Reconcile with P427's per-ticket advisory-lock design (background dispatch widens the concurrency window).
- [ ] Create reproduction test.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P427 (double-dispatch lock — the background primitive interacts with its lock design), P428 (same Step 5 surface, bash-3.2 parse defect — do not fold), P261/P307 (verifying — iter-failure-class siblings; P261's salvage path is reusable by this ticket's recovery story)

## Related

- Upstream issue #327 (inbound; reporter's downstream ticket P110).
- Hang-off arbitration 2026-07-15 (wr-itil:hang-off-check): PROCEED_NEW — P428 is a launch-time parse failure vs this runtime ceiling; P427 is a concurrency-control gap (composes, doesn't absorb); P307's shipped fix is the skill's own idle-timeout formula (suspend-detect inside the poll loop), whereas here the harness kills the call regardless of any formula; P261 is the `is_error` self-exit class with metadata preserved — opposite failure envelope. Iter-failure-class cluster (P121/P146/P147/P261/P307) noted for a possible "Step 5 dispatch resilience" master at a future review.
