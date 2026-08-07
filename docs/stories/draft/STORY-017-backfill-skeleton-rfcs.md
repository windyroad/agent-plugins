---
status: draft
story-id: backfill-skeleton-rfcs
reported: 2026-06-29
decision-makers: [Tom Howard]
problems: [P399, P375]
jtbd: [JTBD-008]
rfcs: [RFC-005]
story-maps: [STORY-MAP-002]
estimated-effort: M
---

# STORY-017: Backfill-or-supersede the skeleton RFCs the repudiated mechanism left behind

**Reported**: 2026-06-29
**Problems**: P399, P375
**JTBD**: JTBD-008
**RFCs**: RFC-005
**Estimated effort**: M

## User value (INVEST Valuable)

In order that the RFC corpus stops carrying placeholders that defeat the very trace they were meant to satisfy, as a maintainer, I want each skeleton RFC auto-created under the repudiated fix-time mechanism either **authored into a real story map** or **superseded** where its fix has already shipped.

## Acceptance criteria (INVEST Testable)

- [ ] Each skeleton RFC (RFC-026/028/029/030/032/033/034 + any flagged by `check-autocreate-rfc-scope.sh`) is either authored as a real story map or superseded with a recorded reason.
- [ ] The repurposed B9 scope detector reports **zero** under-scoped skeletons after the backfill (the backfill-progress signal reaches clean).
- [ ] No new skeleton is created in the process (the authoring uses the STORY-015 pre-implementation story-map path).

## Driving problem trace (I6)

**P399** — the under-scoped skeleton population. **P375** — the "flesh-out-later step never self-fires" cadence-rot that made the skeletons permanent. This story clears the debt the auto-create mechanism accrued. Supersedes RFC-005 B11's backfill sub-edit (rework slice B17).

## JTBD trace (I9)

**JTBD-008** — Decompose a Fix Into Coordinated Changes; a hollow skeleton satisfies the trace structurally while being empty — backfilling restores the trace's value.

## Dependencies

- **Blocks**: (none — this is the debt-clearing tail).
- **Blocked by**: STORY-015 (reuses the pre-implementation story-map authoring path).

## Related

- RFC-005 B17; supersedes B11 backfill sub-edit. ADR-060 (RFC = story map), P399, P375, the `check-autocreate-rfc-scope.sh` detector (RFC-005 B9, repurposed).
