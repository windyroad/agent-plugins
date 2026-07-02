---
"@windyroad/itil": minor
---

Wire the ADR-090 unratified-story/map detector into the work-problems Step 2.4 oversight drain (P404 Phase 2). At loop end, `/wr-itil:work-problems` now runs `wr-itil-detect-unratified-stories-maps` alongside the architect/jtbd detectors and surfaces drift-reopened or never-ratified story maps and stories for re-ratification via the same Drain now / Defer nudge.
