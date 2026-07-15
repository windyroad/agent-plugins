---
"@windyroad/itil": patch
---

work-problems Step 3.6: same-session-adjudication carve-out for CLOSE-CANDIDATE-WITH-CAVEAT — when a same-day interactive review pass already adjudicated the caveat cohort (0 closes, over-fire class recorded in a durable artefact), the orchestrator treats the verdict as resolved-KEEP and dispatches instead of re-queueing a decided question. Class-bound; resolves only toward KEEP, never close; one iter annotation per application. (User-directed 2026-07-15; prevents a known evaluator over-fire from skipping the mature Known-Error tier and inverting tier selection.)
