---
status: "proposed"
date: 2026-10-02
human-oversight: unconfirmed
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: []
reassessment-date: 2027-01-02
supersedes: [ADR-074, ADR-066]
---

# Implementation against proposed ADRs

## Context and Problem Statement

The existing ratification-before-build rule prevents testing whether an architectural proposal works before it is locked into an approved record.

## Decision Drivers

- Implementation must be able to test architectural proposals.
- Permission to explore a proposal must remain distinct from final acceptance.

## Considered Options

1. **Allow authorized implementation against a documented proposal (chosen)** — real implementation findings can improve the proposal before approval.
2. **Require final ratification before implementing a proposal (rejected)** — feasibility must be assumed before the implementation can demonstrate it.

## Decision Outcome

Chosen option: **"Allow authorized implementation against a documented proposal"**, following Tom's direction on 2026-10-02. This document remains a proposal; direction to draft or build is not final ratification.

A documented proposed ADR may guide authorized implementation while its substance remains unratified. Missing ADR ratification alone does not block implementation. This replaces ADR-074's build-upon precondition and only ADR-066's contradictory implementation-licence carve-out; their historical substance remains preserved. Implementation against a proposal does not grant final acceptance or waive unrelated delivery governance.

## Consequences

### Good

- real implementation findings can improve the proposal before approval.

### Neutral

- Deployed work can still be governed by a clearly identified proposal.

### Bad

- a failed or rejected experiment can require rework.

## Confirmation

An authorized delivery can implement a documented unratified proposal, while the proposal remains visibly provisional and unrelated governance controls still apply. This permission has not yet been demonstrated by the published rule in real delivery.

## Pros and Cons of the Options

### Allow authorized implementation against a documented proposal

- Good, because real implementation findings can improve the proposal before approval.
- Bad, because a failed or rejected experiment can require rework.

### Require final ratification before implementing a proposal

- Good, because the intended direction is formally agreed early.
- Bad, because feasibility must be assumed before the implementation can demonstrate it.

## Reassessment Criteria

Reassess if proposals are mistaken for permanent approval or implementation silently bypasses unrelated controls.
