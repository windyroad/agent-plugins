# Style Guide

## Purpose

This project is a plugin-development monorepo. Style guidance applies primarily to:

- Story-map HTML (`docs/story-maps/**/*.html`) — a rendered grid plus its data island, styled by one shared stylesheet. Per ADR-060 § Phase 2 encoding as amended by ADR-102.
- Any CSS / JSX / TSX / Vue / Svelte / ejs / hbs surfaces shipped by plugins (currently none — the repo publishes governance plugins, not UI plugins).

## Story-map HTML style rules

Per ADR-060 § Phase 2 encoding, **as amended by ADR-102 (2026-08-05; amended 2026-08-06, 2026-08-07)**. A story map is a grid, and it is generated. A map file carries its own rendered grid plus the `<script id="story-map-data">` block it was generated from. The grid is written by `wr-itil-render-story-map`, never by hand and never at view time — **a map must be readable with no script engine at all**. Presentation lives in `packages/itil/templates/` — the stylesheet and the shell — so these rules bind those two files, not the artefacts.

### Layout
- A map is a `<table class="map">` inside a `<div class="scroll">` horizontal-scroll wrapper. Backbone activities are COLUMNS (`<thead>` → `<th class="act" scope="col">`); release slices are ROWS (`<th class="slice" scope="row">`); task cards sit in `<td class="cell">`. A row read left to right is everything that ships together.
- The scroll wrapper is the sanctioned two-dimensional-content exception to reflow (SC 1.4.10). `table.map { min-width: 940px }` inside `overflow-x: auto` is correct; do not make the grid reflow.
- `--cols` and the CSS-Grid backbone are **removed**. They belonged to the superseded stacked encoding.

### Prohibited
- **Inline `style=""` anywhere in a map.** Under ADR-102 presentation is the template's alone; the renderer emits none. This is stricter than the previous rule, which permitted `--<custom-property>` on layout containers.
- **A per-map `<style>` block.** *(Reversed 2026-08-06 by ADR-102.)* Presentation lives in one shared `docs/story-maps/story-map.css`, linked by every map. Inlining it duplicated ~920 identical lines across eight files and made a single tweak rewrite all of them. Maps are no longer self-contained, which is the accepted cost.
- **Hand-editing a rendered map.** Everything outside the data island — the grid, the `<meta>` block, the `<link>` — is regenerated from it; edits there are discarded on the next render. This matters more now that the grid ships in the file: it looks like ordinary HTML and is the first thing a reader reaches for.
- **A script the map needs in order to render.** *(Reversed 2026-08-07 by ADR-102.)* The grid ships in the file. Building it at view time made every map unreadable wherever scripts do not run — a phone's file preview, a sandboxed viewer, GitHub's HTML rendering, print — which is most of the places a file gets opened that are not a browser tab.

### Permitted
- One `<link rel="stylesheet" href="../story-map.css">`, placed beside the maps by `wr-itil-render-story-map` from the copy shipped in `@windyroad/itil`; edit the shipped copy, never the one in a repository.
- Exactly two `<script type="application/json">` data islands, which a viewer ignores rather than executes: `#story-map-data` (the authored source) and `#story-map-status` (derived — story statuses, value statements, row statuses, row and map problems, and resolved hrefs). No other `<script>` may appear.
- HTML5 semantic elements: `<table>`, `<thead>`, `<tbody>`, `<tr>`, `<th>`, `<td>`, `<caption>`, `<section>`, `<ul>`, `<li>`, `<p>`, `<a>`, `<span>`, `<strong>`, `<code>`, `<main>`, `<footer>`, `<h1>` / `<h2>`, `<div>` (layout only). The list grew when the grid moved back into the file: `<span>` carries most of the card vocabulary, `<a>` every resolved trace link, and `<strong>` the emphasis a story's own value statement marked.
- A wholly empty release band renders as ONE spanning `<td class="cell empty" colspan="N">` carrying a visually-hidden sentence, not N separate cells. It is silent in a screen reader's browse mode otherwise, while being a loud full-width hatch visually. Do not normalise it to per-cell markup.

### Class names (story-map vocabulary)

Normative, and emitted only by the template:

- `.map` — the grid table; one per map.
- `.scroll` — horizontal-scroll wrapper around `.map`; focusable (`tabindex="0"`, `role="region"`) so a keyboard user can pan it.
- `.act` — a backbone activity column header; one per activity. `.jtbd` is its optional gloss line.
- `.slice` — a release-band ROW header; one per release. `.s-name` and `.s-note` are its parts. **Meaning changed under ADR-102**: `.slice` was previously a single story reference carrying `data-story-id`. That role now belongs to `.task`.
- `.cell` — an activity × release intersection. `.cell.empty` means this activity ships nothing in that band, and is meaningful rather than decorative — the hatch is drawn in the `--line` tone so it clears 3:1.
- `.corner` — the empty top-left `<td>` where the two header axes meet.
- `.tasks` — the `role="list"` of cards inside one `.cell`.
- `.vh` — visually hidden; carries the empty-band sentence for a screen reader.
- `.b-glyph` — the `aria-hidden` glyph inside a `.badge`, carrying status as a channel besides colour.
- `.t-value` — a story's value statement on a card, split into `.v-line` parts: `.v-inorder`, `.v-asa`, `.v-iwant`. `.v-lead` is the connective ("In order to", "as a", "I want"), set in italic — and deliberately at full `--muted`, never faded, because at `opacity: .75` it composited to 3.76:1 against `--card` and 12px text needs 4.5:1.
- `.s-problems` — the problems a release row closes, on its row header. Derived from the stories in that row, never authored.
- `.traces` / `.tr-group` — the jobs the map is drawn for, as one line of links from the island's `traces.jtbd`. Jobs only: a decision trace is not a map's to carry (ADR-106), and an RFC line would restate the row badges directly beneath it. It replaced five paragraphs of hand-written trace prose, every one of which restated something already on the page.
- `.ref-link` — a resolved link to another artefact. Absent when the id did not resolve, so the text stands alone rather than dangling.
- `.task` — a task card inside a cell; carries the `data-*` trace layer. `.t-title`, `.t-value`, `.t-ref` are its parts.
- `.badge` with `.b-live` / `.b-next` / `.b-defect` — a row's status pill, keyed off DERIVED status, never an authored field. Colour is never the sole channel: each badge carries real text — its RFC id, or `Needs an RFC id` / `Untraced — needs a problem` — and a distinct glyph, supplied once by the badge and never repeated in the label. There is no authored `badge`; an R1/R2 ordinal duplicated the RFC identity and collided with it.
- `.genfrom` — the generated-file banner.

Removed by ADR-102: `.backbone`, `.rib`, `.rib-header`, `.map-note`. Maps still carrying them predate the amendment and are pending migration.

### Data attributes (machine-readable trace)
- `data-story-id="STORY-NNN"` — on the `<div class="task">` card (was: on an `<a class="slice">`).
- `data-rfc="RFC-NNN"` — optional; ties the task to a parent RFC.
- `data-jtbd="JTBD-NNN"` — optional; ties to a persona-job.
- `data-status="<draft|accepted|in-progress|done|archived>"` — the story's lifecycle state at render time.
- `data-rib` — **removed**.

Each story-bearing card is emitted on a **single line**. `story-oversight.sh` filters whole lines; a pretty-printed card would break the ADR-101 AFK-accept carve-out.

## Naming

- **Filenames**: kebab-case. `STORY-MAP-001-rfc-framework-phase-1-bootstrap.html` not `storyMap001RfcFramework.html`.
- **CSS class names**: kebab-case. `.rib-header` not `.ribHeader` or `.rib_header`.
- **Custom properties**: kebab-case prefixed with `--`. `--card-line` not `--CardLine` or `--cl`.

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
