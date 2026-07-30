---
status: draft
story-id: commit-gate-honours-risk-policy-stated-review-cadence
reported: 2026-07-05
decision-makers: [Tom Howard]
problems: [P408]
jtbd: [JTBD-001]
rfcs: [RFC-043]
story-maps: []
estimated-effort: S
---

# STORY-037: Commit gate honours the RISK-POLICY stated review cadence for staleness

**Reported**: 2026-07-05
**Problems**: P408
**JTBD**: JTBD-001
**RFCs**: RFC-043
**Story Maps**: (none — populate at accepted transition per I8)
**Estimated effort**: S

## User value (required, INVEST Valuable)

In order to stop the commit gate blocking commits against a risk policy that is current by its own stated review cadence, as a developer adopting @windyroad/risk-scorer, I want the gate's staleness threshold derived from my RISK-POLICY.md's `> Reviewed <cadence>` line — so the policy is the single source of truth and the gate never disagrees with the doc it enforces.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [x] A policy stating `Reviewed monthly`, last reviewed 16 days ago, is NOT flagged stale — the commit is allowed (the P408 witnessed case).
- [x] A policy with no cadence line keeps the existing 14-day fallback threshold — behaviour unchanged for adopters who state no cadence.
- [x] When both `> Last reviewed: <date>` and `> Reviewed <cadence>` lines are present, the cadence parses from the capital-R line, never the date line (regex-collision regression guard).
- [x] A policy whose stated cadence HAS elapsed is denied, and the deny message names the derived threshold and cadence word.
- [x] Behavioural bats cover the four cases above (ADR-052).

## Driving problem trace (required — I6 invariant)

- **P408** — the `POLICY_STALE` block in `packages/risk-scorer/hooks/risk-score-commit-gate.sh` hardcodes `> 14` days and never reads the policy's stated cadence, spuriously blocking every commit for adopters whose cadence exceeds 14 days.

## JTBD trace (required — I9 invariant)

- **JTBD-001** (Enforce Governance Without Slowing Down) — removes a false-positive commit-blocking friction class without weakening enforcement (the fallback preserves the gate for policies that state no cadence).

## Implementation notes (optional)

ADR-091 pins the machine-read contract: regex `(?m)^>?\s*Reviewed\s+([A-Za-z]+)` (case-sensitive, line-anchored); vocabulary weekly=7, fortnightly/biweekly=14, monthly=30, quarterly=90, annually/yearly=365; fallback 14.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- RFC-043 — the fix-time RFC this story implements (single-story atomic fix).
- ADR-091 — anchor decision (born-confirmed on the 2026-07-04 drain ratification).
