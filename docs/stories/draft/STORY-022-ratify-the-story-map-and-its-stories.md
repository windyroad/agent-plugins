---
status: draft
story-id: ratify-the-story-map-and-its-stories
reported: 2026-07-02
decision-makers: [Tom Howard]
problems: [P170]
jtbd: [JTBD-008]
rfcs: [RFC-005]
story-maps: [STORY-MAP-002]
adrs: [ADR-090]
estimated-effort: L
human-oversight: confirmed
oversight-confirmed-date: "2026-07-02 — ratified via AskUserQuestion (per-story pass); acceptance amended to encode the map-first, two-option ratification UX the user pinned"
---

# STORY-022: Ratify the story map and its stories after any change

**Story map:** [← STORY-MAP-002: Decompose a Fix Into Coordinated Changes](../../story-maps/draft/STORY-MAP-002-decompose-a-fix-into-coordinated-changes.html) · A3 (Release 1)
**Siblings (A3):** [start the map](020-start-the-jobs-story-map.md) · [add to map](021-add-the-fixs-stories-to-the-map.md) · [create RFC](015-rfc-authoring-is-pre-implementation-story-map.md) · [reuse](024-reuse-stories-already-on-the-map.md) · [slice](025-slice-the-fixs-stories-into-releases.md)

## User value (INVEST Valuable)

In order to trust that a fix is built on a map a human actually reviewed — not one that quietly drifted or was auto-generated and never checked — as a maintainer, I want the map **and each story on it** to require **re-ratification after any change** before an RFC can rely on them.

## Acceptance criteria (INVEST Testable)

- [ ] A story map and each story carry a `human-oversight:` marker (`unconfirmed`/`confirmed`), orthogonal to the `status:` lifecycle.
- [ ] **Any change** to a map or a story (add / edit / re-slice / reuse / retitle) re-opens its marker to `unconfirmed` — drift-invalidated, not write-once (ADR-009 lineage).
- [ ] An RFC may reference **only ratified** stories — [create RFC](015-rfc-authoring-is-pre-implementation-story-map.md) is gated on this.
- [ ] An unratified-map detector surfaces them (mirroring the ADR/JTBD oversight drains).
- [ ] **Ratification UX**: the **map (USM) is ratified first** — present its URL + context, then an AskUserQuestion with exactly two options: **Ratify** or free-text ("type something"). Only once the map is ratified are the **stories** ratified — one at a time, each briefed then offered the same **Ratify / type-something** choice.

## Driving problem trace (I6)

**P170** — the coordination surface is auto-/hand-authored and drifts; unratified content must not be silently trusted. Same lift-to-human discipline P283/P288 applied to ADRs/JTBDs, now on the story tier.

## JTBD trace (I9)

**JTBD-008** — Decompose a Fix Into Coordinated Changes (the decomposition surface must be trustworthy before the RFC leans on it).

## Related

- **STORY-MAP-002** A3 "ratify" card. **ADR-090** — the authority (drift-invalidated marker; RFC references only ratified stories).
- Implementation tracked in **P404** (Phase 2).
