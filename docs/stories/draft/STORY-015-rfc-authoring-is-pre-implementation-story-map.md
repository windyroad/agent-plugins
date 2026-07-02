---
status: draft
story-id: rfc-authoring-is-pre-implementation-story-map
reported: 2026-06-29
decision-makers: [Tom Howard]
problems: [P251, P399]
jtbd: [JTBD-008]
rfcs: [RFC-005]
story-maps: [STORY-MAP-002]
estimated-effort: M
---

# STORY-015: The RFC lists its stories before any code is written

**Story map:** [← STORY-MAP-002: Decompose a Fix Into Coordinated Changes](../../story-maps/draft/STORY-MAP-002-decompose-a-fix-into-coordinated-changes.html) · A3 (Release 1) — the *create-RFC* card
**Siblings (A3):** [start the map](020-start-the-jobs-story-map.md) · [add to map](021-add-the-fixs-stories-to-the-map.md) · [ratify](022-ratify-the-story-map-and-its-stories.md) · [reuse](024-reuse-stories-already-on-the-map.md) · [slice](025-slice-the-fixs-stories-into-releases.md)
**Note (ADR-089/090):** the RFC lists **≥1 story** (never empty) and only **ratified** stories.

**Status**: draft
**Reported**: 2026-06-29
**Problems**: P251, P399
**JTBD**: JTBD-008
**RFCs**: RFC-005
**Estimated effort**: M

## User value (INVEST Valuable)

In order that a fix is a deliberate, reviewable plan rather than something improvised at the keyboard, as a maintainer authoring an RFC for a fix, I want `/wr-itil:capture-rfc` (and the heavyweight `/wr-itil:manage-rfc`) to author the RFC as a **pre-implementation user story map** (ADR-060), not a fix-time `## Scope`+`## Tasks` blob.

## Acceptance criteria (INVEST Testable)

- [ ] `/wr-itil:capture-rfc` authors a pre-implementation story map (backbone + stories), not a fix-time Scope/Tasks blob.
- [ ] The `capture-rfc --fix-time` byproduct flag/path (shipped 2026-06-28, held) is **retired**; its held changeset is resolved (graduated-as-reworked or dropped).
- [ ] `/wr-itil:manage-rfc` produces/maintains the same story-map shape.
- [ ] **Forward-dogfood**: take a real Known-Error problem from the RFC-005 B7 backlog, author its RFC story map **first** (citing existing ADRs, or escalating an uncovered option to a ratified ADR), THEN implement one story — confirming RFC-first ordering end-to-end.

## Driving problem trace (I6)

**P251 / P399.** P399 corrected the symptom (skeletons under-scoped) but kept the root error (RFC fabricated at/after fix-time); ADR-073 RFC-first repudiates fix-time authoring entirely. This story retires the `--fix-time` path and makes RFC authoring a pre-implementation story-map step. Supersedes RFC-005 B8 + the held B11 `--fix-time` changeset (rework slice B15).

## JTBD trace (I9)

**JTBD-008** — Decompose a Fix Into Coordinated Changes. The story map IS the decomposition; authoring it before implementation is the dogfood of RFC-first.

## Release split (per STORY-MAP-002)

This story spans two releases on the map. **Release 1 (walking skeleton)** ships the **thin covered-path slice**: `/wr-itil:capture-rfc` authors one minimal pre-implementation story map for a fix whose approach existing ADRs already cover. **Release 2** ships the **deepening**: the heavyweight `/wr-itil:manage-rfc` richer authoring path, and retirement of the held `--fix-time` byproduct path.

## Dependencies

- **Blocks**: STORY-017 (backfill reuses the pre-implementation story-map authoring path), RFC-005 B10 (held-changeset graduation gated on this + STORY-016).
- **Blocked by**: STORY-013 (the author-first gate invokes this authoring path).

## Related

- RFC-005 B15; supersedes B8 + held B11. ADR-073 (RFC-first), ADR-060 (RFC = story map), P399 (the held --fix-time changeset).
