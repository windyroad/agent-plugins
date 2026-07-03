---
"@windyroad/itil": patch
---

work-problems: forbid the wrap-time "batch-report upstream" deferral nudge (P413)

The AFK `/wr-itil:work-problems` orchestrator was ending loops with a "N
upstream-blocked tickets are unreported — re-run and choose batch-report
upstream" nudge, leaving tickets unfiled. There is no batch-report mode:
upstream-blocked tickets already auto-invoke `/wr-itil:report-upstream`
per-iter at Step 4 (below-appetite sends, above-appetite queues per P352;
ADR-024 P270). The Output Format section now carries a `### Reported Upstream`
summary subsection that reports ACTUAL filings and an invariant forbidding the
wrap-time deferral nudge (agent-invented loop-control class P390/P341/P175).
Behavioural second-source added to the work-problems promptfoo eval.
