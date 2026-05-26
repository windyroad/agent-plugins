---
status: "proposed"
date: 2026-05-26
decision-makers: [Tom Howard]
consulted: [wr-architect:agent]
informed: []
reassessment-date: 2026-08-26
problems: [P251]
---

# Fix-time RFC-trace gate fires at the `Open → Known Error` transition

## Context and Problem Statement

ADR-071 makes the Problem→RFC trace mandatory and unconditional at fix-time: every problem is fixed only via an RFC. That decision leaves one question open — **where in the problem lifecycle does the gate fire?** This decision answers it.

This decision was first reached as RFC-005 facet **F1** but lived inside an RFC body with no human-oversight marker — exactly the P310 blind spot ADR-070 exists to close. ADR-070 ("RFCs hold no independent decisions") requires every choice among ≥2 viable options to be re-homed to an ADR; this ADR re-homes the F1 placement decision. (Its sibling **ADR-073** re-homes the F4 orchestrator-dispatch enforcement decision.)

## Decision Drivers

- The gate must fire at the moment fix scope becomes real — early enough to prevent the inline-checklist body-drift the invariant is designed to prevent (P251), not after it.
- Reuse the existing problem lifecycle ontology (ADR-060 I2 — uniform ontology, no per-surface re-hosting); avoid inflating the lifecycle with a new state that adds no semantic information.
- Compose with ADR-060 I1's "hard-block at the earliest meaningful surface" precedent.

## Considered Options

1. **Gate at `Open → Known Error`** (single gate; no new lifecycle state).
2. **Gate at `Known Error → Fix Released`.**
3. **Introduce a new `Open → In Progress` lifecycle state and gate there.**

## Decision Outcome

Chosen option: **"Gate at `Open → Known Error`"**, because `Known Error` is the existing ITIL semantic for "root cause identified, fix strategy known, work is now real" — exactly the moment the fix's RFC scope must exist. The gate fires at the `Open → Known Error` transition in `/wr-itil:manage-problem` Step 7. No new lifecycle state is introduced.

Concretely:

- The fix-time Problem→RFC trace check fires at `Open → Known Error` in `/wr-itil:manage-problem` Step 7, and at `git commit` for the staged ticket-state transition (the structural hook surface — sibling to ADR-060 I1's hard-block at `capture-rfc`).
- No new lifecycle state. The check is a gate on an existing transition, not a new ontology node.
- This placement is unconditional per ADR-071 — there is no effort carve-out (the carve-out that RFC-005 F2 attached to this gate is repudiated by ADR-071).

This ADR records the placement decision. ADR-060's I13 invariant (added under RFC-006) cites this ADR for the placement; the structural hook + `/wr-itil:manage-problem` Step 7 enforcement ship as RFC-006 decomposition tasks.

## Consequences

### Good

- The gate fires before the inline `## Root Cause Analysis → ## Fix Strategy` body-drift the invariant prevents — `Known Error` is precisely "work is now real".
- No new lifecycle state; the existing problem ontology (ADR-060 I2) is preserved.
- Composes with ADR-060 I1's hard-block-at-earliest-meaningful-surface precedent and the `git commit` staged-transition hook surface.

### Neutral

- `Open → Known Error` becomes the first gate at that transition; the gate-surface taxonomy extends to `manage-problem <NNN> --to known-error` as a sibling of `capture-rfc` (I1) and `capture-problem` Step 1.5 (I12).

### Bad

- A problem cannot reach `Known Error` until its RFC exists — a small up-front ceremony cost, accepted under ADR-071 (mitigated by the thin-RFC `stories: []` path).

## Confirmation

- `/wr-itil:manage-problem` Step 7 enforces the trace check at `Open → Known Error`; a structural hook hard-blocks the `git commit` that lands the staged `docs/problems/open/ → docs/problems/known-error/` transition without an RFC trace.
- ADR-060's I13 invariant text names `Open → Known Error` as the gate placement and cites this ADR.
- A behavioural test asserts the gate fires at `Open → Known Error` and not elsewhere.

## Pros and Cons of the Options

### Option 1 — Gate at `Open → Known Error` (chosen)

- Good: fires when fix scope becomes real; reuses existing ontology; composes with I1 precedent.
- Bad: small up-front ceremony before a problem can reach `Known Error`.

### Option 2 — Gate at `Known Error → Fix Released`

- Good: lets investigation proceed before the gate.
- Bad: gates *after* the body-drift the invariant is designed to prevent has already happened — the inline-checklist accretion occurs between `Known Error` and `Fix Released`.

### Option 3 — New `Open → In Progress` lifecycle state

- Good: an explicit "work started" marker.
- Bad: inflates the lifecycle ontology without adding semantic information beyond what `Known Error` already carries (ADR-060 I2 friction).

## Reassessment Criteria

Revisit if field evidence shows `Known Error` is reached for reasons other than "fix is now real" frequently enough that the gate fires too early (e.g. `Known Error` used as a triage-parking state), or if a later lifecycle surface proves to be the better gate point.

## Related

- **ADR-071** — Every fix goes through an RFC (the unconditional-RFC-first parent decision this placement serves).
- **Sibling ADR-073** — Orchestrator dispatch hard-blocks RFC-less fixes (the F4 enforcement facet; extracted from RFC-005 alongside this one).
- **ADR-070** — RFCs hold no independent decisions (the reason this F1 decision is re-homed from RFC-005 to an ADR).
- **ADR-060** — Problem-RFC-Story framework; its I13 invariant (added under RFC-006) cites this ADR for the gate placement.
- **ADR-044** — decision-delegation contract; the gate is a framework-mediated hard-block, not a prompt-ask.
- **ADR-051** — load-bearing-from-the-start; the placement ships with a structural hook, not advisory prose.
- **P251** — RFC-first trace invariant not enforced at fix-time (driving problem).
- **RFC-005** — carried this decision as facet F1 with no human ratification (the P310 instance).
- **RFC-006** — implementation RFC that re-homes this decision and ships the I13 invariant + enforcement.
