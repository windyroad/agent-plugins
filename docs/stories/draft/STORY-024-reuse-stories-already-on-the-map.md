---
status: draft
story-id: reuse-stories-already-on-the-map
reported: 2026-07-02
decision-makers: [Tom Howard]
problems: [P170]
jtbd: [JTBD-008]
rfcs: [RFC-005]
story-maps: [STORY-MAP-002]
estimated-effort: M
human-oversight: unconfirmed
---

# STORY-024: Reuse stories already on the map

**Story map:** [← STORY-MAP-002: Decompose a Fix Into Coordinated Changes](../../story-maps/draft/STORY-MAP-002-decompose-a-fix-into-coordinated-changes.html) · A3 (Release 2)
**Siblings (A3):** [start the map](020-start-the-jobs-story-map.md) · [add to map](021-add-the-fixs-stories-to-the-map.md) · [ratify](022-ratify-the-story-map-and-its-stories.md) · [create RFC](015-rfc-authoring-is-pre-implementation-story-map.md) · [slice](025-slice-the-fixs-stories-into-releases.md)

## User value (INVEST Valuable)

As a developer decomposing a later fix on a job that already has a map, I want to **reuse stories already on the map** the fix touches — so I don't re-author a story that exists, and the RFC references the existing one.

## Acceptance criteria (INVEST Testable)

- [ ] When decomposing, existing map stories the fix touches are offered for reuse (referenced, not duplicated).
- [ ] A reused story's `rfcs:`/reverse-trace picks up the new RFC without a duplicate file.
- [ ] Reuse only offers **ratified** stories (per [ratify](022-ratify-the-story-map-and-its-stories.md) + ADR-090).

## Driving problem trace (I6)

**P170** — once a job's map has history, later fixes touch existing stories; reuse keeps the map coherent instead of sprouting near-duplicates.

## JTBD trace (I9)

**JTBD-008** — Decompose a Fix Into Coordinated Changes.

## Related

- **STORY-MAP-002** A3 "reuse" card (Release 2 — the harder cases). Implementation tracked in **P404**.
