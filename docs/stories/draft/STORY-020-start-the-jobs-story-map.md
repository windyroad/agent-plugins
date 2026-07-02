---
status: draft
story-id: start-the-jobs-story-map
reported: 2026-07-02
decision-makers: [Tom Howard]
problems: [P170]
jtbd: [JTBD-008]
rfcs: [RFC-005]
story-maps: [STORY-MAP-002]
estimated-effort: M
human-oversight: confirmed
oversight-confirmed-date: "2026-07-02 — ratified via AskUserQuestion (per-story pass; reworked to the map's whole-picture value before ratifying)"
---

# STORY-020: Start the job's story map

**Story map:** [← STORY-MAP-002: Decompose a Fix Into Coordinated Changes](../../story-maps/draft/STORY-MAP-002-decompose-a-fix-into-coordinated-changes.html) · A3 (Release 1)
**Siblings (A3):** [add to map](021-add-the-fixs-stories-to-the-map.md) · [ratify](022-ratify-the-story-map-and-its-stories.md) · [create RFC](015-rfc-authoring-is-pre-implementation-story-map.md) · [reuse](024-reuse-stories-already-on-the-map.md) · [slice](025-slice-the-fixs-stories-into-releases.md)

## User value (INVEST Valuable)

In order to see and reason about a coordinated fix as one coherent picture — its whole shape at a glance, what's MVP versus later, where the gaps are — instead of a scattered pile of changes buried in a ticket, as a developer taking on the first coordinated fix for a job that has no map yet, I want a story map **started for it**.

## Acceptance criteria (INVEST Testable)

- [ ] When a fix is being decomposed for a JTBD that has no `STORY-MAP-NNN` yet, a new story map is created (correct filename grammar, `draft` lifecycle, meta block wired to the JTBD).
- [ ] The new map's `jtbd:` trace points at the driving job; its `problems:`/`rfcs:` are populated as the fix firms up.
- [ ] When the job already has a map, this story does NOT fire — the fix routes to [add to map](021-add-the-fixs-stories-to-the-map.md) instead.
- [ ] The new map is born `human-oversight: unconfirmed` and must be ratified before an RFC references its stories (per [ratify](022-ratify-the-story-map-and-its-stories.md)).

## Driving problem trace (I6)

**P170** — problem tickets strain as fixes decompose into multiple coordinated changes. The first coordinated fix on any job has no map; this is the cold-start bootstrap of the decomposition surface.

## JTBD trace (I9)

**JTBD-008** — Decompose a Fix Into Coordinated Changes. The story map IS the decomposition surface; starting it is the walking skeleton's first step.

## Related

- **Implementation exemplar:** this map (STORY-MAP-002), hand-authored + ratified end-to-end this session, is the golden reference for the output this capability should reproduce (see P404).
- **STORY-MAP-002** A3 "start-the-map" card (Release 1 walking skeleton — the first run has no map, so it creates one).
- **ADR-090** — the new map is born unconfirmed and carries a drift-invalidated oversight marker.
- Implementation tracked in **P404** (Phase 2 story-map skills).
