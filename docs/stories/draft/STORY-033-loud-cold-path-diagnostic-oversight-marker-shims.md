---
status: draft
story-id: loud-cold-path-diagnostic-oversight-marker-shims
reported: 2026-07-03
decision-makers: [Tom Howard]
problems: [P368]
jtbd: [JTBD-001]
rfcs: [RFC-038]
estimated-effort: S
---

# STORY-033: Loud cold-path diagnostic for oversight-marker shims

**Reported**: 2026-07-03
**Problems**: P368
**JTBD**: JTBD-001
**RFCs**: RFC-038
**Estimated effort**: S

## User value (INVEST Valuable)

In order to understand why an oversight-marker Edit is being denied instead of hitting a silent dead-end, as a plugin developer confirming an ADR/JTBD substance mid-session, I want the `mark-oversight-confirmed` shims to say out loud when they could not discover a session-id and wrote no marker — so the subsequent discipline-hook deny is self-explanatory rather than a confusing loop that points back at a shim I already ran.

## Acceptance criteria (INVEST Testable)

- [x] On the no-candidate cold path (no `CLAUDE_SESSION_ID` and no `*-announced-*` markers), `packages/architect/scripts/mark-oversight-confirmed.sh` prints a stderr diagnostic naming: no candidate session-id, no marker written, and the remedy — and still exits 0.
- [x] Identical diagnostic + exit-0 behaviour in the unsynced sibling `packages/jtbd/scripts/mark-oversight-confirmed.sh`.
- [x] Behavioural bats cold-path test in `architect-oversight-marker-discipline.bats` (RED before, GREEN after): exit 0, no marker file written, stderr contains the diagnostic + "P368".
- [x] Mirror behavioural bats cold-path test in `jtbd-oversight-marker-discipline.bats`.
- [x] Both discipline suites green, no regressions (14/14 architect, 12/12 jtbd).
- [x] Exit code stays 0 on the cold path (documented "do not crash SKILL flows" contract preserved).

## Driving problem trace (I6)

**P368** (Known Error) — the shims exit 0 silently on the genuine cold path, then the oversight-marker-discipline hook denies the `human-oversight: confirmed` Edit, pointing the caller back at the shim it already ran (P368 Description line 21: "creating a confusing loop"). This story implements P368 option (b), the residuum P380 deferred here after fixing the macOS symlink half.

## JTBD trace (I9)

**JTBD-001** (Enforce Governance Without Slowing Down) — the silent cold path is exactly the flow-breaking failure JTBD-001's "so they don't break flow" outcome exists to prevent; a loud diagnostic removes the confusing loop while keeping the marker discipline intact.

## Implementation notes

Two unsynced per-package shim edits (ADR-002 self-containment — no shared canonical, edited independently per P380) plus two behavioural bats. Exit 0 preserved; only the silence is removed. Ships to adopters after the next marketplace release + `/install-updates` + session restart.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none — P380 already landed the `find -L` half this builds beside)

## Related

- RFC-038 (parent RFC).
- P368 (driving Known Error), P380 (sibling; symlink half).
- ADR-066 / ADR-068 (marker mechanism), ADR-050 (candidate enumeration), ADR-052 (behavioural tests).
