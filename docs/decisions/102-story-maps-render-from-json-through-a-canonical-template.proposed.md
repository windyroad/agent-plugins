---
status: proposed
date: 2026-08-05
decision-makers: Tom Howard
human-oversight: confirmed
oversight-date: 2026-08-05
oversight-note: "2026-08-05 — confirmed as written via AskUserQuestion after a post-change brief (P357). The user confirmed the chosen option and all three amendments: the grid encoding replacing stacked sections, the ratification fingerprint moving onto the data island so a restyle cannot revoke an approval, and the renderer shipping via the bin shim rather than ${CLAUDE_SKILL_DIR}, which is empirically unset. The reversal recorded in Decision Outcome — two files chosen first, built, then rejected as too easy to diverge — was surfaced in the brief rather than quietly rewritten."
amends: ADR-060, ADR-090, ADR-049
---

# ADR-102: Story maps render from JSON through a canonical template

## Context and Problem Statement

`/wr-itil:capture-story-map` ships an HTML skeleton that is not a story map. A user story map in Patton's sense is a two-dimensional grid: activities run across the top as columns forming the user journey (the backbone), release slices run down the side as rows, and task cards sit in the cells. Reading a row left to right tells you everything that ships together.

The shipped skeleton emits a vertical stack of `<section class="backbone">` blocks, each holding one heading. No columns, no release dimension, no cells. Nine of the twelve maps in this repository carry that shape, including STORY-MAP-001, which the template's own CSS comment names as the live exemplar. The defect ships to adopters: every map the skill generates is a bulleted list wearing map vocabulary.

**Correction, 2026-08-05, after ratification.** An earlier draft of this section claimed all thirteen maps had that shape, inferred from none of them containing `table class="map"`. That inference was wrong and the claim was overstated. STORY-MAP-002 is a genuine two-dimensional map — five activities by three release bands, CSS-grid encoded — and STORY-MAP-003 has five activities with no release dimension. Neither is the stacked shape; both simply use an encoding the grep did not look for. The decision below is unaffected: the *shipped template* was genuinely degenerate, which is what the renderer replaces. But the generative-cause paragraph is narrower than first written — cloning STORY-MAP-011 propagated the defect, while cloning STORY-MAP-002 would not have. The real hazard is that the corpus offered several incompatible shapes with no way to tell which was canonical, which is precisely what a renderer settles.

The generative cause is that the skill has no internal notion of what a story map is. Its SKILL.md carries markup inline and the authoring agent reaches for a sibling map to infer shape — and the corpus answers with three incompatible shapes and no marker saying which is canonical. An agent that clones the shipped skeleton, or one of the nine maps grown from it, produces a non-map while following the documented process correctly.

## Decision Drivers

- The skill must know what a correct map is without inspecting the repository it runs in. Exemplar-cloning is what let nine maps grow from a wrong skeleton while two others diverged into their own shapes.
- Presentation must live in exactly one place, so a fix reaches every map.
- Authoring must be data entry, not markup authoring. An agent hand-writing a grid will drift from it.
- The existing story-reference layer is load-bearing and must survive: `data-story-id` is consumed by reverse-trace computation (`update-story-references-section.sh`) and by story-map queries. (The ADR-101 consumers named here originally — the AFK-accept carve-out and `check-afk-accept-eligible.sh` — were retired with ADR-103 and no longer read it.)
- Human ratification must survive presentation changes. Under ADR-090 the oversight marker is drift-invalidated against file content; if rendered HTML is the hash basis, restyling the template mass-unratifies every map.
- Scripts must resolve in adopter installs, not only in source-repo dogfooding (the recurring P151 / P153 / P219 / P317 class).

## Considered Options

- **A. Two files per map** — a `.json` source of truth and a generated `.html` committed beside it.
- **B. One self-contained `.html`** carrying its data in an embedded `<script type="application/json">` island, with the renderer rewriting presentation around the island in place.

## Decision Outcome

**Chosen option: B, one self-contained file per map.**

A story map is a single `docs/story-maps/<state>/STORY-MAP-NNN-<slug>.html`. Its authored data lives inside it, in a `<script id="story-map-data" type="application/json">` island; the renderer reads that island and rewrites the presentation around it in place.

**There is one mode.** To create a map, write a file containing nothing but the data island and render it — the renderer fills in everything around it. To change a map, edit the island in place and render again. Creation and editing are the same command on the same file, so there is no seed file, no bootstrap flag, and no second code path to keep in step with the first. An earlier draft of this decision carried a `.json` seed accepted once at creation; it was removed as an unnecessary mode.

**This reverses an earlier choice in the same session, and the reversal is the substance.** Option A (a `.json` source plus a generated `.html` sibling, both committed) was chosen first via `AskUserQuestion` on 2026-08-05 and implemented. On seeing it, the user rejected it: *"I'm not a fan of the two file approach. Too easy for them to diverge."* That is the correct reading, and it matches the architect's original advisory lean, which this ADR had recorded and then not followed.

Two files per map create a divergence class with no structural defence. Nothing stops someone editing the rendered `.html` — it is the file you open to read the map — and that edit is silently destroyed on the next render. The single-file shape removes the failure mode rather than documenting it: there is no second artefact to fall out of step, and the file you read is the file you edit.

It also converts the ADR-090 hash problem below from something the tooling must remember into a property of the format. Because the island is separable, the ratification fingerprint can be scoped to the data alone — so restyling every map in the corpus provably cannot revoke a human approval. Under option A that guarantee had to be maintained by hand.

**Amended 2026-08-06 — the grid is drawn at view time, and status is derived.** Two changes, both taken after the ratified decision above was in use, and both removing duplication rather than adding capability.

*Status is no longer authored.* A card carried `storyStatus`, duplicating the story file's own `status:`. That imposed a sync obligation on every transition, produced a drift class that put three of eight maps out of date, and churned ratification — ticking a story to done is progress, not a revision of what a human approved, yet a stored value drifted the map's fingerprint. The renderer now reads each story's current state from its own file, so a transition needs no map edit at all and the fingerprint does not move.

*Presentation is no longer committed.* A map's markup was regenerated into every file, so 59% of the corpus was derived and one stylesheet was duplicated byte-for-byte eight times — a template tweak rewrote eight files and produced ~920 lines of identical CSS diff. A map is now a shell plus its data block; `story-map.css` and `story-map.js` sit beside the maps as single copies, kept in step by the renderer, and the grid is built in the browser from the data. The corpus went from 3,037 lines to 1,626, and derived content from 1,814 to 403.

Consequences of the second change, stated plainly. The grid is unreachable without script, which the server-rendered version did not require; a `<noscript>` note names the data block as the fallback. Maps are no longer self-contained — a file copied away from its siblings loses its presentation, and the story-map encoding's prohibition on external stylesheets is superseded for this reason. Tooling that grepped rendered markup for `data-story-id` now finds the island's `"storyId"` instead; `update-story-references-section.sh` and `story-oversight.sh` match both. Tests assert on a jsdom render rather than the file's bytes, which is why `jsdom` is a devDependency.

A markdown-table encoding was weighed against this and rejected by the user in favour of keeping the visual grid. It would have been ~34 lines per map with no tooling at all, and it renders on GitHub where the HTML does not.

Trade-off accepted: the renderer is read-modify-write rather than a pure emit, and the data island can in principle be hand-edited into invalid JSON. The renderer fails loudly on that rather than silently, and re-rendering is idempotent and round-trip-tested.

One authoring constraint follows from the encoding: a raw `</script>` inside the island terminates it early, in this renderer and in any browser. The renderer escapes the angle bracket on write, so a rendered map is always safe; a hand-authored island must do the same. The renderer errors rather than emitting a silently truncated map, and both halves are covered by test.

### Amendment to ADR-060 (Problem-RFC-Story framework), Phase 2 HTML encoding

The normative encoding changes from stacked `<section class="backbone">` with `<h2 data-rib>` and `<a class="slice">`, to a grid:

- `<table class="map">`; `<thead>` carries one `<th class="act" scope="col">` per backbone activity.
- Each release slice is a `<tr>` whose row header is `<th class="slice" scope="row">`.
- Cells are `<td class="cell">`; an activity/release pair with no tasks renders `<td class="cell empty">`.
- Task cards keep the story-reference layer: `data-story-id`, `data-rfc`, `data-jtbd`, `data-status` are carried on the card element, exactly as before. The grid is additive to the reference layer, never a replacement for it.
- Each story-bearing card is emitted on a **single line**. This was originally a correctness constraint: `story-oversight.sh` filtered whole lines, so a multi-line card drifted the hash and made ADR-101's carve-out unsatisfiable. **Under ADR-103 that reason is void** — cards are outside the fingerprint basis entirely. The rule is retained as a readability convention: one card per line keeps a map's diff reviewable.
- The `<meta>` trace block is preserved verbatim, including `human-oversight` and `oversight-hash`, so `reconcile-story-maps.sh` and `render-story-map-index.sh` are unaffected.
- The ADR-060 prohibition on inline `style` attributes on data-bearing elements is retained and extended: presentation belongs only in the template's `<style>` block. The reference map that informed this shape carries `style="margin-top:.35rem"` on a row-header span; the renderer must not reproduce that.

### Amendment to ADR-090 (drift-invalidated oversight marker)

The oversight hash basis moves from the whole rendered file to the **data island alone**. `oversight_content_hash` and `oversight_content_hash_excluding_stories` are re-based onto the contents of `<script id="story-map-data">`.

Without this, regenerating maps after any template change drifts every stored fingerprint and silently revokes human ratification across the corpus — which then blocks RFCs through `check-rfc-stories-ratified`. A presentation change must never revoke a substance approval. This requires a deliberate one-time re-hash of existing maps at migration, not an incidental one.

### Amendment to ADR-049 (plugin script resolution)

The renderer ships as `packages/itil/scripts/render-story-map.mjs` with a `wr-itil-render-story-map` shim on `$PATH`, per the existing shim grammar, and the template ships beside it.

`${CLAUDE_SKILL_DIR}` was considered, following `packages/c4/skills/generate/SKILL.md`, which invokes `node ${CLAUDE_SKILL_DIR}/scripts/c4-generate.mjs`. It was rejected: the variable is empirically unset, which is the same finding that drove ADR-049 to the `bin/` route for `${CLAUDE_PLUGIN_ROOT}` on 2026-05-02. ADR-049's reassessment criterion — revisit if a correctly populated equivalent ships — is therefore **not** met. The c4 skill's reliance on it is a suspected adopter-facing defect and is captured separately rather than replicated here.

## Consequences

- Good: presentation is fixed in one file, so correcting a map's shape corrects every map.
- Good: the authoring agent never writes markup and never reads a sibling map for shape, which removes the drift channel that produced this defect.
- Good: a map stays viewable in a browser straight from the repository, with no build step and no second file for a reader.
- Good: there is no second file to diverge. The file a reader opens is the file an author edits, and the divergence class option A carried does not exist.
- Bad: the renderer is read-modify-write rather than a pure emit, and a hand-edit can leave the island as invalid JSON. The renderer fails loudly rather than silently, and idempotence is asserted by test.
- Bad: the 13 existing maps become non-conformant on encoding. They remain parseable — every affected consumer matches `data-story-id` or the `<meta>` block, neither of which is container-dependent — so a mixed corpus is safe during migration.
- Neutral: SKILL.md sheds its inline markup, which returns roughly 45 lines of runtime budget under ADR-054.

## Confirmation

- A fixture JSON rendered through `render-story-map.mjs` emits backbone activities as `<th class="act" scope="col">` and release slices as `<th class="slice" scope="row">`, with cell count equal to activities × releases. Cell count is the assertion that distinguishes a grid from a stack; a single-column table would satisfy a naive "contains a table" check.
- A task declared at a given activity and release renders inside that cell and nowhere else; an empty pair renders `class="cell empty"`.
- Each story-bearing card emits `data-story-id` on a single line.
- Round trip: `update-story-references-section.sh <map> "Story Maps"` resolves a story rendered into a generated map. This proves reverse-trace survives the encoding change and is worth more than the shape assertions combined.
- Re-rendering an unchanged source is byte-identical, and `oversight_content_hash` is stable across a presentation-only template change.
- A guard asserts the renderer never emits the old stacked shape, so the defect cannot silently return.

## Reassessment

Reassess if Claude Code ships a populated skill-directory variable, which would allow the renderer to move skill-local and simplify packaging; or if hand-edits to the data island prove error-prone enough in practice to warrant a validating editor command.
