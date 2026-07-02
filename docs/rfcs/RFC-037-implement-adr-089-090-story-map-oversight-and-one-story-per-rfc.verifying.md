---
status: verifying
rfc-id: implement-adr-089-090-story-map-oversight-and-one-story-per-rfc
reported: 2026-07-02
decision-makers: [Tom Howard]
problems: [P404]
adrs: [ADR-089, ADR-090, ADR-060, ADR-071]
stories: [STORY-020, STORY-021, STORY-022, STORY-024, STORY-025]
story-maps: [STORY-MAP-002]
---

# RFC-037: Implement ADR-089 (every RFC ≥1 story) + ADR-090 (story-map/story oversight)

> Traces to **P404**. Authored 2026-07-02 as the RFC-first fix for P404 — dogfooding the process this very work builds (STORY-013 "no RFC → author it first"; STORY-015 "the RFC is a pre-implementation story map listing its stories"). Hand-authored in that target shape because the tooling that would generate it is itself part of this fix.

## Problem

**P404** — the two decisions ratified this session (ADR-089: every RFC has ≥1 story; ADR-090: story maps and stories carry a drift-invalidated human-oversight marker) have no implementation. The skills + tests still encode the empty-stories fallback and have no story-map/story oversight axis.

## Approach — this RFC is the traceable catalogue

Per ADR-060 + STORY-015, an RFC *is* stories in a user story map, not a fix-time byproduct. This RFC's stories live on **STORY-MAP-002** (JTBD-008's USM); this RFC scopes the subset that implements ADR-089/090, in two phases.

## The catalogue

### Phase 1 — ADR-089 (every RFC has ≥1 story)

Cross-cutting enforcement (no single map card — it hardens the create-RFC/decompose invariant that [STORY-015](../stories/draft/STORY-015-rfc-authoring-is-pre-implementation-story-map.md) + [STORY-021](../stories/draft/STORY-021-add-the-fixs-stories-to-the-map.md) already assert):

- Remove the empty-stories fallback in the `work-problem`/`manage-problem` Known-Error traversal + the `Refs: RFC-NNN` atomic trailer.
- `capture-rfc`/`manage-rfc` reject an `accepted` RFC with empty `stories: []`; drop the lazy-empty `## Stories` omission.
- **Flip the four green bats** (`rfc-stories-extension`, `working-the-problem-traversal`, `check-rfc-rejected-alternatives`, `list-stories-contract`) from asserting the empty-stories fallback is legal to asserting it is rejected — **in the SAME slice that ships the behaviour**, or CI goes red (P404's highest-signal risk).
- Legacy back-fill: existing `stories: []` RFCs (e.g. RFC-036, RFC-003) get one story each.

### Phase 2 — ADR-090 (story-map/story drift-invalidated oversight) — the story-map/story tooling

Each story is on STORY-MAP-002; the marker + gate ride the tooling that builds them:

- **[STORY-020](../stories/draft/STORY-020-start-the-jobs-story-map.md)** — start the job's story map (skill: capture-story-map).
- **[STORY-021](../stories/draft/STORY-021-add-the-fixs-stories-to-the-map.md)** — add stories to the map (capture-story), each born `unconfirmed`.
- **[STORY-022](../stories/draft/STORY-022-ratify-the-story-map-and-its-stories.md)** — the drift-invalidated marker + re-open-on-edit trigger + the RFC-references-only-ratified-stories gate + the unratified-map detector. The core ADR-090 story.
- **[STORY-024](../stories/draft/STORY-024-reuse-stories-already-on-the-map.md)** — reuse existing (ratified) stories.
- **[STORY-025](../stories/draft/STORY-025-slice-the-fixs-stories-into-releases.md)** — release-slice the map.

## Confirmation

**Status: implementation complete (2026-07-03) — awaiting P404 verification to close.** All five stories (STORY-020/021/022/024/025) are `done` and ratified.

- ADR-089 ✅ — `wr-itil-check-rfc-has-stories` (behavioural bats) hard-blocks an `accepted` RFC with `stories: []` at the `manage-rfc` accept gate; the empty-stories fallback was removed from the work-problem/manage-problem traversal; the coupled `working-the-problem-traversal` bat was flipped in the same slice, and the other three verified green under the new model. Commits `3e3300a3`, `d2eb97d5`, `af49f7e6`.
- ADR-090 ✅ — story maps + stories carry a drift-invalidated `human-oversight` marker fingerprinted by `oversight-hash`; any **substance** edit re-opens ratification (lifecycle progress — status, checkbox ticks, slice `data-status` — does not); `wr-itil-check-rfc-stories-ratified` refuses an RFC referencing an unratified story; `wr-itil-detect-unratified-stories-maps` surfaces unratified maps + stories into the work-problems Step 2.4 drain; the ratify UX (map-first → stories) lives in `manage-story-map` / `manage-story`; new maps/stories are born `unconfirmed`.
- **Golden exemplar** ✅ — `capture-story-map` / `capture-story` now birth `unconfirmed` artefacts and the ratify flow reproduces STORY-MAP-002's shape (backbone × ribs × slices, INVEST value-first stories, drift-invalidated oversight); the hand-authored STORY-MAP-002 is the reference the tooling matches.

## Related

- **P404** (the problem). **ADR-089 / ADR-090** (the ratified authorities). **ADR-060** (RFC = story map) / **ADR-071** (RFC-first).
- **STORY-MAP-002** — the USM this RFC's stories live on, and the hand-authored exemplar.
- Vehicle note: kept separate from **RFC-005** (which traces P251/P399) because P404 is a distinct problem — the fix's own dedicated RFC (ADR-060: multiple RFCs may trace to one problem; nothing forces folding into an unrelated one).
