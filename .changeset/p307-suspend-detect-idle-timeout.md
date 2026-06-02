---
"@windyroad/itil": patch
---

Fix work-problems Step 5 idle-timeout SIGTERM false-kill on machine-sleep (P307). The poll loop computed `IDLE_SECONDS = NOW - LAST_ACTIVITY_MARK` using wall-clock; laptop suspend between the 60s polls inflated the apparent idle to multi-hour values, tripping SIGTERM on a working iter (2026-05-26 evidence: idle jumped 481s -> 1016s -> 5544s across suspend gaps; SIGTERM at 5544s > 3600s threshold lost the iter's commit + cost metadata as exit 143 + 0-byte JSON per the P147 stuck-before-emit class).

Detect large wall-clock jumps between consecutive polls (`ACTUAL_POLL_DELTA > EXPECTED_POLL_DELTA_S + SUSPEND_JITTER_S` = 60 + 120 = 180s) as suspend events and accumulate the gap-minus-expected into `SUSPEND_OFFSET_S`. `IDLE_SECONDS = (NOW - SUSPEND_OFFSET_S) - LAST_ACTIVITY_MARK` then reads active-elapsed rather than wall-clock-elapsed. Pure-bash heuristic — no `CLOCK_MONOTONIC` dependency (bash doesn't expose it), no iter-side contract change (purely orchestrator-side).

Locus: `packages/itil/skills/work-problems/SKILL.md` Step 5 poll loop + the LAST_ACTIVITY_MARK signal trade-off paragraph extended with the suspend-detect rationale (alternative signals — monotonic clocks, heartbeat files — considered and rejected). Behavioural second-source in `packages/itil/skills/work-problems/test/work-problems-step-5-idle-timeout-sigterm.bats` (8 new tests: algorithm unit tests covering normal cadence / within-jitter / at-threshold / detected-suspend / 2026-05-26 5544s evidence reproduction + SKILL.md doc-lint contract assertions). Full bats suite 22/22 GREEN.
