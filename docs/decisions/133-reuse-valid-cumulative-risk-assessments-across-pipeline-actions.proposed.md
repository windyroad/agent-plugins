---
status: "proposed"
date: 2026-09-22
human-oversight: confirmed
oversight-date: 2026-09-22
decision-makers: [tomhoward]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: [Windy Road plugin users]
supersedes: [020-governance-auto-release-for-non-afk-flows]
reassessment-date: 2026-12-22
---

# Reuse valid cumulative risk assessments across pipeline actions

## Context and Problem Statement

The pipeline scorer already assesses staged, unpushed, and unreleased changes in one run. It returns separate commit, push, and release scores. A governance skill used while a maintainer is present calls the scorer before committing. The prior auto-release decision (ADR-020) requires another call immediately after the commit, before pushing or releasing. The scorer records a compact signature of the assessed state (a state hash). It stays the same when identical assessed content is committed and pushed. A second call for unchanged work repeats the assessment without adding evidence.

The later actions still need checks at the time they run. The assessed checkout, content, release scope, policy, or score age can change; continuous integration (CI) checks can also change.

## Decision Drivers

- Avoid repeated scoring of the same work.
- Keep the exact push and release scores and an auditable assessment.
- Never push or release above the effective risk appetite: the configured risk limit used by the scorer and gates.
- Preserve action-time checkout, drift, expiry, and CI checks.

## Considered Options

1. **Run the scorer again after every commit (status quo).** Simple to state, but repeats an assessment even when its inputs are unchanged.
2. **Reuse a valid cumulative assessment (proposed).** Use the pre-commit result for later actions while it covers the exact pending work and remains valid; rescore otherwise.
3. **Remove push and release risk gates.** Saves checks, but allows later actions to proceed after the assessment becomes stale or the release scope changes.

## Decision Outcome

**Proposed choice: Option 2, subject to human ratification.** In a governance skill used while a maintainer is present, score the staged change before commit. After commit, reuse that run's `push` and `release` values if the assessment is still bound to the same checkout, covers the exact unpushed and unreleased scope, uses the current effective appetite, and has not expired or drifted. A commit or push of identical assessed content does not by itself require rescoring. If any condition fails or cannot be established, run the pipeline scorer again before pushing or releasing.

The commit score does not stand in for the push or release score. `push:watch` and `release:watch` retain their separate action-time gates, including the relevant score, checkout and state checks, and CI status. Above-appetite remediation and halt behavior remain in force.

This replaces ADR-020's unconditional post-commit scoring step and its source-order confirmation criterion only after this decision is ratified. Its auto-release behavior remains. The unattended (AFK) orchestrator's iteration runs in a separate session and retains its own scoring step; this decision does not alter that cadence.

## Consequences

### Good

- Unchanged work uses one assessment across commit, push, and release.
- Each action still checks current evidence and its own score.

### Neutral

- The action-time gates and unattended release cadence remain in place.

### Bad

- Skills must distinguish a valid reusable assessment from a changed or expired one. An uncertain state requires rescoring.

## Pros and Cons of the Options

### Score again after every commit

- Good: no validity decision is needed in the skill.
- Bad: unchanged work is assessed twice.

### Reuse a valid assessment

- Good: unchanged work is assessed once.
- Bad: the skill must rescore when validity cannot be established.

### Remove push and release gates

- Good: fewer checks run.
- Bad: changed or stale work could pass without an action-time risk or CI check.

## Confirmation

- An attended skill with unchanged assessed scope invokes the scorer once, then commits, pushes, and releases through the existing gates.
- If the checkout, assessed content, release scope, or effective appetite changes, or the score expires, run a new assessment before pushing or releasing.
- A stale or above-appetite release score, or failing CI, still blocks release.
- The AFK orchestrator's scoring and release cadence remain unchanged.

## Reassessment Criteria

Revisit if the scorer stops emitting separate scores for all three actions, the state binding no longer survives an unchanged commit and push, or release scope cannot be verified at action time.

## Related

- ADR-020 — prior non-AFK auto-release decision, superseded on ratification.
- ADR-015 — on-demand pipeline assessment interface.
- ADR-042 — above-appetite remediation and halt behavior.
- ADR-099 — changesets are release metadata, not shipment controls.
