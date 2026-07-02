---
"@windyroad/itil": minor
---

Remove the empty-stories atomic fallback from the work-problem/manage-problem Known-Error traversal (ADR-089 Phase 1). An RFC with empty `stories: []` is now a legacy/back-fill state, not a legitimate atomic-fix-adopter path — the traversal back-fills a story rather than falling back to per-RFC task dispatch. The `Refs: RFC-NNN` trailer remains valid for cross-cutting RFC work with no single story. (P404 / RFC-037 Phase 1.)
