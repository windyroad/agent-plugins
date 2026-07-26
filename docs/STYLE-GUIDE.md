# Style Guide

## Purpose

This project is a plugin-development monorepo. Style guidance applies primarily to:

- Story-map HTML (`docs/story-maps/**/*.html`) — minimal embedded `<style>` per ADR-060 § Phase 2 encoding amendment 2026-05-12.
- Any CSS / JSX / TSX / Vue / Svelte / ejs / hbs surfaces shipped by plugins (currently none — the repo publishes governance plugins, not UI plugins).

## Story-map HTML style rules

Per ADR-060 § Phase 2 encoding amendment 2026-05-12 lines 392-435:

### Layout
- Backbone × ribs × slices uses CSS Grid via embedded `<style>` block in `<head>`. Layout-only rules (no semantic styling).
- Grid sizing via `--<custom-property>` variables permitted inline on layout-container elements (e.g. `style="--cols: 4"` on `.backbone`).
- `--cols` is the **number of slices laid out per row** within one rib — the grid's column count — not the number of ribs and not the rib's total slice count. A rib holding one slice uses `--cols: 1`; a rib holding four side by side uses `--cols: 4`. A rib may hold more slices than `--cols`, in which case they wrap to further rows (see `STORY-MAP-001`, whose `--cols: 1` rib stacks two slices).

### Prohibited
- **Inline `style=""` on data-bearing elements**: `<a class="slice">` carrying `data-story-id` MUST NOT carry inline `style=""`. Rationale: keeps `grep`-as-lint deterministic; data-attribute extraction never matches a styling string.
- **Inline `style=""` on `<h2 class="rib-header">` carrying `data-rib`**: same rationale.
- **External stylesheets** (`<link rel="stylesheet">`): story maps are self-contained artefacts; the embedded `<style>` block in `<head>` is the only permitted styling source.

### Permitted
- Embedded `<style>` block in `<head>` with layout-only class-keyed rules.
- `--<custom-property>` variables inline on layout containers (e.g. `--cols`, `--rows`, `--gap`).
- HTML5 semantic elements: `<section>`, `<header>`, `<h1>` / `<h2>`, `<a>`, `<div>` (only as a layout container).

### Class names (story-map vocabulary)
- `.backbone` — per-rib grid container; one per rib, many per map. Multiple ribs are encoded as sibling `<section class="backbone">` elements, not as multiple `.rib` divs inside one section: `.rib { display: contents }` promotes slices to direct grid items and `.rib-header { grid-column: 1 / -1 }` assumes one header per grid, so a second rib inside one `.backbone` would share a single `--cols` track list and break both. Keeping ribs as siblings in DOM order also keeps focus order equal to visual order. (Known misnomer: Patton's conceptual backbone is the ordered set of these sections, not any one of them. Renaming the class is a decision, not a doc fix.)
- `.rib` — horizontal lane of related slices; many per map.
- `.rib-header` — heading row for a rib; one per rib.
- `.slice` — single story reference (carries `data-story-id`); many per rib.
- `.map-note` — optional trailing prose annotation on the map (rationale, floor-shape justification, growth plan). Carries no `data-*` attributes; unstyled by default.

Maps written before this vocabulary was recorded also use `.task`, `.legend`, `.badge`, and `.b-live` / `.b-next` / `.b-later` (see `STORY-MAP-003`). Those are not yet normative — they are catalogued in the vocabulary-and-contrast sweep ticket rather than blessed here.

### Data attributes (machine-readable trace)
- `data-story-id="STORY-NNN"` — on `<a>` slice element.
- `data-rfc="RFC-NNN"` — optional; ties the slice to a parent RFC.
- `data-jtbd="JTBD-NNN"` — optional; ties to a persona-job.
- `data-status="<draft|accepted|in-progress|done|archived>"` — story's lifecycle state at map-render time.

## Naming

- **Filenames**: kebab-case. `STORY-MAP-001-rfc-framework-phase-1-bootstrap.html` not `storyMap001RfcFramework.html`.
- **CSS class names**: kebab-case. `.rib-header` not `.ribHeader` or `.rib_header`.
- **Custom properties**: kebab-case prefixed with `--`. `--cols` not `--Cols` or `--c`.

## Colours

Story maps are intentionally style-minimal; colour is OPTIONAL. If used:

- High contrast against white background (WCAG AA minimum 4.5:1 for text).
- Conventional status indicators: `draft = gray`, `accepted = blue`, `in-progress = yellow`, `done = green`, `archived = light gray`.
- No background colours on data-bearing `<a class="slice">` elements (keep them visually neutral; status conveyed via border / outline if at all).
- **Non-text contrast**: borders and other non-text UI boundaries meet 3:1 against their background (WCAG 2.2 SC 1.4.11). This binds hardest on `.slice`, whose border is the only resting signal that the card is a link. Use `#767676` (4.54:1 on white) as the shared border value for new maps.

  Maps written before this rule, plus the two template sources (ADR-060's inlined template and `docs/story-maps/README.md`), still carry sub-3:1 border greys such as `#ccc` (1.6:1), `#c9d2de`, and `#c4c4c4`. The sweep is tracked as its own ticket — this line is normative for new work, not a description of what is currently on disk.

### Interaction states

- **Focus**: `:focus-visible` is required on every interactive element whose only resting affordance is its border. Use `outline: 3px solid #0b3a66; outline-offset: 2px;` — reusing the value already shipped as `--focus` in `STORY-MAP-003` rather than minting a third blue.
- **Hover**: pair the border-colour change with a non-colour cue (`text-decoration: underline`) so the state survives greyscale and forced-colours mode. A 1px border darkening on its own is a state-to-state difference most sighted users cannot detect.
- **Viewport and canvas**: every map declares `<meta name="viewport" content="width=device-width, initial-scale=1">` (WCAG 2.2 SC 1.4.10 Reflow) and pins its canvas with `:root { color-scheme: light; }` unless it ships a dark-mode counterpart — otherwise auto-dark-theme inverts the background while authored colours stay put, invalidating every contrast ratio.
- **Dark mode**: a map that declares `color-scheme` supplies a light-on-dark focus counterpart (`STORY-MAP-003` uses `#97c6f5`). A map that stays on the white canvas does not need one.

## Typography

- Use the browser default font stack via `font-family: system-ui, sans-serif;` in the embedded style block.
- Slice card text: ≤ 80 characters; truncate longer titles with CSS `text-overflow: ellipsis` if needed.
- Heading sizes: H1 for map title; H2 for rib headers; no H3+ inside slices (slices are leaves).

## Scope

This guide applies to:
- HTML under `docs/story-maps/**/*.html`
- CSS files (none currently in the repo)
- JSX / TSX / Vue / Svelte component style blocks (none currently)
- ejs / hbs templates with embedded styling (none currently)

It does NOT apply to:
- Markdown documentation (no styling; render-target-dependent).
- Plugin SKILL.md prose (covered by `docs/VOICE-AND-TONE.md`).
- Test fixtures or temp HTML (out of scope; not adopter-facing).

## Related

- **ADR-060 amendment 2026-05-12** — HTML encoding for story-maps + prohibition on inline style on data-bearing elements.
- **`docs/VOICE-AND-TONE.md`** — sibling policy for prose content.
- **`docs/story-maps/README.md`** — story-map directory scaffold + per-state subdir convention.
- **JTBD-302** — Trust That the README Describes the Plugin I Just Installed; style guidance supports that trust by keeping HTML simple, semantic, and grep-able.
