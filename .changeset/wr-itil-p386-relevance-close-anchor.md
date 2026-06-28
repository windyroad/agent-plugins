---
"@windyroad/itil": patch
---

Fix two dangling cross-references in the `review-problems` Step 4.6 relevance-close pass. They anchored the AFK-silent close branch on `work-problems` "Step 6.5", which is the Release-cadence check and carries no relevance-close logic. The references now point at the actual mechanism: the relevance-close pass is reached via the `work-problems` side-effect dispatch path (Step 0b/0c/0d pre-flight + Step 3.6 pre-dispatch relevance gate), and its silent-close branch fires because the dispatched `claude -p` subprocess is AFK-by-construction (the Step 5 dispatch constraint forbids `AskUserQuestion` in the worker, per ADR-032 subprocess isolation). An adjacent Step 4.5 inbound-discovery reference carrying the same dangling pointer was corrected in the same pass. Documentation-accuracy only — the AFK-silent runtime behaviour is unchanged. (P386)
