---
"@windyroad/itil": minor
---

P220: wire `/wr-itil:work-problems` Step 0d to pre-flight `/wr-itil:check-upstream-responses` when the outbound-responses cache is stale, missing, or has `last_checked: null` AND back-link tickets carrying `## Reported Upstream` sections exist. Outbound symmetric counterpart to Step 0b's inbound-discovery pre-flight per ADR-062 § JTBD-006 driver. Cache TTL defaults to 86400s (24h) symmetric with the inbound axis; per-cache override via `ttl_seconds` field. Adopter-portable via the `wr-itil-check-outbound-responses-staleness` ADR-049/080 PATH shim. Closes the cadence-wiring gap P249 Phase 1 explicitly deferred ("Phase 1 ships manual-invocation only"). Behavioural bats covers 10 cases (5 outcomes × dual-tolerant layout + custom-TTL + default-TTL). ADR-062 Confirmation #5 amended with the Step 0d clause; `check-upstream-responses` SKILL Confirmation #7 added with drift-source contract marker symmetric across helper / Step 0d / Confirmation round-trip.
