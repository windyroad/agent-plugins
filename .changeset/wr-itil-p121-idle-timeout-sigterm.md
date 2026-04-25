---
"@windyroad/itil": patch
---

`/wr-itil:work-problems` Step 5 backgrounds the iteration subprocess and runs a 60s poll loop with an idle-timeout SIGTERM branch. When `now - LAST_ACTIVITY_MARK > WORK_PROBLEMS_IDLE_TIMEOUT_S` (default 3600s = 60 min), the orchestrator sends SIGTERM to the stuck `claude -p` PID. SIGTERM empirically produces a clean JSON exit-flush — the subprocess responds with a valid `is_error: false` envelope and parseable `ITERATION_SUMMARY` block within seconds. Override the threshold per-environment via the `WORK_PROBLEMS_IDLE_TIMEOUT_S` env var. Closes P121. ADR-032 amended with the backgrounded-poll-loop refinement under the subprocess-boundary variant; new behavioural fixture in `test/work-problems-step-5-idle-timeout-sigterm.bats` provides the second-source for the production observation that motivated the fix.
