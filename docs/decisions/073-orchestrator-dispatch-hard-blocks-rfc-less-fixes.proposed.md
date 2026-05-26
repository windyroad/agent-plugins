---
status: "proposed"
date: 2026-05-26
decision-makers: [Tom Howard]
consulted: [wr-architect:agent]
informed: []
reassessment-date: 2026-08-26
problems: [P251]
---

# Orchestrator dispatch hard-blocks RFC-less fixes (no soft-route auto-capture)

## Context and Problem Statement

Under ADR-071 every problem is fixed only via an RFC, and ADR-072 places the fix-time trace gate at `Open → Known Error`. That leaves the **AFK orchestrator dispatch** question: when `/wr-itil:work-problems` Step 5 selects a problem that has no RFC trace, what should it do — refuse to dispatch (hard-block), or auto-scope the RFC inline and proceed (soft-route)?

This decision was first reached as RFC-005 facet **F4** but lived inside an RFC body with no human-oversight marker — the P310 blind spot. ADR-070 requires re-homing it to an ADR. (Its sibling **ADR-072** re-homes the F1 gate-placement decision.)

## Decision Drivers

- RFC scope is **direction-setting** — choosing what an RFC ships is a category-1 decision under ADR-044 that stays with the user; the framework must not invent it.
- ADR-051 (load-bearing-from-the-start) — the dispatch refusal must be a real block, not advisory-disguised-as-action.
- JTBD-006 (AFK orchestrator throughput) — a refusal must not terminate the loop; it must compose with the existing "skip non-actionable tickets, advance to next-highest WSJF candidate" shape.

## Considered Options

1. **Hard-block** — the iter does not dispatch on an RFC-less problem at/above the fix-time gate; the orchestrator skips it and advances to the next-highest-WSJF candidate (the existing skip-non-actionable shape), surfacing a recovery prompt naming `/wr-itil:capture-rfc P<NNN>`. The loop does NOT terminate.
2. **Soft-route** — the orchestrator auto-invokes `/wr-itil:capture-rfc` inline, scopes the RFC itself, and proceeds with the fix.

## Decision Outcome

Chosen option: **"Hard-block"**, because RFC scope is direction-setting (ADR-044 category 1) and the orchestrator must not author it unattended. Soft-route would be advisory-disguised-as-action — the orchestrator inventing scope the user is supposed to set.

Concretely:

- `/wr-itil:work-problems` Step 5 dispatch refuses to invoke a fix iter on any `Open`/`Known Error` problem that lacks an RFC trace (no effort carve-out — ADR-071 makes this unconditional; the F2 carve-out RFC-005 attached here is repudiated).
- The refusal is a **hard-block on that ticket**: the iter does not dispatch, the loop does NOT terminate; the orchestrator advances to the next-highest-WSJF actionable candidate per the established skip-non-actionable-tickets shape.
- The deny surfaces a recovery prompt naming `/wr-itil:capture-rfc P<NNN> <description>` as the next action, and logs a structured dispatch-denial entry for the reassessment criterion.

This ADR records the enforcement stance. The `/wr-itil:work-problems` Step 5 implementation + the structured dispatch-denial log ship as RFC-006 decomposition tasks.

## Consequences

### Good

- RFC scope stays with the user (ADR-044 category 1); the orchestrator never invents direction-setting content unattended.
- The refusal is load-bearing (ADR-051), not advisory.
- Composes with JTBD-006 — the loop keeps making progress on other actionable tickets rather than halting.

### Neutral

- An RFC-less high-WSJF problem is skipped until its RFC exists; it re-enters dispatch the moment the user (or a foreground turn) captures the RFC.

### Bad

- A high-priority RFC-less problem can sit un-progressed across an entire AFK loop if no RFC is captured for it. Mitigated by the recovery-routing prompt + the structured denial log surfacing the pattern at retro. (Reassessment criterion below tracks whether repeated same-ticket denials warrant softening.)

## Confirmation

- `/wr-itil:work-problems` Step 5 refuses dispatch on an RFC-less `Open`/`Known Error` problem and admits an RFC-traced one; the loop advances rather than terminates.
- The deny emits a recovery prompt naming `/wr-itil:capture-rfc P<NNN>` and a structured dispatch-denial log entry.
- A behavioural test asserts: RFC-less problem → dispatch refused + loop continues; RFC-traced problem → dispatch admitted.

## Pros and Cons of the Options

### Option 1 — Hard-block (chosen)

- Good: keeps direction-setting RFC scope with the user (ADR-044 cat 1); load-bearing (ADR-051); composes with JTBD-006 skip-and-continue.
- Bad: a high-priority RFC-less problem stays un-progressed until an RFC exists.

### Option 2 — Soft-route (auto-invoke capture-rfc inline)

- Good: zero stall; the orchestrator keeps fixing.
- Bad: violates ADR-044 category 1 — RFC scope IS direction-setting; the orchestrator would invent scope unattended. Advisory-disguised-as-action; not load-bearing.

## Reassessment Criteria

Revisit if the structured dispatch-denial log shows the orchestrator repeatedly halting on the same RFC-less problem AND the user repeatedly captures that RFC inline immediately after — that pattern would indicate the hard-block stance should soften toward an assisted-capture flow for a recurring sub-class.

## Related

- **ADR-071** — Every fix goes through an RFC (the unconditional parent; removes the F2 effort carve-out this dispatch refusal previously gated on).
- **ADR-072** — Fix-time RFC-trace gate fires at `Open → Known Error` (sibling; the placement this dispatch stance enforces at the orchestrator surface).
- **ADR-070** — RFCs hold no independent decisions (the reason this F4 decision is re-homed from RFC-005 to an ADR).
- **ADR-044** — decision-delegation contract; RFC scope is category-1 direction-setting that stays with the user.
- **ADR-051** — load-bearing-from-the-start; the dispatch refusal is a real block, not advisory.
- **ADR-060** — Problem-RFC-Story framework; the I1 hard-block precedent this mirrors at the symmetric dispatch surface.
- **JTBD-006** — Progress the Backlog While I'm Away; the skip-and-continue shape this composes with.
- **P251** — RFC-first trace invariant not enforced at fix-time (driving problem).
- **RFC-005** — carried this decision as facet F4 with no human ratification (the P310 instance).
- **RFC-006** — implementation RFC that re-homes this decision and ships the Step 5 enforcement.
