---
"@windyroad/itil": patch
---

`/wr-itil:work-problems` Step 0 session-continuity detection now applies a staleness filter to `.afk-run-state/iter-*.json` error markers — a marker is load-bearing only if its mtime is newer than HEAD's commit time OR within the last 24h (whichever is more permissive). Stale residuals (older than HEAD AND older than 24h) are silently skipped instead of indefinitely false-positive halting the loop or asking the user.

Closes the indefinite-halt class where an iter-error-marker from a prior session whose work has since been verified-closed via an intervening commit would still fire the Step 0 gate on every subsequent AFK invocation. When ≥1 stale marker is skipped, the iter summary emits a one-line annotation naming the count + oldest marker for audit-trail traceability (JTBD-006).

Driver: P333. Trace: RFC-015 (problem-traced retro-fit per ADR-071). No ADR amendment in this change — ADR-019 in-place amendment naming the staleness predicate at the P109-extension surface deferred to a follow-up ticket per architect advisory.
