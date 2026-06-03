---
"@windyroad/itil": patch
---

P308: work-problems Step 6.5 cohort-graduation now routes evaluator `status=resolved` through a Rule 4 evidence-floor judgement step (necessary-but-not-sufficient) instead of treating it as graduate-now. Interactive surfaces per-held-entry AskUserQuestion (Graduate/Defer/Reject with inline evidence summary per P350 brief-before-ID); AFK queues a per-held-entry outstanding_question and does NOT graduate (P352 queue-and-continue default). Closes the AFK false-graduation hazard.
