---
"@windyroad/itil": patch
---

work-problems: forbid turn-end-survivor background tasks in AFK iter dispatch

The AFK `/wr-itil:work-problems` orchestrator dispatches each iteration as a
single-shot `claude -p` subprocess, which has no auto-resume: the iteration's
turn boundary is its process boundary. A backgrounded task whose completion is
deferred to a later turn (a `run_in_background` Agent/Bash call, or a
`&`-detached job awaited across turns) never resumes — the iteration exits at
turn-end with its work staged but uncommitted, and the work is lost.

The Step 5 iteration-prompt body now carries a prohibition clause, scoped to the
cross-turn / turn-end-survivor shape, directing iterations to use
foreground-synchronous invocation (or an intra-turn background they reap before
turn-end). It explicitly preserves the existing sanctioned intra-turn
`run_in_background` + `BashOutput`-poll-then-`wait` idiom and joins the existing
ScheduleWakeup and bash-polling antipattern bans in the same constraints list.
