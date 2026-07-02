---
status: done
story-id: add-the-fixs-stories-to-the-map
reported: 2026-07-02
decision-makers: [Tom Howard]
problems: [P170]
jtbd: [JTBD-008]
rfcs: [RFC-005]
story-maps: [STORY-MAP-002]
estimated-effort: M
oversight-confirmed-date: "2026-07-02 — ratified via AskUserQuestion (per-story pass)"
human-oversight: confirmed
oversight-hash: 3c662bdcd47c25cf47b29f3513c0eac42a0c0ae27a57713849ef2822fa1fc5f7
---

# STORY-021: Add the fix's new stories to the map

**Story map:** [← STORY-MAP-002: Decompose a Fix Into Coordinated Changes](../../story-maps/draft/STORY-MAP-002-decompose-a-fix-into-coordinated-changes.html) · A3 (Release 1)
**Siblings (A3):** [start the map](020-start-the-jobs-story-map.md) · [ratify](022-ratify-the-story-map-and-its-stories.md) · [create RFC](015-rfc-authoring-is-pre-implementation-story-map.md) · [reuse](024-reuse-stories-already-on-the-map.md) · [slice](025-slice-the-fixs-stories-into-releases.md)

## User value (INVEST Valuable)

In order that no part of a coordinated fix slips through the cracks — each change captured as its own trackable, prioritisable, reviewable piece rather than lost in a blob — as a developer decomposing a fix, I want to **add the fix's stories to the job's story map**.

## Acceptance criteria (INVEST Testable)

- [x] New stories are added to the job's existing map (each a full INVEST story with `problems`/`jtbd`/`rfcs`/`story-maps` traces, per ADR-089).
- [x] Every RFC carries **≥1 story** — an atomic fix adds exactly one story (never an empty `stories:` list, per ADR-089).
- [x] Added stories are born `human-oversight: unconfirmed`; the map re-opens to unconfirmed on the change (per [ratify](022-ratify-the-story-map-and-its-stories.md)).
- [x] A card on the map links to each added story's file.

## Driving problem trace (I6)

**P170** — the coordination surface (stories on a map) is what scales up when a fix spreads across multiple changes; adding stories is the core decompose act.

## JTBD trace (I9)

**JTBD-008** — Decompose a Fix Into Coordinated Changes.

## Related

- **Implementation exemplar:** this map (STORY-MAP-002), hand-authored + ratified end-to-end this session, is the golden reference for the output this capability should reproduce (see P404).
- **STORY-MAP-002** A3 "add-to-map" card.
- **ADR-089** (every RFC has ≥1 story) · **ADR-090** (added stories carry a drift-invalidated oversight marker).
- Implementation tracked in **P404**.
