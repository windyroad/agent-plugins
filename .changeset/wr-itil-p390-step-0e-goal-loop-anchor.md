---
"@windyroad/itil": patch
---

work-problems: anchor the AFK loop with Claude Code's native /goal external evaluator (P390 reopened fix, ADR-094 / RFC-047 / STORY-040). New Step 0e documents the canonical goal condition, the anchor-guaranteed headless launch one-liner, and the interactive nudge-and-proceed fallback; the goal lives on the orchestrator session only. Step 2.4 Gate (0) now requires the re-scan classification table be PRINTED in turn output — the evidence the external evaluator judges — and an active goal makes ALL_DONE subject to independent per-turn confirmation (one-directional: a cleared goal never relaxes Gate (0)). work-problem (singular) documents the headless anchor shape. Paired promptfoo Tier-A/Tier-B eval cases per ADR-061 Rule 4.
