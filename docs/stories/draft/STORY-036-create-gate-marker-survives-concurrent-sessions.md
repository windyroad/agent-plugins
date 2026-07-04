---
status: draft
story-id: create-gate-marker-survives-concurrent-sessions
reported: 2026-07-04
decision-makers: [Tom Howard]
problems: [P260]
jtbd: [JTBD-006]
rfcs: [RFC-007]
estimated-effort: M
---

# STORY-036: Write the create-gate marker under every candidate session id

**Status**: draft
**Reported**: 2026-07-04
**Problems**: P260
**JTBD**: JTBD-006
**RFCs**: RFC-007
**Estimated effort**: M

## User value (INVEST Valuable)

In order to stop AFK ticket writes being denied when the orchestrator and its subprocess run concurrently, as a developer running the AFK work-problems loop, I want the create-gate marker written under every recent candidate session id so the PreToolUse hook always finds a match — so concurrent sessions don't collide on the shared runtime-sid marker.

## Acceptance criteria (INVEST Testable)

- [x] The create-gate marker is written under every recent candidate session id (ADR-050 Option C) — the `get_current_session_id` pick plus every recent announce-marker UUID within the mtime window.
- [x] Concurrent orchestrator + subprocess writes no longer produce a create-gate deny on the first ticket of a session.
- [x] Behavioural bats cover the concurrent-write / marker-mismatch case.

## Driving problem trace (I6)

**P260** — under `/wr-itil:work-problems` the orchestrator main turn and its backgrounded subprocess write the same per-machine runtime-sid marker (last-writer-wins), so the single-SID pick can mismatch the Write's stdin SID and the create-gate denies. Option C marks under every candidate SID so a matching marker provably exists.

## JTBD trace (I9)

**JTBD-006** (Progress the Backlog While I'm Away) — the race fires precisely during the AFK loop; the fix keeps the loop from stalling on a spurious create-gate deny.

## Backfill note (ADR-089)

Umbrella backfill story for the pre-ADR-089 RFC-007 (`verifying` — retro-fit RFC over an already-shipped fix). Stays `draft` (born `human-oversight: unconfirmed`) until an interactive session ratifies it and decides whether to give it a story-map trace (I8) to reach `accepted`. The RFC-side `stories:` wiring is deferred to that interactive drain per ADR-090 (ratify-then-wire order).

## Dependencies

- **Blocks**: (none — backfill)
- **Blocked by**: (none)

## Related

- RFC-007 (parent RFC), ADR-050 (runtime-SID marker; Option C), ADR-052 (behavioural tests). P260 (driving problem).
