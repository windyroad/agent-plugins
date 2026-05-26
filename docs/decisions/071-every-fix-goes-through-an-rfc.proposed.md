---
status: "proposed"
date: 2026-05-26
human-oversight: confirmed
oversight-date: 2026-05-26
decision-makers: [Tom Howard]
consulted: []
informed: []
reassessment-date: 2026-08-26
amends: [060-problem-rfc-story-framework-with-mandatory-problem-trace-and-unified-problem-ontology]
problems: [P251]
---

# Every fix goes through an RFC

## Context and Problem Statement

ADR-060 I1 gate-enforces the RFC→Problem trace (every RFC traces to ≥1 problem), but the inverse — Problem→RFC at fix-time — is not enforced (P251). A problem can be worked, fixed, and released without ever touching an RFC. Fixes routinely accrete inline `## Root Cause Analysis` → `### Investigation Tasks` → `## Fix Strategy` checklists as work uncovers scope, rather than scoping an RFC first.

A reactive exemption made this worse: the **atomic-fix carve-out** (*Effort ≤ M may skip RFC ceremony; Effort ≥ L requires RFC trace*) reached `RFC-005` **accepted** status (F2/F7/I13), anchored in `JTBD-008` (lines 21/26/44) and `JTBD-101` (line 30), with **no human ratification**. On 2026-05-26 the user disavowed it: *"I did not agree to a atomic-fix carve-out"* and *"Each problem may ONLY be fixed via an RFC."*

This ADR decides that the RFC is the mandatory, unconditional vehicle for every fix. (Its sibling **ADR-070** decides that RFCs hold no independent decisions; the two were ratified together but are independently transitionable.)

## Decision Drivers

- RFC-first trace must be unconditional (P251) — a carve-out is precisely the surface where unratified scope decisions hide (the atomic-fix carve-out being the concrete instance).
- Uniformity + auditability: every fix traceable through one RFC primitive, with no exemption class to drift.
- ADR-060 already provides the thin-RFC landing pad (an atomic fix is "an RFC with empty `stories: []`"), so unconditional RFC-first does not require heavy ceremony for small fixes.

## Considered Options

1. **Every problem is fixed only via an RFC — no carve-out, no effort threshold.**
2. **Keep an effort-threshold carve-out** (Effort ≤ M skips RFC ceremony) — the current RFC-005 F2 shape.
3. **Status quo (do nothing)** — RFC-first remains unenforced; fixes start without RFCs.

## Decision Outcome

Chosen option: **"Every problem is fixed only via an RFC — no carve-out, no effort threshold"**, ratified by the user via clear direction on 2026-05-26 (*"Each problem may ONLY be fixed via an RFC"*).

Concretely:

- **RFC-first is mandatory and unconditional.** Every problem is fixed only via an RFC. There is no atomic-fix carve-out and no effort threshold. This repudiates RFC-005 F2/F7/I13 and its JTBD-008/JTBD-101 anchor.
- **An atomic single-commit fix becomes "an RFC with an empty `stories: []` list"** — the fallback ADR-060 already provides (lines 268/311/316) — not "a fix that skips the RFC." The scale-down *value* for atomic-fix adopters (JTBD-101) is preserved by relocating it to a minimal-ceremony RFC, not deleted.

This ADR records the decision. A separate RFC (tracing P251 + P310) scopes the implementation — the Problem→RFC fix-time gate and the JTBD-008/JTBD-101 amendments.

## Consequences

### Good

- RFC-first trace becomes unconditional — no carve-out for scope decisions to hide behind (composes with ADR-070's decision-homing fix).
- Uniform, auditable fix path: every fix threads Problem → RFC.
- Reuses ADR-060's existing empty-`stories: []` atomic-RFC fallback — no new primitive needed.

### Neutral

- Atomic fixes shift from "no RFC" to "thin RFC with empty `stories: []`" — the adopter scale-down value is relocated, not lost.

### Bad

- A per-fix ceremony floor lands on the speed-optimised solo-developer / atomic-fix-adopter personas (the carve-out previously waived it). Mitigated by the thin-RFC path; the trade (uniformity + auditability over per-fix speed) is user-ratified.
- One-time amendment cost: JTBD-008 (lines 21/26/44) + JTBD-101 (line 30) carve-out struck/reframed.

## Confirmation

- A Problem→RFC fix-time gate enforces RFC-first with no effort carve-out (a problem fix cannot commence/commit without an RFC trace).
- JTBD-008 (lines 21/26/44) + JTBD-101 (line 30) no longer contain the atomic-fix carve-out; both edits route through the ADR-068 oversight-confirm flow (clear-and-reconfirm JTBD-101 which carries a marker; born-confirm JTBD-008 which does not).
- RFC-005's F2/F7/I13 carve-out is removed under the implementation RFC.
- The thin-RFC path (empty `stories: []`) is documented as the atomic-fix shape.

## Pros and Cons of the Options

### Option 1 — Every fix via RFC, no carve-out

- Good: unconditional, uniform, auditable; no exemption class to drift; reuses the thin-RFC fallback.
- Bad: per-fix ceremony floor on speed-optimised personas; one-time JTBD amendment cost.

### Option 2 — Keep the effort-threshold carve-out

- Good: zero ceremony for atomic fixes; lowest friction for the speed personas.
- Bad: the carve-out is itself the unratified-drift surface the user disavowed; an exemption class is where scope decisions hide unaudited.

### Option 3 — Status quo

- Good: lowest churn.
- Bad: RFC-first stays unenforced; fixes keep starting without RFCs (the P251 gap).

## Reassessment Criteria

Revisit if the per-fix ceremony floor proves to materially slow the solo-developer / atomic-fix-adopter personas in measured practice (e.g. the thin-RFC path is not actually thin), or if a class of trivial fixes emerges where even a thin RFC adds no auditability value.

## Related

- **Sibling ADR-070** — RFCs hold no independent decisions (the decision-homing facet; ratified together, split per P017).
- **Amends ADR-060** (Problem-RFC-Story framework) — makes the Problem→RFC trace unconditional at fix-time; ADR-060 stays accepted, amended via the implementation RFC.
- **P251** — RFC-first trace invariant not enforced at fix-time (driving problem).
- **P310** — RFCs carry independent decisions invisible to ADR-066 (sibling driver, ADR-070's problem).
- **RFC-005** — carries the disavowed carve-out (F2/F7/I13); to be retrofitted under the implementation RFC.
- **JTBD-008 / JTBD-101** — anchor the carve-out; to be amended under the implementation RFC (via the ADR-068 re-confirm flow).
- **ADR-068** — JTBD/persona oversight marker; governs the JTBD-008/JTBD-101 amendment re-confirm.
