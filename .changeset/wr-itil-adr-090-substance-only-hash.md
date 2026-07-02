---
"@windyroad/itil": minor
---

Refine the ADR-090 oversight fingerprint to substance-only (P404). The `oversight-hash` now excludes lifecycle-progress — the `status` field, acceptance-criterion checkbox ticks, and slice `data-status` — so advancing a story or map through its lifecycle no longer spuriously re-opens ratification; only a substance change (value statement, criterion text, structure) drifts the marker.
