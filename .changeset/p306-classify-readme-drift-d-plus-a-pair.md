---
"@windyroad/itil": patch
---

Extend `classify-readme-drift.sh` to recognise same-ID delete+add (D+A) pairs as same-session coverage alongside the pre-existing staged-rename (R/RM) shape. A substantial-body `git mv` defeats git's rename-detection and renders the move as a delete + add for the same ticket ID — previously treated as uncovered and triggered a false HALT_ROUTE_RECONCILE during the in-flow drift classification. The classifier now intersects DELETED_IDS ∩ ADDED_IDS from `git status --porcelain -u` (the `-u` flag is essential — without it git collapses untracked directories to `?? <dir>/`, hiding the `??` side of a D+`??` pair). Dispositions are unchanged; only the detection mechanism widened to close the coverage gap. Single-commit grain and AFK fail-safe semantics preserved.
