---
status: draft
story-id: rfc-decisions-homed-in-adrs-rfc-first-unconditional
reported: 2026-07-04
decision-makers: [Tom Howard]
problems: [P310, P251]
jtbd: [JTBD-008]
rfcs: [RFC-006]
estimated-effort: L
---

# STORY-035: Home RFC decisions in ADRs and make the RFC-first trace unconditional

**Reported**: 2026-07-04
**Problems**: P310, P251
**JTBD**: JTBD-008
**RFCs**: RFC-006
**Estimated effort**: L

## User value (INVEST Valuable)

In order to keep every fix traceable through an RFC without decisions drifting between RFCs and ADRs, as a developer, I want RFC decisions homed in ADRs and the RFC-first trace made unconditional — so the trace invariant holds without per-fix carve-outs.

## Acceptance criteria (INVEST Testable)

- [x] RFC decisions are re-homed to ADRs (ADR-070); RFCs hold no independent decisions.
- [x] The RFC-first trace is unconditional (ADR-071); the JTBD-008 and JTBD-101 atomic-fix carve-outs are struck.
- [x] The fix-time RFC-trace gate and auto-create are wired (ADR-072/073, as corrected per P314 — gate at the propose-fix step on a Known Error, missing RFC auto-created everywhere).
- [x] Behavioural bats cover the gate per ADR-052.

## Driving problem trace (I6)

**P310** — decisions duplicated across RFCs and ADRs drift out of sync; homing them in ADRs removes the double-source. **P251** — the RFC-first trace carried carve-outs that let fixes bypass the invariant; ADR-071 makes it unconditional.

## JTBD trace (I9)

**JTBD-008** (Decompose a Fix Into Coordinated Changes) — an unconditional RFC-first trace with decisions homed in ADRs is what keeps a multi-change fix coordinated and auditable.

## Backfill note (ADR-089)

Umbrella backfill story for the pre-ADR-089 RFC-006 (`verifying` — already shipped). Stays `draft` (born `human-oversight: unconfirmed`) until an interactive session ratifies it and decides whether to give it a story-map trace (I8) to reach `accepted`. The RFC-side `stories:` wiring is deferred to that interactive drain per ADR-090 (ratify-then-wire order). The acceptance criteria record RFC-006's as-shipped deliverable; the ADR-072/073 gate-placement correction landed post-ship via P314.

## Dependencies

- **Blocks**: (none — backfill)
- **Blocked by**: (none)

## Related

- RFC-006 (parent RFC), ADR-070/071/072/073 (homed decisions), ADR-060 (parent framework), ADR-052 (behavioural tests). P310 / P251 (driving problems), P314 (post-ship gate correction).
