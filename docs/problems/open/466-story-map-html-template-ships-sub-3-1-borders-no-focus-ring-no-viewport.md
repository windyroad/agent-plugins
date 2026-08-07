# Problem 466: The story-map HTML template ships sub-3:1 borders, no focus ring, and no viewport meta

**Status**: Open
**Reported**: 2026-07-26
**Priority**: 6 (Medium) — Impact: 2 (Minor — internal governance artefacts, no adopter runtime surface, but they are HTML this project asks people to read and the project sells accessibility work) × Likelihood: 3 (Possible — every new map copies the defective template; four of five on-disk maps already carry it) — derived at capture from the description per Step 4a
**Origin**: internal
**Effort**: S — mechanical CSS edits across two template sources and four map files, plus one grid fix — cf. P429 (S)
**JTBD**: JTBD-008
**Persona**: developer

## Description

The canonical story-map HTML template — inlined in ADR-060 (line 408) and mirrored in `docs/story-maps/README.md` (line 59) — teaches a `<style>` block that fails several WCAG 2.2 criteria, and four of the five maps on disk have copied it.

Three defects, all inherited rather than independently introduced:

1. **Non-text contrast (SC 1.4.11)**. `.slice { border: 1px solid #ccc; }` is 1.6:1 on white, against a 3:1 floor. This is load-bearing rather than decorative: `.slice` also sets `text-decoration: none; color: inherit`, so the 1px border is the *only* resting signal that the card is a link. Actual on-disk values are `#ccc` (STORY-MAP-001, STORY-MAP-004), `#c9d2de` (STORY-MAP-002), and `#c4c4c4` / `#cfcfcf` (STORY-MAP-003) — all sub-3:1.
2. **No focus indicator**. The template has `.slice:hover` but no `:focus-visible` counterpart, so a keyboard user gets no indication of which card is focused. STORY-MAP-003 solved this independently with `outline: 3px solid var(--focus)`; the template never learned it.
3. **No viewport meta (SC 1.4.10 Reflow)**. Without it, mobile browsers assume a ~980px layout viewport and scale down, forcing two-dimensional scrolling. STORY-MAP-003 has it; the template and the other maps do not.

A fourth, narrower defect sits on one map: STORY-MAP-001 combines `--cols: 4` / `--cols: 3` with `grid-template-columns: repeat(var(--cols), 1fr)` and no viewport meta. A `1fr` track has a `min-content` floor, so those columns never collapse and the grid overflows horizontally at 320px — a live 1.4.10 failure rather than a latent one.

Related but separable: `docs/STYLE-GUIDE.md`'s story-map class vocabulary is incomplete. `.map-note` was added on 2026-07-26, but STORY-MAP-003's `.task`, `.legend`, `.badge`, `.b-live`, `.b-next`, and `.b-later` remain uncatalogued, so the guide does not describe what is actually on disk.

## Symptoms

- 2026-07-26 (P430 iter): authoring STORY-MAP-005 from the STORY-MAP-004 shape drew a FAIL from `wr-style-guide:agent` on the inherited `#ccc` border and a further FAIL on the focus value, then five findings from `accessibility-agents:accessibility-lead` (missing viewport, imperceptible hover step, no `<main>` landmark, no `color-scheme`, opaque `.md` link target). STORY-MAP-005 was authored to the corrected values and `docs/STYLE-GUIDE.md` gained the three governing rules, but the template sources and the four pre-existing maps were left untouched — so the next author who reads the template rather than the guide re-inherits all of it.

## Workaround

Superseded by ADR-102 (2026-08-05): maps are no longer copied from an exemplar at all. `packages/itil/templates/story-map.html` is the single source of the shape and `wr-itil-render-story-map` builds every map from it, so the inherited-values failure mode this ticket describes is closed at the source.

## Impact Assessment

- **Who is affected**: anyone reading a story map, most sharply keyboard and low-vision users; also the project's own credibility, since it publishes accessibility tooling.
- **Frequency**: every new map authored from the template.
- **Severity**: Medium — no runtime breakage, but it is a documented standards failure in artefacts the project asks people to read, and it self-propagates.

## Root Cause Analysis

### Investigation Tasks

- [ ] Fix the two template sources first (ADR-060 line 408 and `docs/story-maps/README.md` line 59) — they are the propagation vector; fixing maps without fixing templates re-opens this.
- [ ] Sweep the four existing maps to `#767676` borders, add `:focus-visible` (`3px solid #0b3a66`, offset 2px), add viewport meta, and pin the canvas with `:root { color-scheme: light; }` where no dark-mode counterpart exists.
- [ ] Fix STORY-MAP-001's grid overflow — `repeat(auto-fit, minmax(min(100%, 14rem), 1fr))` or an explicit narrow-viewport collapse.
- [ ] Catalogue `.task` / `.legend` / `.badge` / `.b-live` / `.b-next` / `.b-later` in the STYLE-GUIDE class vocabulary, or retire them from STORY-MAP-003.
- [ ] Once the sweep lands, tighten the STYLE-GUIDE's deliberately-hedged wording (it currently says the rule is "normative for new work, not a description of what is currently on disk") to describe disk state.
- [ ] Consider whether a `docs/story-maps/**/*.html` check belongs in CI, given the project ships accessibility plugins.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: (none)

## Related

- `docs/STYLE-GUIDE.md` § Colours (non-text contrast) + § Interaction states — added 2026-07-26 in the P430 commit; both sections name this sweep as their outstanding follow-up, so leaving it uncaptured would make the guide's own pointer dangle.
- `packages/itil/templates/story-map.html` — the canonical template every map is now rendered from.
- Captured via `/wr-itil:capture-problem`; expand at next investigation.
