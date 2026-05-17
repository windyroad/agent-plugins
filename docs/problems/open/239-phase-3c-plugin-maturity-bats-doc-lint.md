# Problem 239: Phase 3c — bats doc-lint per plugin asserts `maturity:` field shape, rollup invariant, rendered badge currency

**Status**: Open
**Reported**: 2026-05-17
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: S (deferred — re-rate at next /wr-itil:review-problems)

**Type**: technical

## Description

Phase 3c of the P087 plugin maturity rollout per ADR-063 §Phase 3 sub-iter shape. For each `packages/<plugin>/`, ship a bats fixture asserting:

1. `plugin.json` carries a `maturity:` field on every top-level entry (skill / agent / hook / command / sub-skill) whose value matches the ADR-063 schema (`{schema_version: "1.0", band, computed_at, evidence: {invocations_30d, days_shipped, closed_tickets_window, breaking_change_age_days}}`).
2. The plugin root entry carries a rollup `maturity:` field whose shape is `{schema_version: "1.0", band}` (rollup omits the evidence record per ADR-063 §Decision Outcome).
3. The rollup band equals the worst-case among constituent surfaces per ADR-053 §granularity contract (Experimental ≻ Alpha ≻ Beta ≻ Stable; Deprecated as overlay axis).
4. The README contains the prose-woven rollup badge matching the canonical `plugin.json` field (during Bootstrapping window: compound form with invocations + window; post-sunset: band-only).
5. **Anti-pattern checks (negative-presence assertions)**: README does NOT contain a standalone `## Maturity` section heading; README does NOT contain a shields.io URL pattern (`img\.shields\.io/badge/maturity`); per-skill table cells do NOT contain the compound bootstrapping rendering (compound is rollup-only).

ADR-052 behavioural — tests read `plugin.json` and assert field shape behaviourally, NOT by structural-grep on README content for the badge text (which would be brittle to plugin-author restructuring of the value-framing prose). The README presence assertion is structural on the badge marker but not on the full prose context — the marker is a stable string the renderer always emits.

May ship alongside Phase 3b (P238) in a single commit, or as a follow-on commit per ADR-014 commit grain. Recommend alongside for fixture-coverage-and-implementation co-location.

Child of P087. Driver: ADR-063 Phase 3 sub-iter contract.

## Symptoms

(deferred to investigation)

## Workaround

(deferred to investigation)

## Impact Assessment

- **Who is affected**: (deferred to investigation)
- **Frequency**: (deferred to investigation)
- **Severity**: (deferred to investigation)
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Author per-plugin bats fixture template; copy into each of 11 `packages/<plugin>/` directories with plugin-specific surface enumeration.
- [ ] Author anti-pattern negative-presence assertions (no standalone `## Maturity` section; no shields.io URL; no compound rendering in per-skill table cells).
- [ ] Verify rollup-equals-worst-case invariant assertion logic against a multi-band fixture (synthetic plugin with one Experimental skill + one Beta skill → rollup must be Experimental).
- [ ] Ensure bats fixtures discover plugins dynamically (no hard-coded list) so future plugin additions auto-inherit the doc-lint.

## Dependencies

- **Blocks**: P087 closure path
- **Blocked by**: P237 (Phase 3a — needs canonical fields to assert against) AND P238 (Phase 3b — needs rendered badges to assert against)
- **Composes with**: ADR-063 (Phase 3 presentation contract), ADR-052 (behavioural test default), ADR-053 (granularity + rollup-worst-case contract)

## Related

- P087 — parent
- ADR-063 — Phase 3 presentation-layer contract (schema being asserted)
- ADR-053 — granularity contract (rollup-worst-case invariant)
- ADR-052 — behavioural bats default
- P237 — Phase 3a population script (blocks)
- P238 — Phase 3b renderer + drift detector (blocks)
- P240 — Phase 3d JTBD outcome amendments
