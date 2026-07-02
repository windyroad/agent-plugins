---
status: done
story-id: slice-the-fixs-stories-into-releases
reported: 2026-07-02
decision-makers: [Tom Howard]
problems: [P170]
jtbd: [JTBD-008]
rfcs: [RFC-005]
story-maps: [STORY-MAP-002]
estimated-effort: M
oversight-confirmed-date: "2026-07-02 — ratified via AskUserQuestion (per-story pass)"
human-oversight: confirmed
oversight-hash: 27fff01e1fe51ed59ac070e910217869ab978ef64701b555f1a5995058307f6c
---

# STORY-025: Slice the fix's stories into releases

**Story map:** [← STORY-MAP-002: Decompose a Fix Into Coordinated Changes](../../story-maps/draft/STORY-MAP-002-decompose-a-fix-into-coordinated-changes.html) · A3 (Release 2)
**Siblings (A3):** [start the map](020-start-the-jobs-story-map.md) · [add to map](021-add-the-fixs-stories-to-the-map.md) · [ratify](022-ratify-the-story-map-and-its-stories.md) · [create RFC](015-rfc-authoring-is-pre-implementation-story-map.md) · [reuse](024-reuse-stories-already-on-the-map.md)

## User value (INVEST Valuable)

In order that users get the important part sooner, and work I defer stays visible instead of being quietly dropped, as a developer, I want to **slice the fix's stories into releases** (MVP first).

## Acceptance criteria (INVEST Testable)

- [x] Stories on the map can be grouped into ordered release slices (Release 1 walking skeleton → Release 2 …).
- [x] Deferred phases stay first-class (visible on the map, competing for priority), not buried.
- [x] The release-slice grouping is a map change → re-opens ratification (per [ratify](022-ratify-the-story-map-and-its-stories.md)).

## Driving problem trace (I6)

**P170** — phased work needs explicit ordering; a slice makes the MVP boundary and deferred phases first-class instead of implicit.

## JTBD trace (I9)

**JTBD-008** — Decompose a Fix Into Coordinated Changes (the time-boxing / phase-ordering outcome).

## Related

- **Implementation exemplar:** this map (STORY-MAP-002), hand-authored + ratified end-to-end this session, is the golden reference for the output this capability should reproduce (see P404).
- **STORY-MAP-002** A3 "slice" card (Release 2). This map's own R1/R2 bands are the dogfood. Implementation tracked in **P404**.
