---
"@windyroad/itil": patch
---

RFC-004 Slice F: --force-upstream-recheck flag wiring + TTL-expiry auto-recheck

Replaces the Slice C SLICE-C-FLAG-STUB string-match with proper tokenized
$ARGUMENTS parsing. Step 4.5a now recognises `--force-upstream-recheck`
and `--no-force-upstream-recheck` flags; unknown inbound-discovery flags
surface an advisory rather than silently ignoring.

Step 4.5b refactored into four explicit branches:

- force-flag branch — `--force-upstream-recheck` bypasses TTL.
- first-run branch — `last_checked == null`; fresh cache.
- TTL-expiry auto-recheck branch — `cache_age > ttl_seconds`; self-healing
  across maintainer cadence without requiring the explicit flag.
- cache-fresh within-TTL branch — silent-pass per ADR-013 Rule 5.

The auto-recheck branch is what makes the system self-healing — a
maintainer who runs `/wr-itil:review-problems` once a week still gets a
fresh poll after the 24h default TTL expires. The explicit flag is the
JTBD-202 pre-flight surface for tighter cadence (e.g. immediately before
a release).

Bats: SLICE-C-FLAG-STUB-absent assertion + 5 new Slice F assertions
covering tokenized parsing + TTL-expiry + cache-fresh + within-TTL
silent-pass + unknown-flag advisory.

Refs: RFC-004
