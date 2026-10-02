---
status: "proposed"
date: 2026-10-02
human-oversight: unconfirmed
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: []
reassessment-date: 2027-01-02
---

# ADR acceptance after production use and human ratification

## Context and Problem Statement

Ratification before real use can approve an architecture that cannot actually work. The current acceptance guidance requires human ratification but does not require demonstrated production use.

## Decision Drivers

- Approval must reflect demonstrated feasibility.
- A human must evaluate the final decision substance and observed consequences.

## Considered Options

1. **Acceptance after both human ratification and successful production use (chosen)** — final approval is informed by demonstrated behavior and human judgment.
2. **Acceptance after human ratification alone (rejected)** — approval can precede demonstrated feasibility.

## Decision Outcome

Chosen option: **"Acceptance after both human ratification and successful production use"**, following Tom's direction on 2026-10-02. This document remains a proposal; direction to draft or build is not final ratification.

An ADR reaches accepted only after both explicit human ratification of its final substance and evidence of successful actual production use satisfying its decision-level Confirmation criteria. Neither condition substitutes for the other. Local tests, CI, publication, previews, staging, and synthetic evaluations alone do not establish actual production use.

## Consequences

### Good

- final approval is informed by demonstrated behavior and human judgment.

### Neutral

- An ADR can remain proposed while evidence or ratification is pending.

### Bad

- final acceptance waits for real use and subsequent review.

## Confirmation

The acceptance flow leaves a decision proposed when either human ratification or successful actual production-use evidence is absent, and accepts it only when both are present. This proposed lifecycle rule has not yet been proven through real production use.

## Pros and Cons of the Options

### Acceptance after both human ratification and successful production use

- Good, because final approval is informed by demonstrated behavior and human judgment.
- Bad, because final acceptance waits for real use and subsequent review.

### Acceptance after human ratification alone

- Good, because the approval can be recorded earlier.
- Bad, because approval can precede demonstrated feasibility.

## Reassessment Criteria

Reassess if acceptance routinely substitutes synthetic evidence for real use or claims ratification of substance that was never presented.
