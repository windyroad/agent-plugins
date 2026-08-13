---
status: draft
story-id: releases-are-proposed-against-the-problem-before-code
reported: 2026-06-29
decision-makers: [Tom Howard]
problems: [P251, P399]
jtbd: [JTBD-008]
rfcs: [RFC-005]
story-maps: [STORY-MAP-002]
estimated-effort: M
---

# STORY-015: Releases are proposed against the problem before any code is written

**Story map:** [← STORY-MAP-002: Take a Problem From Noticed to Resolved](../../story-maps/draft/STORY-MAP-002-take-a-problem-from-noticed-to-resolved.html) · A3 (Release 1) — the *create-RFC* card
**Siblings (A3):** [start the map](020-start-the-jobs-story-map.md) · [add to map](021-add-the-fixs-stories-to-the-map.md) · [ratify](022-ratify-the-story-map-and-its-stories.md) · [reuse](024-reuse-stories-already-on-the-map.md) · [slice](025-slice-the-fixs-stories-into-releases.md)
**Note (ADR-089/090):** the RFC lists **≥1 story** (never empty) and only **ratified** stories.

**Reported**: 2026-06-29
**Problems**: P251, P399
**JTBD**: JTBD-008
**RFCs**: RFC-005
**Estimated effort**: M

## User value (INVEST Valuable)

In order to fix the problem — and keep a single, traceable catalogue of the work that fix takes, tied back to the problem it solves — as a maintainer working a Known Error, I want the fix proposed as **one or more release rows on a story map**, recorded on the problem ticket, before any code is written.

A release row is the RFC: the set of stories that ship together. There is no separate RFC document to author, so "the RFC is written first" means "the rows are drawn and proposed first".

## Acceptance criteria (INVEST Testable)

- [ ] Proposing a fix on a Known Error records one or more release rows — new or existing, on new or existing maps — against the problem ticket.
- [ ] Work is queued, not started, when the proposal needs a new map, a new activity column, or a new ADR; it proceeds when the proposal uses only what is already ratified.
- [ ] The `capture-rfc --fix-time` byproduct path (shipped 2026-06-28, held) is **retired**, and its held changeset is resolved — graduated as reworked, or dropped.
- [ ] **Forward-dogfood**: take a real Known-Error problem, propose its release rows first (citing existing ADRs, or escalating an uncovered option to a ratified ADR), THEN implement one story from a row — confirming the ordering end-to-end.

## Driving problem trace (I6)

**P251 / P399.** P399 corrected the symptom (skeletons under-scoped) but kept the root error (RFC fabricated at/after fix-time); ADR-073 RFC-first repudiates fix-time authoring entirely. This story retires the `--fix-time` path and makes RFC authoring a pre-implementation story-map step. Supersedes RFC-005 B8 + the held B11 `--fix-time` changeset (rework slice B15).

## JTBD trace (I9)

**JTBD-008** — Decompose a Fix Into Coordinated Changes. The story map IS the decomposition; authoring it before implementation is the dogfood of RFC-first.

## Release split (per STORY-MAP-002)

Sits in the row that has no RFC identity yet: RFC-005 delivered six of its seven stories, so it was never one release and cannot own an undelivered one. This story's row gains an identity when a problem proposes it.

## Dependencies

- **Blocks**: STORY-017 (backfill reuses the pre-implementation story-map authoring path), RFC-005 B10 (held-changeset graduation gated on this + STORY-016).
- **Blocked by**: STORY-013 (the author-first gate invokes this authoring path).

## Related

- **Implementation exemplar:** this map (STORY-MAP-002), hand-authored + ratified end-to-end this session, is the golden reference for the RFC-as-pre-implementation-story-map output this capability should reproduce (see P404).
- RFC-005 B15; supersedes B8 + held B11. ADR-073 (RFC-first), ADR-060 (RFC = story map), P399 (the held --fix-time changeset).


## Story Maps

| ID | Title | Status |
|----|-------|--------|
| STORY-MAP-002 | STORY-MAP-002: Take a problem from noticed to resolved | draft |

## Rework note (2026-08-07)

Rewritten when a release row became the RFC. The original ask — that `capture-rfc` author an RFC document shaped like a story map rather than a `## Scope` + `## Tasks` blob — dissolved: there is no RFC document to shape. What survived is the ordering it was really protecting (propose before you build), the retirement of the held `--fix-time` byproduct path, and the end-to-end dogfood.

It also overlapped STORY-025 ("slice the fix's stories into releases"), which shipped the grouping itself. The distinction now is that STORY-025 draws the rows; this story requires that they be proposed against a problem before implementation begins.
