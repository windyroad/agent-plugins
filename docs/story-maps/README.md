# Story Map Backlog

> Last reviewed: 2026-08-07. Maps are rendered from a data island by `wr-itil-render-story-map` per ADR-102; edit with `wr-itil-story-map-edit`, query with `wr-itil-story-map-query`. The bootstrap migration this note used to track is long done, and the map that carried it has since been retired into the decompose-a-fix journey.
>
> Run `/wr-itil:manage-story-map review` to refresh once the manage-story-map skill ships.

## Jobs to be Done

This index serves two persona-jobs per ADR-051 sibling pattern (JTBD-anchored README rule):

### developer

- **JTBD-008 (Decompose a Fix Into Coordinated Changes)** — primary fit. Story maps ARE the decomposition surface: when a fix decomposes into multiple coordinated changes (refactor across packages, phased migration, framework evolution), the story map provides the spatial 2D backbone × ribs × slices structure that names each sub-workstream as a first-class entity competing for WSJF attention at a level above individual commits. Patton's whole point is that the spatial layout *is* the meaning; HTML encoding preserves that semantic in a way markdown linearises away.

### plugin-user

- **JTBD-302 (Trust That the README Describes the Plugin I Just Installed)** — secondary fit. Adopters consuming `@windyroad/itil` who hit a multi-commit problem in their own repo need to read `docs/story-maps/README.md` to find the maps that decompose their fix. `data-status="done"` attributes on story-map slices are structurally less drift-prone than free-prose "✓ Done" notations, preserving load-bearing-at-commit-time trust signal per JTBD-302 § 2026-05-04 amendment.

## Status

`docs/story-maps/` is the canonical home for **user story map** artefacts per ADR-060 (Problem-RFC-Story framework) Phase 2 — DESIGN accepted 2026-05-10; SHIP in progress per P170 Phase 2 (started 2026-05-12). Story maps are the *what we're decomposing* layer of the four-tier governance hierarchy:

| Tier | Surface | Encoding | Lifecycle | Captures |
|------|---------|----------|-----------|----------|
| Problem | `docs/problems/<state>/` | markdown | `Open → Known Error → Verifying → Closed` (or `Parked`) | What hurts |
| ADR | `docs/decisions/` | markdown | `proposed → accepted → superseded` | How we decided to solve it |
| RFC | `docs/rfcs/` | markdown | `proposed → accepted → in-progress → verifying → closed` | What we're shipping to solve it |
| **Story Map** | **`docs/story-maps/<state>/`** | **HTML (`*.html`)** | **`draft → accepted → in-progress → completed → archived`** | **How the work decomposes spatially across backbone × ribs × slices** |
| Story | `docs/stories/<state>/` | markdown | `draft → accepted → in-progress → done → archived` | One slice of a story map; INVEST-shaped + JTBD-anchored |

This directory is live. Capture a map with `/wr-itil:capture-story-map`, move it through its lifecycle with `/wr-itil:manage-story-map`, and repair index drift with `/wr-itil:reconcile-story-maps`.

## Story-map filename grammar

`docs/story-maps/<state>/STORY-MAP-<NNN>-<kebab-case-title>.html`

- `<state>` — one of `draft`, `accepted`, `in-progress`, `completed`, `archived`. State encoded by directory per ADR-031 sibling pattern (no filename suffix).
- `<NNN>` — three-digit zero-padded ID (matches `RFC-<NNN>` / `ADR-<NNN>` form). ID-collision-guard extension to `.html` enumeration in `docs/story-maps/` per ADR-019 (Phase 2 Slice 2 work).
- `<kebab-case-title>` — kebab-slug derived from the map's title.

## Story-map HTML schema

**Amended by ADR-102 (2026-08-05).** A story map is a rendered grid, and it is generated. Each map is ONE file carrying its own data in a `<script id="story-map-data" type="application/json">` island; `wr-itil-render-story-map` reads that island and rewrites everything around it. Creation and editing are the same command on the same file.

**Author the island. Never hand-write the markup, and never open another map to copy its shape** — that inference is what let the whole corpus drift into a vertical stack together.

```html
<script id="story-map-data" type="application/json">
{
  "storyMapId": "STORY-MAP-<NNN>",
  "title": "<Title>",
  "status": "draft",
  "persona": "<persona>",
  "traces": { "problems": ["P<NNN>"], "rfcs": [], "jtbd": ["JTBD-<NNN>"], "adrs": [] },
  "lead": "A story map for the <persona> who ... Read across the top for the journey; read down the rows for release bands.",
  "backbone": [ { "id": "<slug>", "title": "A. <Activity>", "note": "<optional gloss>" } ],
  "releases": [ { "id": "live", "name": "Existing", "badge": "Live", "note": "shipped" } ],
  "tasks": [
    { "activity": "<backbone id>", "release": "<release id>",
      "title": "<what the persona can do>", "value": "Value: <why it matters>",
      "storyId": "STORY-<NNN>", "rfc": "RFC-<NNN>", "jtbd": "JTBD-<NNN>",
      "ref": "STORY-<NNN>, P<NNN>" }
  ],
  "traceProse": { "persona": "...", "jobs": "...", "problems": "...", "decisions": "...", "open": "..." }
}
</script>
```

Rendered shape: backbone activities become `<th class="act" scope="col">` COLUMNS; releases become `<th class="slice" scope="row">` ROWS; tasks become `<div class="task">` cards inside `<td class="cell">`; an activity × release pair with no tasks renders `<td class="cell empty">`. A row read left to right is everything that ships together.

**Trace layer**: `data-story-id`, `data-rfc`, `data-jtbd`, `data-status` on each rendered card. Since the cards are built in the browser, tooling that needs the trace reads the data block's `"storyId"` instead — `update-story-references-section.sh` and `story-oversight.sh` match both spellings. The island's pretty-printed serialisation keeps each `"storyId"` on its own line, which is what the ADR-101 whole-line filter needs.

**Ratification** is fingerprinted over the data island alone, not the whole file, so restyling the template can never revoke a human approval (ADR-102's amendment to ADR-090).

**Prohibition**: no inline `style=""` anywhere — presentation belongs to the template only. This is stricter than the superseded rule, which permitted `--<custom-property>` on layout containers. `--cols`, `<section class="backbone">`, `.rib`, `.rib-header`, `data-rib` and `<a class="slice">`-as-story-link are all removed.

**Authoring note**: escape a literal `<` in island strings as `\u003c`. A raw `</script>` terminates the block early — in the renderer and in a browser — and the renderer refuses the file rather than emitting a truncated map.

**Migration**: maps predating this amendment still carry the stacked encoding. They remain parseable — every consumer matches `data-story-id` or the `<meta>` block, neither of which is container-dependent — so a mixed corpus is safe. Tracked separately.

## Story Map Rankings

One row per story map in `draft` / `accepted` / `in-progress` status, from filesystem truth. Map-level WSJF is not yet computed — the column is reserved.

| WSJF | ID | Title | Status | Problems | RFCs |
|------|-----|-------|--------|----------|------|
| — | STORY-MAP-002 | Decompose a fix into coordinated changes | draft | P170, P251, P314, P371, P399, P390 | RFC-003, RFC-005, RFC-047 |
| — | STORY-MAP-003 | Sustain my token quota across the week and across surfaces | draft | P160, P443 | RFC-046 |
| — | STORY-MAP-004 | Close the loop with someone who reported a problem | draft | P376, P431 | RFC-051 |
| — | STORY-MAP-008 | Have a plugin behave like a guest in my repository | draft | P424, P435 | RFC-054 |
| — | STORY-MAP-011 | Trust the AFK loop's autonomous conduct | draft | P430, P433, P434, P438, P439 | RFC-050, RFC-052, RFC-053, RFC-056, RFC-057 |
| — | STORY-MAP-012 | Ship through a scored path | draft | P435, P208 | — |
| — | STORY-MAP-013 | Know what my push did | draft | P435 | — |


## Consolidated away

Six maps were absorbed into consolidated journeys and their files removed — five single-story stubs on 2026-08-05, and the framework-bootstrap map on 2026-08-07. Five held one card each — a map's clothes on a single fix. The sixth listed the tooling's own commands, which is an inventory rather than a journey anybody walks. The honest unit is the journey a persona takes.

Their IDs are retired and must not be reused. The lookup from each retired ID to the journey that absorbed it is recorded in problem ticket 477, kept there rather than here because this index treats any map ID it contains as a claim that the file exists on disk.

## Completed

(Empty — no completed story maps yet.)

| ID | Title | Completed | Driving problems |
|----|-------|-----------|------------------|

## Reconciliation

`docs/story-maps/README.md` is reconciled against on-disk HTML map files by `wr-itil-reconcile-story-maps` (P170 Phase 2 Slice 5; `$PATH` shim per ADR-049). The reconciliation contract mirrors `wr-itil-reconcile-readme docs/problems` per P118: diagnose-only mechanical drift detector that runs as a Step 0 preflight in `/wr-itil:manage-story-map` invocations.

Index row rendering uses `packages/itil/scripts/render-story-map-index.sh` (P170 Phase 2 Slice 5) which parses each HTML map's `<meta>` block (status, problems, rfcs, jtbd) plus the `<title>` element via `xmllint --xpath` (libxml2 present on macOS + GNU Linux) with a pure-shell `grep` fallback for adopters without libxml2.

## Related

- **ADR-060** — Problem-RFC-Story framework with mandatory problem-trace and unified problem ontology. The decision that introduces this directory.
- **ADR-060 amendment 2026-05-12** — HTML encoding for story-maps (this directory's storage convention).
- **ADR-031** — per-state-subdirectory encoding pattern (this directory's lifecycle subdir layout follows ADR-031 sibling pattern).
- **ADR-049** — plugin-bundled scripts via `bin/` on `$PATH`. `wr-itil-reconcile-story-maps` shim follows this naming grammar.
- **ADR-051** — JTBD-anchored README rule. This README anchors on JTBD-008 (primary) + JTBD-302 (secondary).
- **ADR-052** — behavioural-tests default. capture-story-map + manage-story-map + reconcile-story-maps ship with behavioural bats coverage.
- **JTBD-008** — Decompose a Fix Into Coordinated Changes. Primary persona-job for this directory.
- **JTBD-302** — Trust That the README Describes the Plugin I Just Installed. Secondary persona-job; README-currency rule applies.
- **P170** — driver problem ticket capturing the strain pattern that motivated ADR-060.
- **`docs/rfcs/README.md`** — sibling directory's lifecycle index. Same architectural pattern applied at the RFC tier (markdown encoding).
- **`docs/stories/README.md`** — sibling directory for individual stories (markdown encoding, JTBD-008 + JTBD-001 anchors).
- **Jeff Patton**, *User Story Mapping* (O'Reilly, 2014) — backbone/ribs/slices canonical reference.
