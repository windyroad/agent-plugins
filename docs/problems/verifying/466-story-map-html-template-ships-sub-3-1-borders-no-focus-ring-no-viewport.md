# Problem 466: The story-map HTML template ships sub-3:1 borders, no focus ring, and no viewport meta

**Status**: Verification Pending
**Reported**: 2026-07-26
**Priority**: 10 (Medium) — Impact: 2 (Minor — governance artefacts rendered for humans to read; no adopter runtime surface. Re-rated 2026-08-21: briefly carried Impact 3 on the premise that this project's product line is accessibility tooling. That premise is FALSE — CLAUDE.md line 5 states this is not a web UI project and that the accessibility-first guidance comes from the third-party `accessibility-agents` plugin injected into `~/CLAUDE.md`, not from anything in `packages/`. The product line is governance / ITIL / risk / TDD / JTBD plugins. Severity must not borrow credibility stakes this project does not have.) × Likelihood: 5 (Almost certain — *every render already carries it*. Rests on **defect 5** as of 2026-08-21, not defect 4: the sticky-column focus obscuring is live in the shipped CSS at every width under 940px. Defect 4 turned out to be latent rather than live — the UA default underline was still in force — so the original wording, "the rule is absent from the shipped CSS so all renders fail it today", was true of the wrong defect.)
**Origin**: inbound-reported (addressr, 2026-08-21) — defect 4 externally corroborated; defects 1-3 internal
**Effort**: S — mechanical CSS edits across two template sources and four map files, plus one grid fix — cf. P429 (S). *Actual 2026-08-21: S. Two CSS properties, one dead rule retired, and a STYLE-GUIDE pass; the four-map sweep and the grid fix had both been made moot by ADR-102.*
**WSJF**: 10 — (10 × 1.0) / 1 (re-rated 2026-08-21: defect 5 is live and adopter-visible, but the Impact-3 rationale rested on a false product-line premise and is withdrawn)
**JTBD**: JTBD-008
**Persona**: developer

## Description

> **Historical, as captured 2026-07-26.** Defects 1-3 and the grid overflow below were closed or made moot by ADR-102's render pipeline; STORY-MAP-001 is no longer on disk. Current state is in Investigation Tasks, and the two defects that were still live in 2026-08 are Defect 4 and Defect 5 further down. Left unrewritten because the propagation story is what the ticket is for.

The canonical story-map HTML template — inlined in ADR-060 (line 408) and mirrored in `docs/story-maps/README.md` (line 59) — teaches a `<style>` block that fails several WCAG 2.2 criteria, and four of the five maps on disk have copied it.

Three defects, all inherited rather than independently introduced:

1. **Non-text contrast (SC 1.4.11)**. `.slice { border: 1px solid #ccc; }` is 1.6:1 on white, against a 3:1 floor. This is load-bearing rather than decorative: `.slice` also sets `text-decoration: none; color: inherit`, so the 1px border is the *only* resting signal that the card is a link. Actual on-disk values are `#ccc` (STORY-MAP-001, STORY-MAP-004), `#c9d2de` (STORY-MAP-002), and `#c4c4c4` / `#cfcfcf` (STORY-MAP-003) — all sub-3:1.
2. **No focus indicator**. The template has `.slice:hover` but no `:focus-visible` counterpart, so a keyboard user gets no indication of which card is focused. STORY-MAP-003 solved this independently with `outline: 3px solid var(--focus)`; the template never learned it.
3. **No viewport meta (SC 1.4.10 Reflow)**. Without it, mobile browsers assume a ~980px layout viewport and scale down, forcing two-dimensional scrolling. STORY-MAP-003 has it; the template and the other maps do not.

A fourth, narrower defect sits on one map: STORY-MAP-001 combines `--cols: 4` / `--cols: 3` with `grid-template-columns: repeat(var(--cols), 1fr)` and no viewport meta. A `1fr` track has a `min-content` floor, so those columns never collapse and the grid overflows horizontally at 320px — a live 1.4.10 failure rather than a latent one.

Related but separable: `docs/STYLE-GUIDE.md`'s story-map class vocabulary is incomplete. `.map-note` was added on 2026-07-26, but STORY-MAP-003's `.task`, `.legend`, `.badge`, `.b-live`, `.b-next`, and `.b-later` remain uncatalogued, so the guide does not describe what is actually on disk.

## Symptoms

- 2026-07-26 (P430 iter): authoring STORY-MAP-005 from the STORY-MAP-004 shape drew a FAIL from `wr-style-guide:agent` on the inherited `#ccc` border and a further FAIL on the focus value, then five findings from `accessibility-agents:accessibility-lead` (missing viewport, imperceptible hover step, no `<main>` landmark, no `color-scheme`, opaque `.md` link target). STORY-MAP-005 was authored to the corrected values and `docs/STYLE-GUIDE.md` gained the three governing rules, but the template sources and the four pre-existing maps were left untouched — so the next author who reads the template rather than the guide re-inherits all of it.

- 2026-08-21 (inbound, adopter `addressr`): adopting the story tier for the first time, addressr ran its own accessibility review over its first map and routed two items back upstream — whether the link underline belongs at rest rather than on `:hover` (its link-checker argues at-rest is what *discharges* SC 1.4.11 rather than merely satisfying it), and whether the `.rib` grid should become `<ul role="list">` + `grid-template-columns: subgrid` (explicitly "an ADR against the framework, not a local decision"). Its lead **cleared** `display: contents` on `.rib` as a non-defect and named this repo's own map shape as the correct precedent to copy — so the template reviewed well overall. Checking their underline claim against our source surfaced a **fourth, more severe defect they did not catch**, recorded below: they were arguing hover-vs-rest on the assumption an underline exists somewhere, and none does.

## Workaround

Superseded by ADR-102 (2026-08-05): maps are no longer copied from an exemplar at all. `packages/itil/templates/story-map.html` is the single source of the shape and `wr-itil-render-story-map` builds every map from it, so the inherited-values failure mode this ticket describes is closed at the source.

## Impact Assessment

- **Who is affected**: anyone reading a story map, most sharply keyboard and low-vision users. (An earlier revision added "the project's own credibility, since it publishes accessibility tooling" — struck 2026-08-21: it does not. See the Priority line.)
- **Frequency**: every new map authored from the template.
- **Severity**: Medium — no runtime breakage, but it is a documented standards failure in artefacts the project asks people to read, and it self-propagates.

## Root Cause Analysis

### Investigation Tasks

**Re-grounded 2026-08-20** (user re-reported the contrast failure from a live authoring session; verified against disk rather than taken on report). ADR-102's render pipeline closed most of this: `docs/story-maps/story-map.css` now ships `--line: #767676` (4.54:1), a `:focus-visible` outline at `3px solid var(--focus)` with 2px offset, and a dark-mode counterpart; `docs/story-maps/README.md` no longer teaches a `<style>` block at all (it is now the JSON authoring shape). No `border: 1px solid #<sub-3:1>` survives in any on-disk map.

One template source did not get swept: **`docs/decisions/060-...accepted.md` line 415 still inlines `.slice { border: 1px solid #ccc; padding: 0.5rem; }`** — 1.61:1 on white, against the 3:1 floor of SC 1.4.11, and still load-bearing because the inlined template also sets `text-decoration: none; color: inherit`. It is the surviving propagation vector: an author who reads the ADR rather than the CSS re-inherits the original defect.

- [x] ~~Strike or correct the inlined `<style>` block at ADR-060 line 415~~ — **barred, and re-scoped.** `wr-architect:agent` 2026-08-21: ADR-060 carries `human-oversight: confirmed`, and ADR-116 (2026-08-13) makes a ratified body immutable — no in-place edit, no amendment section, no marker clearing. Both the recolour and a supersession banner are barred. Routed to **P481**, which already owns ADR-060's stale-spec reconciliation (its fenced frontmatter block, same document, same class) and already records the maintainer ruling that a ratified decision changes only by supersession. The `<style>` block is added there as a further stale region rather than captured as a sibling ticket. P483 governs the rule; P481 is the work. Either way it needs human ratification and so is not an AFK action. The propagation vector is closed in the meantime where it is actually reachable: STYLE-GUIDE § Colours now states that ADR-060's inlined example is a historical record of a superseded encoding and not a shape to copy from.
- [x] ~~Fix the two template sources first (ADR-060 line 408 and `docs/story-maps/README.md` line 59) — they are the propagation vector; fixing maps without fixing templates re-opens this.~~ — README source retired by ADR-102; ADR-060 still outstanding, split out above
- [x] ~~Sweep the four existing maps to `#767676` borders, add `:focus-visible` (`3px solid #0b3a66`, offset 2px), add viewport meta, and pin the canvas with `:root { color-scheme: light; }` where no dark-mode counterpart exists.~~ — superseded: the shared CSS carries a full dark-mode block and every map renders from it
- [x] ~~Fix STORY-MAP-001's grid overflow~~ — moot. STORY-MAP-001 is no longer on disk, and `--cols` / the CSS-Grid backbone were removed by ADR-102; the live grid is a `<table class="map">` in an `overflow-x: auto` wrapper, which is the sanctioned SC 1.4.10 two-dimensional exception.
- [x] ~~Catalogue `.task` / `.legend` / `.badge` / `.b-live` / `.b-next` / `.b-later`, or retire them~~ — done, and split by which was true of each. `.task`, `.badge`, `.b-live`, `.b-next` were already catalogued. `.legend` and `.map-note` are moot: removed by ADR-102 and emitted by nothing. `.b-later` was neither — it was **dead code in the shipped template**, styled at `story-map.css:75` and present in the renderer's `BADGE_GLYPH`, with no path to it from `badgeClass()` since a row with no trace became a defect rather than a third resting state. Retired from both. Two classes the guide had simply never named — `.orient` and `.ts-glyph` — are now catalogued.
- [x] ~~Correct the stale § Typography rules~~ — three of them contradicted disk: the font stack was to be declared "in the embedded style block" (prohibited by the guide's own line 21), `text-overflow: ellipsis` was mandated but never implemented and would hide content outright, and "H2 for rib headers" named an element ADR-102 removed. A map has exactly one heading.
- [x] ~~Tighten the STYLE-GUIDE's deliberately-hedged wording to describe disk state~~ — done. Both halves were stale, not just the tense: it named `docs/story-maps/README.md` as a live template source (retired by ADR-102) and disclaimed describing disk state when disk state is in fact compliant. The § Colours non-text-contrast bullet also still said the rule "binds hardest on `.slice`, whose border is the only resting signal that the card is a link" — post-ADR-102 `.slice` is a `<th scope="row">` and not a link at all; it now binds `.task`.
- [ ] Consider whether a `docs/story-maps/**/*.html` check belongs in CI — on the merits of guarding a rendered artefact adopters read, NOT on the struck premise that this project ships accessibility plugins.
- [x] ~~**Defect 4**: give the reference links a resting non-colour cue and re-sync the shared copy~~ — done. `a { color: var(--focus); text-decoration: underline; }` at `story-map.css:59`, stated on the bare `a` selector rather than `.ref-link` (see the correction under Defect 4). Copy re-synced by re-rendering a map through `wr-itil-render-story-map`, so `ensureSharedAssets()` owns the sync rather than a hand edit; verified byte-identical with `diff`.
- [x] ~~Add an in-prose-reference-link rule to STYLE-GUIDE.md~~ — done, filed under § Colours rather than § Interaction states. Placement was the reviewer's call and it matters: this is an **at-rest** rule, and filing it beside the hover rule would re-manufacture the exact category confusion that produced the wrong first reading of line 92. The hover rule gained a clause naming itself a card rule so the two cannot be conflated again.
- [ ] Decide the `<ul role="list">` + `subgrid` semantic upgrade for `.rib` — **out of scope for any AFK iteration**; see Outstanding Questions. Needs an ADR and a human.
- [x] ~~Encode the `display: contents` permissibility rule in STYLE-GUIDE.md~~ — done, under § Layout, with a note that nothing currently uses it (`.rib` was removed by ADR-102) so a reader does not hunt for a class that is gone.
- [x] ~~**Defect 5 (SC 2.4.11, Level AA)**: focus obscured by the sticky row-header column~~ — see below. `scroll-padding-left: 104px` on `.scroll`.
- [ ] `thead th.act`'s sticky pinning (`story-map.css` § sticky headers) is **inert**, and its comment describes behaviour that does not happen. `.scroll` has `overflow-x: auto`, which computes `overflow-y` to `auto` and makes `.scroll` the sticky containing block; it has no height constraint, so `top: 0` never engages. Functional/visual rather than an accessibility failure — the row header, which is the one that survives the scroll axis that moves further, does work. Separable fix; needs a design call on whether to constrain the scrollport height.


### Defect 4 — reference links inside prose are distinguished by colour alone (SC 1.4.1, Level A) — CURRENT shipped CSS

Added 2026-08-21. Distinct from defect 1 in criterion, element, and conformance level, and **not** closed by ADR-102: defect 1 is `.slice` *borders* (SC 1.4.11, non-text contrast, Level AA); this is `.ref-link` *text links* (SC 1.4.1 Use of Color, Level **A**), live in the currently-shipped `packages/itil/templates/story-map.css`.

- `packages/itil/templates/story-map.css` contains **no `text-decoration` rule anywhere** — verified by grep over the whole file. Links carry `a { color: var(--focus); }` (line 50) and nothing else.

  **Correction, 2026-08-21 (fix iteration).** The clause that followed — "there is no underline at rest and none on `:hover`" — was wrong, and the distinction changes the severity rather than the fix. Because *nothing removes it*, the UA stylesheet's own `a { text-decoration: underline }` is still in force: rendered maps do carry an underline today. So this was never a **live** F73 failure; it was an **unpinned** one. Any future `text-decoration: none`, CSS reset, or `normalize` import silently reintroduces it, and — as the ratios below show — there is no colour-contrast escape hatch to land on when it does. The fix is unchanged (state the rule explicitly); what changes is that this is a latent Level A exposure being closed, not an active one being repaired. The Impact re-rate from 2 to 3 on the strength of "live in the currently-shipped CSS" is left standing on the separate evidence of defect 5, which *is* live.
- The `.ref-link` class that `render-story-map.mjs` line 563 puts on every reference anchor is **styled nowhere** in the stylesheet.
- Those anchors render *inside blocks of text*, which is what makes this Level A rather than a judgement call — e.g. `closes <a class="ref-link">P155</a>, <a class="ref-link">P170</a>` and `Traces: <a class="ref-link">STORY-018</a>`. This is WCAG failure technique **F73** (link not visually evident without colour vision).
- Link-vs-surrounding-text contrast, computed from the shipped tokens, is roughly half the 3:1 that technique G183 requires for a colour-only differentiator:

  | Theme | Link (`--focus`) | Surrounding text | Ratio | G183 floor |
  |-------|------------------|------------------|-------|------------|
  | Light | `#0b3a66`        | `--fg` `#1a1a1a`    | 1.50:1 | 3:1 |
  | Dark  | `#97c6f5`        | `--fg` `#f2f3f5`    | 1.62:1 | 3:1 |
  | Light | `#0b3a66`        | `--muted` `#565656` | 1.58:1 | 3:1 |
  | **Dark**  | **`#97c6f5`**    | **`--muted` `#b6bac2`** | **1.09:1** | 3:1 |

  All four recomputed independently during the fix and confirmed. **The last row is the one that matters and the ticket originally missed it**: the in-prose links do not sit on `--fg` text at all — `.t-ref`, `.s-problems` and `.traces` are all `--muted` containers, and those are exactly where `closes P160` / `Traces: STORY-018` render. At 1.09:1 the link and its neighbours are all but the same lightness in dark mode. So the colour-only allowance is not merely missed, it is missed by a factor of three at the worst case.

  Corollary for the fix's shape: the rule went on the bare `a` selector, not on `.ref-link`. The two are coextensive today — `render-story-map.mjs` line 563 is the only anchor emitter — but the colour that creates the exposure is declared on `a`, so co-locating the compensating channel keeps them from drifting apart, and any second anchor emitter added later inherits both. `.ref-link` is also used as a whole-element card-title link, where an underline is not what carries the affordance, which is a further reason not to key the rule to it.
- `docs/story-maps/story-map.css` is byte-identical to the template, so every rendered map on disk and every adopter render carries it.
- Our own `docs/STYLE-GUIDE.md` line 92 already mandates the non-colour cue (`text-decoration: underline`) — the story-map stylesheet simply does not implement the rule the guide states.

**No style-guide conflict — checked, and the first reading of this was wrong.** STYLE-GUIDE.md line 92 sits under "### Interaction states" and reads "pair the *border-colour change* with a non-colour cue": it governs **card** hover, where the border is the card's only resting affordance (`.slice`, now `.task`). It does not govern in-prose text links and does not forbid an at-rest underline on `.ref-link`. The guide has **no rule at all** for in-prose reference links — a gap, not a contradiction — so underline-at-rest is compatible with the guide as written and needs no deviation approval. Filling the gap is a mechanical extension consistent with the surrounding rules.

(addressr's own hover-vs-rest question is genuine *for their slice cards*, which is the case line 92 does cover. It does not transfer to `.ref-link`.)

### Defect 5 — focus is obscured by the sticky row-header column (SC 2.4.11, Level AA) — CURRENT shipped CSS

Found 2026-08-21 during the defect-4 fix, independently by `keyboard-navigator` and `contrast-master` under `accessibility-agents:accessibility-lead`. Unlike defect 4 this one is **live**, which is why the ticket's Impact 3 stands.

`table.map` carries `min-width: 940px`, so below that width the `.scroll` wrapper scrolls horizontally. `th.slice` is sticky-left with an **opaque** `background: var(--bg)` and `z-index: 2`, painting over the leftmost ~96px of the scrollport. There was no `scroll-padding-left` anywhere in the file. Browsers' focus-driven scroll-into-view is not sticky-aware: it aligns the focused element flush with the scrollport's left edge — underneath the header. The `.t-ref` reference links render at `.75rem` and are roughly 30-70px wide, narrower than the column, so they are hidden **entirely** rather than partially. Entirely is the Level AA threshold (2.4.11); partial obscuring would only engage 2.4.12 at AAA.

Fixed with one property on `.scroll`: `scroll-padding-left: 104px` — the 96px column plus the 3px focus ring, its 2px offset, and clearance. No media-query variant is needed: the column is `width: 10%`, which is 94px of the 940px minimum, so its 96px `min-width` governs at every width that scrolls, including under the 640px override where `min-width` drops to 72px and the 94px percentage takes over. Both are under 104px.

Verification is by construction rather than observation — confirming it needs a render below 940px with a focused `.t-ref` link, which this iteration had no browser for.

**Rule worth encoding from addressr's review:** `display: contents` is permitted only on an element whose computed role is `generic`, with no `role`, no `aria-*`, no accessible name, no focusability, and no part in a required-owned-element chain.

## Outstanding Questions

1. **[direction]** Should `.rib` become `<ul role="list">` with `grid-template-columns: subgrid`? Routed upstream by adopter `addressr` explicitly as "an ADR against the framework, not a local decision", and `wr-architect:agent` agrees it needs its own ADR and a human. Note the question has partly moved since it was asked: ADR-102 removed `.rib` and the CSS-Grid backbone outright, so the live question is whether the **`<table class="map">` grid** should carry list semantics for its card columns, not whether `.rib` should. **Not decidable in an AFK iteration.**

2. **[direction]** How should ADR-060's superseded inlined encoding example be retired? ADR-116 bars editing the ratified body, so the options are a supersede-in-part ADR on the ADR-115 pattern (`Supersedes: [ADR-060 (in part — Phase 2 HTML encoding only)]`), or leaving it as historical record now that the STYLE-GUIDE labels it as such. Belongs to P483's supersession sweep; needs human ratification.

3. **[direction]** Should P466 carry a secondary JTBD anchor to JTBD-303 (generated output respects adopter conventions) for the adopter-install axis — this fix reaches `addressr` through a package upgrade, not a local patch? Raised by `wr-jtbd:agent`, which also warned **against** moving the header anchor now: JTBD-303 is unratified, so citing it in the header would fire the `[Unratified Dependency]` guard with no human present to clear it. Recorded as a question deliberately, since a question is not a build-upon. Ratify via `/wr-jtbd:confirm-jobs-and-personas` first.

4. **[direction]** Should the JTBD corpus document an accessibility/perceivability outcome for rendered artefacts, and should `developer` / `tech-lead` / `plugin-user` gain assistive-technology context constraints? `wr-jtbd:agent` grepped all 18 jobs and 4 personas for `accessib|WCAG|contrast` and found exactly one hit, about skill discoverability — no persona records keyboard-only, low-vision or colour-vision-deficiency context, in this repo's corpus. (The original wording justified this with "in a repo whose own product line is accessibility tooling" — struck 2026-08-21, false; the question stands or falls on whether rendered artefacts deserve a perceivability outcome at all, not on a product-line claim.) It ruled this a depth gap in a covered flow rather than a blocker, so it did not hold this fix; but it is the reason defects 4 and 5 had no job to surface them.

## Fix Released

Released in `@windyroad/itil@1.1.2` on 2026-08-21, via changeset `itil-story-map-link-and-focus-cues.md`.

Awaiting user verification that the fix behaves as intended in the installed package.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: (none)

## Related

- `docs/STYLE-GUIDE.md` § Colours (non-text contrast) + § Interaction states — added 2026-07-26 in the P430 commit; both sections name this sweep as their outstanding follow-up, so leaving it uncaptured would make the guide's own pointer dangle.
- `packages/itil/templates/story-map.html` — the canonical template every map is now rendered from.
- Captured via `/wr-itil:capture-problem`; expand at next investigation.
