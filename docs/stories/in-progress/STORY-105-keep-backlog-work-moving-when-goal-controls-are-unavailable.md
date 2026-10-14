---
status: in-progress
story-id: keep-backlog-work-moving-when-goal-controls-are-unavailable
reported: 2026-10-14
decision-makers: [Tom Howard]
problems: [P556]
jtbd: [JTBD-006]
rfcs: [RFC-076]
story-maps: [STORY-MAP-011]
estimated-effort: S
---

# STORY-105: Keep backlog work moving when Goal controls are unavailable

**Reported**: 2026-10-14
**Problems**: P556
**JTBD**: JTBD-006
**RFCs**: RFC-076
**Story Maps**: STORY-MAP-011
**Estimated effort**: S

## User value (required, INVEST Valuable)

In order to make progress while I am away, as a developer starting an unattended
Codex backlog drain, I want work to continue when this session lacks Goal
controls and to be told accurately whether the external anchor is active.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [x] The built Codex skill checks current-session callable capability and keeps
  the existing get/set/clear lifecycle when available.
- [x] Missing get or set capability produces one honest unanchored notice and
  continues with unconditional Gate (0) checks, without a consent or restart
  gate, false Hard-fail halt, or unrelated-thread anchor.
- [x] Missing clear capability preserves terminal evidence and discloses that
  the Goal remains uncleared.
- [x] Generated-skill positive/negative model cases pass for
  complete, missing, partial, stop-only, and other-thread capabilities.
- [ ] The published package retains all repository testing, risk, commit,
  push, release, and zero-dispatchable completion requirements.

## Driving problem trace (required — I7 invariant)

- P556 — the Codex overlay turns unavailable Goal controls into a prerequisite
  and stops before dispatch, contrary to the approved fallback.

## JTBD trace (accepted-gate — I8 invariant)

Serves JTBD-006, **Progress the Backlog While I'm Away**. Capability limitations
must not strand otherwise dispatchable work or create misleading completion
claims.

## Implementation notes (optional)

- Reuse ADR-094's existing never-halt rule under RFC-076; no new architecture
  decision, persona, job, or map activity is introduced.
- Keep the correction in the Codex overlay and its existing generator/model
  checks. Do not change the canonical Claude Code branch or runtime settings.
- Keep callable-control errors distinct from absent capabilities.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- STORY-070 supplies the existing positive persisted-Goal contract; this card
  adds the requirements-floor case on the same release row.
- Architecture preflight PASS: ADR-083, ADR-094 Rule 6, ADR-103, ADR-104, ADR-128.
