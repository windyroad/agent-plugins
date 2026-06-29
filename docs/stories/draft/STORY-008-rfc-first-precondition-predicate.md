---
status: draft
story-id: rfc-first-precondition-predicate
reported: 2026-06-29
decision-makers: [Tom Howard]
problems: [P251, P314]
jtbd: [JTBD-008]
rfcs: [RFC-005]
estimated-effort: S
---

# STORY-008: The propose-fix predicate refuses (routes to authoring), it does not auto-create

**Status**: draft
**Reported**: 2026-06-29
**Problems**: P251, P314
**JTBD**: JTBD-008
**RFCs**: RFC-005
**Estimated effort**: S

## User value (INVEST Valuable)

As a maintainer (or the AFK orchestrator) proposing a fix on a Known Error, I want the `check-fix-rfc-trace.sh` predicate to signal **refuse / route-to-RFC-authoring** when no RFC traces the problem — instead of emitting a `no-rfc-trace: … auto-create` directive — so that I cannot silently build a hollow fix and so the RFC-first invariant is enforced at the detection layer.

## Acceptance criteria (INVEST Testable)

- [ ] When no RFC's `problems:` array claims the problem's PID, the predicate signals **refuse/route-to-authoring** (no `auto-create` directive on stdout).
- [ ] When an RFC already traces the problem, the predicate signals **proceed** (empty stdout) — this branch is unchanged.
- [ ] The predicate carries **no effort branch** (unconditional gate; S/M/L/XL traverse the same path) and **no `type:` branch** (ADR-060 I2 uniformity).
- [ ] Exit-code contract documented (the refuse/route signal vs proceed vs error) and asserted.
- [ ] `check-fix-rfc-trace.bats` rewritten from auto-create-directive assertions to refuse/route assertions; green.

## Driving problem trace (I6)

**P251** — RFC-first trace invariant not enforced at fix-time. **P314** — the gate-design rework. The shipped predicate emits an auto-create directive and exits 0 (the mechanism ADR-073 repudiated 2026-06-29); this story reworks the **detection** half to the RFC-first precondition signal. Supersedes RFC-005 B3 (rework slice B12).

## JTBD trace (I9)

**JTBD-008** — Decompose a Fix Into Coordinated Changes. The predicate is the load-bearing detection that makes "no fix without a pre-existing RFC" enforceable rather than advisory.

## Dependencies

- **Blocks**: STORY-009, STORY-010 (the manage-problem + work-problems gates consume this predicate's signal), STORY-012 (predicate bats).
- **Blocked by**: (none — the ADRs it enforces, ADR-071/072/073, are ratified).

## Related

- RFC-005 B12 (the rework slice this story ships); supersedes B3.
- ADR-073 (RFC-first), ADR-072 (gate placement), ADR-051 (load-bearing-from-the-start).
