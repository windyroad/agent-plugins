---
status: "proposed"
date: 2026-09-11
oversight-date: 2026-09-11
human-oversight: confirmed
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent, wr-risk-scorer:wip]
informed: [Windy Road plugin users, Windy Road plugin developers]
reassessment-date: 2026-12-11
supersedes: ["ADR-014 (in part - problem-creation preflight routing only)"]
---

# Problem reports precede derived index repair

## Context and Problem Statement

The problem-creation skills run the strict problem-index reconciler before they classify or preserve a new report. When an adopter repository has no `docs/problems/README.md`, or its generated index tables are stale, that preflight halts the operation and the report is never captured. The index is derived navigation state. Its absence or ordinary drift must not make the source problem report unavailable.

The existing reconciliation primitive also detects malformed indexes that may contain human-authored narrative. That case still needs to fail closed because blindly regenerating the whole file could destroy user content.

## Decision Drivers

- Preserve every actionable problem report before repairing derived navigation state.
- Keep the ticket and its derived index consistent at the commit boundary.
- Preserve human-authored README narrative and fail closed when it cannot be parsed safely.
- Keep strict reconciliation for backlog selection, updates, transitions, and all non-creation callers.
- Avoid a second reconciliation implementation or a new bypass token.

## Considered Options

1. **Report-first problem creation** - on a missing index or parseable drift, create the ticket and repair the derived index in the same commit; retain the halt for an existing malformed index.
2. **Keep the current preflight halt** - require the index to be repaired or recreated before any new problem ticket can be created.

## Decision Outcome

Chosen option: **"Report-first problem creation"**, because a derived index must not discard the report it exists to surface. The same-commit repair preserves the repository's consistency boundary without weakening strict reconciliation outside new-problem creation.

The creation-only routing is:

- Clean index: continue normally.
- Parseable drift: retain the diagnostic, create the ticket, repair only the generated index sections while preserving narrative, and stage both in one commit.
- Missing index: create the ticket, generate the canonical index from ticket truth, and stage both in one commit.
- Existing malformed index: halt with the existing parse error so user content is not overwritten.

For `manage-problem`, the preflight result is retained until the requested operation is classified. Only the new-problem branch may use the report-first routing. Existing-problem updates and transitions retain the current halt. The reconciler, backlog worker, and all other callers remain unchanged.

## Consequences

### Good

- A missing or stale derived index can no longer cause a problem report to be lost.
- Capture commits remain internally consistent because the ticket and repaired index land together.
- Malformed human-authored content remains protected from destructive regeneration.
- Strict reconciliation semantics remain unchanged for every non-creation operation.

### Neutral

- Problem creation now classifies the reconciliation outcome before deciding whether it is blocking.
- A capture over stale index state repairs generated sections as part of the capture transaction instead of in a preceding dedicated reconciliation commit.

### Bad

- A problem-creation commit can include unrelated pre-existing table drift, making that repair less independently attributable than the prior dedicated commit.
- Both problem-creation skill surfaces must keep the same creation-only routing contract.

## Confirmation

- Focused behavioral skill evaluations show both `capture-problem` and the new-problem branch of `manage-problem` continue when `docs/problems/README.md` is absent, create the ticket, generate the canonical index, and stage both in one commit.
- A focused evaluation shows parseable index drift is repaired without changing narrative outside generated sections.
- A focused evaluation shows an existing malformed index still halts before any overwrite.
- Existing reconciliation tests confirm strict exit codes and all non-creation callers remain unchanged.
- The packed plugin is installed into a temporary adopter repository with no problem index, and an exact problem-creation journey produces both the ticket and canonical index.

## Pros and Cons of the Options

### Report-first problem creation

- Good: preserves the report and restores derived state within the existing single-commit consistency boundary.
- Bad: creation must distinguish missing, stale, and malformed index outcomes instead of treating every nonzero preflight result alike.

### Keep the current preflight halt

- Good: retains a simple universal preflight rule and a separately attributable repair commit.
- Bad: a missing derived file can prevent the source problem report from ever being recorded.

## Reassessment Criteria

Reassess if the problem index becomes entirely machine-generated with no human-authored content, if problem creation no longer owns same-commit index refresh, or if adopter evidence shows report-first repair can misclassify malformed content as safe drift.

## Related

- P538 - problem creation is gated on the problem index existing.
- ADR-014 - governance skills commit their own completed work; superseded only for problem-creation preflight routing.
- ADR-032 - foreground lightweight problem capture and same-commit index refresh.
