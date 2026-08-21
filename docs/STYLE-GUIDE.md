# Style Guide

## Purpose

This project is a plugin-development monorepo. Style guidance applies primarily to:

- Story-map HTML (`docs/story-maps/**/*.html`) — a rendered grid plus its data island, styled by one shared stylesheet. Per ADR-060 § Phase 2 encoding as amended by ADR-102.
- `packages/itil/templates/story-map.css` — the one stylesheet every map is rendered against, shipped in `@windyroad/itil` and copied beside an adopter's maps by `wr-itil-render-story-map`. `docs/story-maps/story-map.css` is that copy and is generated: edit the template, never the copy.
- Any other CSS / JSX / TSX / Vue / Svelte / ejs / hbs surface shipped by a plugin (currently none — the repo publishes governance plugins, not UI plugins).

## Story-map HTML style rules

Per ADR-060 § Phase 2 encoding, **as amended by ADR-102 (2026-08-05; amended 2026-08-06, 2026-08-07)**. A story map is a grid, and it is generated. A map file carries its own rendered grid plus the `<script id="story-map-data">` block it was generated from. The grid is written by `wr-itil-render-story-map`, never by hand and never at view time — **a map must be readable with no script engine at all**. Presentation lives in `packages/itil/templates/` — the stylesheet and the shell — so these rules bind those two files, not the artefacts.

### Layout
- A map is a `<table class="map">` inside a `<div class="scroll">` horizontal-scroll wrapper. Backbone activities are COLUMNS (`<thead>` → `<th class="act" scope="col">`); release slices are ROWS (`<th class="slice" scope="row">`); task cards sit in `<td class="cell">`. A row read left to right is everything that ships together.
- The scroll wrapper is the sanctioned two-dimensional-content exception to reflow (SC 1.4.10). `table.map { min-width: 940px }` inside `overflow-x: auto` is correct; do not make the grid reflow.
- `--cols` and the CSS-Grid backbone are **removed**. They belonged to the superseded stacked encoding.
- **`display: contents` is permitted only on a box that carries no semantics.** All of: computed role is `generic`, no `role`, no `aria-*`, no accessible name, not focusable, and no part in a required-owned-element chain — never on a `<ul>` whose `<li>`s must stay owned, nor on a table row or cell. Several engines drop the element from the accessibility tree along with its box, so any of those properties is lost silently.

  Nothing in the stylesheet uses it today: `.rib`, which did, was removed by ADR-102. The rule is recorded from an adopter's review of a map built on this template, so the question is settled once rather than re-litigated per map.

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
- `.t-status` with `.ts-done` / `.ts-arch` / `.ts-prog` / `.ts-acc` / `.ts-draft` — a **card's** own lifecycle state, keyed off the story file. A card-grain sibling of `.badge`, never `.badge` itself: the row's status is the more important fact and the card marker must not out-shout it.

  **Subordinate by four axes at once.** No pill shape and no fill — border-only where a border is used, per the no-background rule below. `.7rem`/600 against the badge's `.75rem`/700, glyph (`.ts-glyph`) at 700 against `.b-glyph`'s 900. Its own line above `.t-title`, not inline beside it. And a chroma budget: only `done`, `archived` and `in-progress` carry colour; `accepted` and `draft` render achromatic in `--muted`. A map with twenty-four cards would otherwise put twenty-four coloured markers against five row badges.

  The glyph is real text, never generated content — under forced colors the backgrounds collapse and the glyph becomes the only discriminator. For the same reason `.t-status` does **not** take `forced-color-adjust: none`: `.badge` opts out because its state lives in its fill, and this marker's does not.

  **No lifecycle state renders as absence.** Draft is quiet — muted, weight 400, no glyph, no border — but present. Absence is reserved for a story whose status could not be resolved, which is a different fact and needs an edit. Rendering draft as nothing would make the two identical, and would make this very defect unverifiable by looking at a map.
- `.badge` with `.b-live` / `.b-next` / `.b-defect` — a row's status pill, keyed off DERIVED status, never an authored field. Colour is never the sole channel: each badge carries real text — its RFC id, or `Needs an RFC id` / `Untraced — needs a problem` — and a distinct glyph, supplied once by the badge and never repeated in the label. There is no authored `badge`; an R1/R2 ordinal duplicated the RFC identity and collided with it.
- `.orient` — the orientation line and the ratification ask, between the `<h1>` and the grid so it is read before any scrolling and cannot be missed by not scrolling back. A second consecutive `.orient` is the subordinate line and takes `--muted`.
- `.genfrom` — the generated-file banner.

Removed by ADR-102: `.backbone`, `.rib`, `.rib-header`, `.map-note`. No map on disk carries them.

Also retired: `.b-later`. It was the amber "scheduled later" badge, and `badgeClass()` has had no path to it since a row with no trace became a defect rather than a third resting state — a row could sit in amber untraced indefinitely and feel accounted for. The rule and its glyph were left behind in the stylesheet and the renderer until 2026-08-21; both are now gone, and `--later-fg` survives only as `.task .ts-prog`'s colour.

### Data attributes (machine-readable trace)
- `data-story-id="STORY-NNN"` — on the `<div class="task">` card (was: on an `<a class="slice">`).
- `data-rfc="RFC-NNN"` — optional; ties the task to a parent RFC.
- `data-jtbd="JTBD-NNN"` — optional; ties to a persona-job.
- `data-status="<draft|accepted|in-progress|done|archived>"` — the story's lifecycle state at render time.
- `data-rib` — **removed**.

Each story-bearing card is emitted on a **single line**. That was load-bearing under ADR-101's whole-line filter; since the fingerprint became island-scoped, cards sit outside the basis entirely and this is a readability convention rather than a correctness constraint. A corollary worth stating: rendered marker text cannot drift a ratification, so there is no fingerprint reason to reach for generated content.

## Naming

- **Filenames**: kebab-case. `STORY-MAP-001-rfc-framework-phase-1-bootstrap.html` not `storyMap001RfcFramework.html`.
- **CSS class names**: kebab-case. `.rib-header` not `.ribHeader` or `.rib_header`.
- **Custom properties**: kebab-case prefixed with `--`. `--card-line` not `--CardLine` or `--cl`.

## Colours

Story maps are intentionally style-minimal; colour is OPTIONAL. If used:

- High contrast against white background (WCAG AA minimum 4.5:1 for text).
- Conventional status indicators: `draft = gray`, `accepted = blue`, `in-progress = yellow`, `done = green`, `archived = muted gray`.

  **Archived is not `--line`.** Read literally, "light gray" lands on `--line`, which is 4.20:1 against `--card` in light mode — under the 4.5:1 that marker text needs, and passing in dark mode at 5.02:1, so it fails in exactly one theme. Archived takes `--muted` (6.79:1 light, 8.19:1 dark) for its glyph and label, and may use `--line` for a border only, where 3:1 applies. Same class of miss as the 3.76:1 `.v-lead` incident.
- No background colours on the data-bearing story element (keep it visually neutral; status conveyed via border / outline if at all). Written for `<a class="slice">`; since ADR-102 that role is held by `.task`, so the rule now binds card markers.
- **Non-text contrast**: borders and other non-text UI boundaries meet 3:1 against their background (WCAG 2.2 SC 1.4.11). Written for `<a class="slice">`, whose border was once the only resting signal that the card was a link; since ADR-102 it binds `.task`'s `1px solid var(--card-line)` card edge and the `.cell` rules. `#767676` is the shared value (4.54:1 on white; `#8a919c` is its dark counterpart).

  On disk this now holds wherever a map is rendered: `docs/story-maps/story-map.css` ships `--line` and `--card-line` at `#767676`, and every map in `docs/story-maps/draft/` renders from it with no `<style>` block and no sub-3:1 grey. `docs/story-maps/README.md` no longer teaches a `<style>` block at all — ADR-102 replaced it with the JSON authoring shape.

  One stale source survives, and it is not a template: ADR-060's inlined example still shows `.slice { border: 1px solid #ccc }` — 1.61:1 — beside `text-decoration: none; color: inherit`, and still uses the `.backbone` / `.rib` / `<a class="slice">` classes ADR-102 deleted. It is a **historical record of a superseded encoding, not a shape to copy from**; ADR-116 makes a ratified body immutable, so it is corrected by supersession rather than edited. Read the stylesheet, never the ADR, for the live shape.

- **Colour is never the sole channel for a link inside prose.** Every `<a>` in a run of text keeps `text-decoration: underline` **at rest** — not on `:hover` only, and never reset to `text-decoration: none`. The rendered reference links sit mid-sentence — `closes <a>P160</a>`, `Traces: <a>STORY-018</a>` — so without the underline a link is distinguished from its neighbours by hue alone, which is SC 1.4.1 (Level **A**), failure technique F73.

  The colour-only allowance is not open either. Technique G183 wants 3:1 between the link and the text around it, and `--focus` against its neighbours is 1.50:1 (light, on `--fg`), 1.62:1 (dark, on `--fg`), 1.58:1 (light, on `--muted`) and **1.09:1 (dark, on `--muted`)**. The worst case is the common one: both in-prose contexts — `.t-ref` and `.s-problems` / `.traces` — are `--muted`, where in dark mode the two tones are all but indistinguishable.

  The rule binds the **element**, not the class. `.ref-link` is also used as a whole-element card-title link, where the underline is not what carries the affordance; and the stylesheet states the rule on the bare `a` selector, since the colour that creates the exposure is declared there and the two cannot then drift apart. A corollary worth recording: if a card title ever becomes an anchor, the at-rest underline pre-empts the hover cue below.

  This is the underline the browser already draws. The stylesheet states it so that a later `text-decoration: none` — the reset the pre-ADR-102 `.slice` card carried — reads as the regression it is rather than as a tidy-up.

### Interaction states

- **Focus**: `:focus-visible` is required on every interactive element whose only resting affordance is its border. Use `outline: 3px solid #0b3a66; outline-offset: 2px;` — reusing the value already shipped as `--focus` in `STORY-MAP-003` rather than minting a third blue. The offset is load-bearing, not cosmetic: at `0` the ring's inner edge abuts same-coloured glyphs at 1.00:1 and becomes a 1.4.11 finding of its own.
- **Focus must not be obscured** (SC 2.4.11, Level AA). A sticky header painted over a scrollport hides whatever the browser scrolls into it, because focus-driven scroll-into-view is not sticky-aware. `.scroll` therefore carries `scroll-padding-left` wide enough to clear the sticky `th.slice` column plus its focus ring. Any future sticky edge takes the matching `scroll-padding-*`.
- **Hover**: pair the border-colour change with a non-colour cue (`text-decoration: underline`) so the state survives greyscale and forced-colours mode. A 1px border darkening on its own is a state-to-state difference most sighted users cannot detect. This is a **card** rule — it governs an element whose border is its resting affordance. It does not govern text links, which carry their underline at rest; see § Colours.
- **Viewport and canvas**: every map declares `<meta name="viewport" content="width=device-width, initial-scale=1">` (WCAG 2.2 SC 1.4.10 Reflow) and pins its canvas with `:root { color-scheme: light; }` unless it ships a dark-mode counterpart — otherwise auto-dark-theme inverts the background while authored colours stay put, invalidating every contrast ratio.
- **Dark mode**: a map that declares `color-scheme` supplies a light-on-dark focus counterpart (`STORY-MAP-003` uses `#97c6f5`). A map that stays on the white canvas does not need one.

## Typography

- Use the browser default font stack via `font-family: system-ui, sans-serif;`, declared once in the shared stylesheet. Per-map `<style>` blocks are prohibited above.
- Card text: keep story titles short enough to scan at `.85rem` in a `10%`-wide column. Long titles **wrap**; they are never truncated. `text-overflow: ellipsis` would hide content that has no other rendering, which is a 1.4.4-shaped defect rather than a tidy card.
- **A map has exactly one heading: the `<h1>` map title.** The backbone and release axes are `<th scope="col">` and `<th scope="row">`, not headings — a table already exposes both axes to assistive technology, and duplicating them as `<h2>`s would announce every axis twice. (The superseded stacked encoding used `<h2>` for rib headers; ADR-102 removed ribs.)

## Scope

This guide applies to:
- HTML under `docs/story-maps/**/*.html`
- CSS files — `packages/itil/templates/story-map.css` and its generated copy at `docs/story-maps/story-map.css`. The story-map rules above are the ones that bind them.
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
