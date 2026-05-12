# Story Map Backlog

> Last reviewed: 2026-05-12 — **Scaffolded.** Directory + lifecycle subdirs created; encoding decision per ADR-060 amendment 2026-05-12 = HTML for story-maps; markdown stays for stories + RFCs + problems + decisions. STORY-MAP-001 bootstrap migration (from `docs/plans/170-rfc-framework-story-map.md`) lands in P170 Phase 2 Slice 8. Skills (`/wr-itil:capture-story-map`, `/manage-story-map`, `/reconcile-story-maps`, `/list-story-maps`) land in Phase 2 Slice 3.
>
> Run `/wr-itil:manage-story-map review` to refresh once the manage-story-map skill ships.

## Jobs to be Done

This index serves two persona-jobs per ADR-051 sibling pattern (JTBD-anchored README rule):

### solo-developer

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

This directory is **scaffold-only** until P170 Phase 2 Slice 3 ships `/wr-itil:capture-story-map` + `/wr-itil:manage-story-map` (Slice 3) and Slice 8 migrates `docs/plans/170-rfc-framework-story-map.md` to `STORY-MAP-001-rfc-framework-phase-1-bootstrap.html`.

## Story-map filename grammar

`docs/story-maps/<state>/STORY-MAP-<NNN>-<kebab-case-title>.html`

- `<state>` — one of `draft`, `accepted`, `in-progress`, `completed`, `archived`. State encoded by directory per ADR-031 sibling pattern (no filename suffix).
- `<NNN>` — three-digit zero-padded ID (matches `RFC-<NNN>` / `ADR-<NNN>` form). ID-collision-guard extension to `.html` enumeration in `docs/story-maps/` per ADR-019 (Phase 2 Slice 2 work).
- `<kebab-case-title>` — kebab-slug derived from the map's title.

## Story-map HTML schema

Per ADR-060 § Phase 2 encoding amendment (2026-05-12). Every story-map HTML file carries:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>STORY-MAP-NNN: <Title></title>
  <meta name="story-map-id" content="STORY-MAP-NNN">
  <meta name="status" content="<draft|accepted|in-progress|completed|archived>">
  <meta name="problems" content="P<NNN>[,P<NNN>...]">
  <meta name="rfcs" content="RFC-<NNN>[,RFC-<NNN>...]">
  <meta name="jtbd" content="JTBD-<NNN>[,JTBD-<NNN>...]">
  <style>
    .backbone { display: grid; grid-template-columns: repeat(var(--cols), 1fr); gap: 1rem; }
    .rib { display: contents; }
    .slice { border: 1px solid #ccc; padding: 0.5rem; }
  </style>
</head>
<body>
  <h1>STORY-MAP-NNN: <Title></h1>
  <section class="backbone" style="--cols: <N>">
    <header class="rib-header"><h2 data-rib="<rib-N-name>">Rib N</h2></header>
    <div class="rib">
      <a class="slice"
         href="../../stories/<state>/STORY-NNN-<slug>.md"
         data-story-id="STORY-NNN"
         data-rfc="RFC-<NNN>"
         data-jtbd="JTBD-<NNN>"
         data-status="<draft|accepted|in-progress|done|archived>">
        Story title
      </a>
    </div>
  </section>
</body>
</html>
```

**Prohibition**: `<a class="slice">`, `<h2 class="rib-header">`, and any element carrying `data-*` attributes MUST NOT carry inline `style=""` attributes. `--<custom-property>` CSS variables for grid sizing on container elements are permitted because they are layout-not-data. See ADR-060 amendment 2026-05-12 § Prohibition.

## Story Map Rankings

(Empty — no story maps captured yet. STORY-MAP-001 bootstrap migration lands in P170 Phase 2 Slice 8.)

| WSJF | ID | Title | Status | Problems | RFCs |
|------|-----|-------|--------|----------|------|

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
- **`docs/plans/170-rfc-framework-story-map.md`** — current Patton-style planning artefact for P170; migrates to `STORY-MAP-001-rfc-framework-phase-1-bootstrap.html` in P170 Phase 2 Slice 8.
- **`docs/rfcs/README.md`** — sibling directory's lifecycle index. Same architectural pattern applied at the RFC tier (markdown encoding).
- **`docs/stories/README.md`** — sibling directory for individual stories (markdown encoding, JTBD-008 + JTBD-001 anchors).
- **Jeff Patton**, *User Story Mapping* (O'Reilly, 2014) — backbone/ribs/slices canonical reference.
