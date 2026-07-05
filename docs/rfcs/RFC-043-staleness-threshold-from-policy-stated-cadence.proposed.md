---
status: proposed
rfc-id: staleness-threshold-from-policy-stated-cadence
reported: 2026-07-05
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P408]
adrs: [ADR-091]
jtbd: [JTBD-001]
stories: [STORY-037]
---

# RFC-043: Derive the commit-gate RISK-POLICY staleness threshold from the policy's stated review cadence

**Status**: proposed
**Reported**: 2026-07-05
**Problems**: P408
**ADRs**: ADR-091
**JTBD**: JTBD-001

## Summary

Derive the commit-gate RISK-POLICY staleness threshold from the policy's stated review cadence per ADR-091 (Commit-gate staleness threshold derives from RISK-POLICY.md's stated review cadence). Fix-time RFC auto-created by the I13 `no-rfc-trace` directive (ADR-072 placement / ADR-073 auto-create) during the P408 implementation iteration; the fix substance was ratified in the 2026-07-04 interactive decision drain (P408 § Ratified Direction, option (a)).

## Driving problem trace

- **P408** (`risk-score-commit-gate` hardcodes a 14-day RISK-POLICY staleness threshold, ignoring the policy's stated review cadence) — the `POLICY_STALE` block in `packages/risk-scorer/hooks/risk-score-commit-gate.sh` hardcodes `> 14` days and never reads the policy's `> Reviewed <cadence>` line, spuriously blocking commits for every adopter whose stated cadence exceeds 14 days (witnessed 2026-07-02: quarterly policy, 16 days since review, all commits blocked).

## Scope

Single-story atomic fix, scoped by ADR-091's machine-read contract:

- Extend the `POLICY_STALE` python block to parse the cadence line (`(?m)^>?\s*Reviewed\s+([A-Za-z]+)`, case-sensitive, never binding the lowercase `> Last reviewed:` date line) and derive the threshold: weekly=7, fortnightly/biweekly=14, monthly=30, quarterly=90, annually/yearly=365; fallback 14 when absent/unrecognised.
- Deny message names the derived threshold + cadence word.
- Behavioural bats per ADR-091 § Confirmation (4 cases, including the capital-R regex-collision regression guard).
- `.changeset` patch bump for `@windyroad/risk-scorer`.

## Tasks

- [ ] Implement the cadence-derivation in `packages/risk-scorer/hooks/risk-score-commit-gate.sh` (STORY-037)
- [ ] Behavioural bats: `packages/risk-scorer/hooks/test/risk-score-commit-gate-cadence-staleness.bats` (STORY-037)
- [ ] Changeset: `@windyroad/risk-scorer` patch (STORY-037)

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook per ADR-060 Phase 1 item 12)

## Related

- ADR-091 — anchor decision (born-confirmed on the 2026-07-04 drain ratification).
- ADR-086 — sibling: appetite threshold derived from the policy.
- P408 — driving problem (`docs/problems/`).
- STORY-037 — the single story (forward-referenced at capture; ADR-089 ≥1-story shape).

