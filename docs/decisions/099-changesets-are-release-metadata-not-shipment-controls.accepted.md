---
status: "accepted"
date: 2026-07-23
human-oversight: confirmed
oversight-date: 2026-07-23
decision-makers: [Tom Howard]
consulted: [wr-architect:agent]
informed: [Windy Road plugin users]
problems: [P359]
supersedes: [ADR-061, ADR-082]
---

# Changesets are release metadata, not shipment controls

## Context and Problem Statement

Moving a changeset out of `.changeset/` does not withhold its code. Any sibling
release publishes the committed package contents, so a "held changeset" delays
only version attribution and the changelog entry. That creates ceremony and
confusion without reducing shipment risk.

## Decision Drivers

- Never describe metadata movement as risk remediation.
- Keep frequent, small releases as the default risk-control mechanism.
- Preserve the invariant that commit, push, and release risk must be within
  appetite.
- Prefer controls that change shipped code or its blast radius.

## Considered Options

1. Keep holding as attribution-only metadata. Rejected because it provides no
   risk-management value.
2. Build a generic packaging-time feature-toggle system. Rejected as
   disproportionate infrastructure for a workflow that should instead keep
   changes small and releasable.
3. Remove holding and require shipment-affecting remediation. Chosen.

## Decision Outcome

`.changeset/` is the only changeset queue. Changesets describe release metadata;
they never control whether committed code ships.

When work is above appetite, the agent must reduce the actual risk by splitting
the change, adding evidence or controls, narrowing blast radius, disabling or
reverting the risky behaviour, or halting. Moving release notes is not a
remediation.

ADR-061 and ADR-082 are superseded. RFC-025 is retired without implementation.
ADR-042 retains its open remediation vocabulary, never-above-appetite invariant,
and halt-on-exhaustion rule, but its holding-area rules are removed.

## Consequences

### Good

- Release metadata and shipment controls have distinct, truthful meanings.
- The workflow encourages small commits, pushes, and releases instead of
  accumulating work behind a non-functional hold.
- Above-appetite remediation must affect code, evidence, controls, or scope.

### Bad

- Work that cannot be made safe enough must be disabled, reverted, or halted;
  it cannot remain merged while pretending not to ship.
- Historical tickets and RFCs still mention holding as part of the audit trail.

## Confirmation

- No runtime skill, hook, scorer agent, or release helper treats
  `docs/changesets-holding/` as an active queue.
- The holding directory and graduation evaluator are absent.
- Codex-generated agent surfaces match the runtime-neutral source.
- ITIL and risk-scorer tests pass.

## Related

- P359 — holding changesets does not withhold shipment.
- ADR-042 — above-appetite remediation and halt discipline.
- ADR-061 — superseded graduation criteria.
- ADR-082 — superseded real-shipment-control direction.
- RFC-025 — retired build-time-toggle proposal.
