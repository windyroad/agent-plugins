# Problem 437: wr-wardley exposes no version-stable invocation path for its owm-to-svg converter (consumers pin the cache version and break on bump)

**Status**: Open
**Reported**: 2026-07-06
**Priority**: 9 (Medium) — Impact: 3 × Likelihood: 3
**Origin**: inbound-reported (#325)
**Effort**: S. WSJF = (9 × 1.0) / 1 = 9.0.
**WSJF**: 9 — (9 × 1.0) / 1 (added 2026-07-26 review)
**JTBD**: JTBD-101
**Persona**: plugin-developer

## Description

A downstream consumer (`wr-newsletter` step 7) invokes wr-wardley's converter by a version-pinned cache path (`.../cache/windyroad/wr-wardley/0.1.0/skills/generate/owm-to-svg.mjs`), which breaks with `Cannot find module` on every wr-wardley version bump. wr-wardley provides no version-stable invocation path (PATH shim / skill-mediated entry) for its converter — same no-version-pinned-paths class as P137/P317, but on the *consumer-invokes-plugin* axis.

## Symptoms

- Any consumer that renders a Wardley map via the pinned converter path breaks the moment wr-wardley publishes a new version (the cache dir name changes).

## Impact Assessment

- **Who is affected**: consumers invoking the wr-wardley converter across plugin updates.
- **Frequency**: every wr-wardley version bump.
- **Severity**: Medium — breaks map render until the consumer re-pins.

## Root Cause Analysis

### Investigation Tasks

- [ ] Expose a version-stable invocation path for the owm-to-svg converter (ADR-049 PATH shim or a skill-mediated entry point), so consumers never reference a version-pinned cache path.

## Dependencies

- **Composes with**: P137 / P317 (published-artifact path portability — same class, consumer-invocation axis).

## Related

- Inbound issue #325. The `wr-newsletter` SKILL that trips this is a downstream artifact; the windyroad-side fix is the stable wr-wardley entrypoint.
