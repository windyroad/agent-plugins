---
name: wr-itil:capture-story-map
description: Lightweight story-map-capture skill for aside-invocation during foreground work — mandatory leading problem-trace AND JTBD-trace per ADR-060 I3 + I4 invariants, skeleton HTML file at `docs/story-maps/draft/STORY-MAP-NNN-<slug>.html` per ADR-060 § Phase 2 encoding amendment 2026-05-12, single commit per capture, no inline README refresh. Defers full backbone/ribs/slices authoring + lifecycle transitions to /wr-itil:manage-story-map. Use when the user (or agent) wants to capture a new story-map quickly with clear problem + JTBD anchoring.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# Capture Story Map Skill

Capture a story-map (HTML artefact representing Patton's backbone × ribs × slices layout) quickly during foreground work. Lightweight aside-invocation surface that complements the heavyweight `/wr-itil:manage-story-map` flow. Mirrors `/wr-itil:capture-story` shape per ADR-032 lightweight + heavyweight skill split, applied at the story-map tier with HTML encoding.

**Related JTBDs**: JTBD-008 (primary — Decompose a Fix Into Coordinated Changes; story-maps represent the journey-context decomposition), JTBD-001 (extended scope), JTBD-302 (README-currency rule for `docs/story-maps/README.md`).

## When to invoke

- **Decomposing a problem or RFC into a journey-shaped layout** — agent / user observes that the fix decomposes into multiple coordinated changes that map onto a user-journey backbone × ribs × slices spatial layout (per Patton's User Story Mapping). Capture the story-map BEFORE individual stories so the spatial-placement context informs story decomposition.
- **Retrospective story-map for shipped work** — lifting an existing multi-commit decomposition into a story-map artefact (e.g. STORY-MAP-001 retro on P170 Phase 1 + Phase 2 framework code — Slice 14 of P170 Phase 2).
- **Cross-RFC journey lens** — a single story-map can reference stories from multiple RFCs (the map is a journey-context lens on the story corpus per ADR-060 line 317).

**Use `/wr-itil:manage-story-map` instead** when:
- The work is moving an existing story-map through its lifecycle (draft → accepted → in-progress → completed → archived).
- The user wants to author or refine the backbone/ribs/slices structure with full intake.
- Cross-map coordination decisions need to be captured.

## Argument grammar

**Positional (both mandatory)**: `<problem-trace> <jtbd-trace> <description>` where:
- `<problem-trace>` is `P<NNN>` or `P<NNN>,P<NNN>,...`
- `<jtbd-trace>` is `JTBD-<NNN>` or `JTBD-<NNN>,JTBD-<NNN>,...`

```
/wr-itil:capture-story-map P170 JTBD-008 RFC framework Phase 1 + Phase 2 bootstrap
/wr-itil:capture-story-map P170 JTBD-008,JTBD-001 Story map for the P170 RFC framework work
```

Positional grammar mirrors `/wr-itil:capture-story` shape (footnote per ADR-060 line 285 phrasing — `--problem` / `--jtbd` flag-form was the ADR-exemplar but positional is the lightweight-aside grammar that Claude Code skills support natively).

## Rule 6 audit (per ADR-032 + ADR-013 + ADR-060)

| Decision | Resolution | Authority class |
|----------|-----------|-----------------|
| Problem-trace presence | I3 hard-block — refuse on missing trace; emit deny log + halt | direction-setting |
| Problem-trace validation | Mechanical: each `P<NNN>` exists in `docs/problems/`; dual-tolerant lookup | silent-mechanical |
| JTBD-trace presence | I4 hard-block — refuse on missing trace; emit deny log + halt | direction-setting |
| JTBD-trace validation | Mechanical: each `JTBD-<NNN>` resolves to a file in `docs/jtbd/` | silent-mechanical |
| STORY-MAP ID allocation | Mechanical: `max(local, origin) + 1` enumerating `docs/story-maps/*/STORY-MAP-*.html` (ADR-019 inline collision-guard) | silent-mechanical |
| Title kebab-slug | Mechanical: first 8-10 non-stopword tokens of description | silent-mechanical |
| Title prose refinement | Optional taste AskUserQuestion; silent-default to derived form | taste |
| HTML file write | Mechanical: schema per ADR-060 § Phase 2 encoding amendment 2026-05-12 lines 381-435 | silent-mechanical |
| Reverse-trace `## Story Maps` refresh | Mechanical: inline on driving problem + JTBD files via Slice 2a/2b helpers | silent-mechanical |
| README refresh | Mechanical: deferred to `/wr-itil:manage-story-map review` or `wr-itil-reconcile-story-maps` | silent-mechanical |
| Empty arguments | Halt-with-stderr-directive | n/a |

## Steps

### 0. Preflight

```bash
wr-itil-reconcile-readme docs/problems > /tmp/wr-itil-drift-$$.txt
reconcile_exit=$?
# Halt-and-route on drift per the standard pattern.
```

### 1. Parse arguments

```bash
problem_trace="$1"; shift
jtbd_trace="$1"; shift
description="$*"
```

Validate `$problem_trace` matches `^P[0-9]{3}(,P[0-9]{3})*$`. Validate `$jtbd_trace` matches `^JTBD-[0-9]{3}(,JTBD-[0-9]{3})*$`. If `$description` is empty, halt with empty-arguments directive.

Derive kebab-case title slug from first 8-10 non-stopword tokens of `$description`.

### 2. Validate problem trace + I3 hard-block

For each `P<NNN>`:

```bash
# Dual-tolerant ticket discovery (RFC-002 migration window).
trace_files=$(ls docs/problems/<NNN>-*.md docs/problems/*/<NNN>-*.md 2>/dev/null)
```

**I3 hard-block** (ADR-060, the story-map schema's `problems:` field): trace absent / malformed / unresolved → emit deny log entry to `logs/story-map-capture-denials.jsonl`, halt with stderr directive naming `/wr-itil:capture-problem` as the open-the-driving-problem-first surface.

### 2.5. Validate JTBD trace + I4 hard-block

For each `JTBD-<NNN>`:

```bash
jtbd_file=$(ls docs/jtbd/*/JTBD-<NNN>-*.md 2>/dev/null | head -1)
```

**I4 hard-block** (ADR-060, the story-map schema's `jtbd:` field): trace absent / malformed / unresolved → emit deny log + halt. Story-maps without JTBD trace are structurally meaningless per ADR-060 ("a map with no JTBD trace is structurally meaningless"; Patton's central thesis is journey-around-user-value).

### 3. Compute next STORY-MAP ID

Inline `max(local, origin) + 1` per ADR-019 collision-guard (architect Slice 3 design review option a — inline-only path, mirrors capture-rfc + capture-story precedent):

```bash
local_max=$(ls docs/story-maps/*/STORY-MAP-*.html 2>/dev/null | sed 's|.*/STORY-MAP-||;s|-.*||' | grep -oE '^[0-9]+' | sort -n | tail -1)
origin_max=$(git ls-tree -r --name-only origin/main docs/story-maps/ 2>/dev/null | sed 's|.*/STORY-MAP-||;s|-.*||' | grep -oE '^[0-9]+' | sort -n | tail -1)
next=$(printf '%03d' $(( 10#$(echo -e "${local_max:-0}\n${origin_max:-0}" | sort -n | tail -1) + 1 )))
```

### 4. Optional taste prompt for title

Same shape as capture-story Step 4 — silent-default when unavailable.

### 5. Write the story-map JSON, then render it

**NEVER hand-write the HTML, and NEVER open an existing map to copy its shape.** Both maps and template drifted together once already: every map in the corpus became a vertical stack of headings — no journey columns, no release rows, no cells — because each new map was cloned from the last. The renderer owns the shape so that cannot recur.

**A map is ONE file**: `docs/story-maps/draft/STORY-MAP-<NNN>-<kebab-title>.html`. Its data lives inside it, in a `<script id="story-map-data" type="application/json">` island. The renderer rewrites the presentation around that island. There is no separate source file to fall out of step with the rendered map, and the file a reader opens is the file an author edits.

**There is one command and one mode.** To CREATE a map, write a file containing nothing but the data island, then render it — the renderer fills in everything around it:

```bash
# Write docs/story-maps/draft/STORY-MAP-<NNN>-<kebab-title>.html containing only:
#   <script id="story-map-data" type="application/json">
#   { ...the map data... }
#   </script>
wr-itil-render-story-map docs/story-maps/draft/STORY-MAP-<NNN>-<kebab-title>.html
```

**To CHANGE a map**, edit the data island in that same file and run the same command again. Creation and editing are the same operation, so there is no seed file to clean up and no bootstrap mode. Re-rendering is idempotent. Never edit the grid, the `<style>` block, or the `<meta>` block by hand — they are regenerated from the island, and a hand-edit outside it is discarded on the next render.

**What a story map is.** A grid, not a list. Backbone activities are COLUMNS across the top and form the user's journey left to right. Release slices are ROWS. Task cards sit in the cells. A row read left to right is everything that ships together — that is the whole point of the artefact, and it is what a vertical stack cannot express.

**JSON shape:**

Extracted verbatim by `test/documented-island-renders.bats` — editing which keys
appear here changes what that test asserts, and that binding is deliberate.

<!-- documented-island:begin -->
```json
{
  "storyMapId": "STORY-MAP-<NNN>",
  "title": "<Title>",
  "status": "draft",
  "persona": "<persona>",
  "reported": "<YYYY-MM-DD>",
  "decisionMakers": "<git config user.name>",
  "traces": { "jtbd": ["JTBD-<NNN>"] },
  "backbone": [
    { "id": "<slug>", "title": "A. <Activity>", "note": "<optional JTBD or gloss>" }
  ],
  "releases": [
    { "id": "rfc-<nnn>", "name": "<what this release delivers>", "rfc": "RFC-<NNN>", "note": "<optional>" }
  ],
  "tasks": [
    {
      "activity": "<backbone id>", "release": "<release id>",
      "title": "<what the persona can do>",
      "storyId": "STORY-<NNN>", "rfc": "RFC-<NNN>", "jtbd": "JTBD-<NNN>",
      "ref": "STORY-<NNN>, P<NNN>"
    }
  ]
}
```
<!-- documented-island:end -->

**Authoring rules:**

- **The backbone must be a journey, not a list of invariants.** Activities are steps the persona walks through in sequence. "Finish a change → get it assessed → push it → get through CI → release it" is a backbone. "Leave no unscored way out", "score this change not the last one" are invariants, and a column of them is not a map.
- At capture a map may legitimately have **columns and rows but empty cells**. That is the honest state of unbuilt work, and the renderer says so in place — a wholly empty band carries its own sentence. Do not add prose at the top explaining it.
- **Composing a row asks two questions, in order.** A row is a release, so putting two stories in one is a claim that they ship together. Answer both before drawing it.

  **1. Do they NEED to ship together?** Coupling. Is either broken, meaningless or misleading on its own? A migration and the code that depends on it need one row. Two fixes that merely arrived in the same conversation do not. *Absence of a dependency is not a reason to bundle* — it is the reason not to.

  **2. SHOULD they ship together?** Economics, and this is the question that gets skipped. Batching imposes the delay of the slowest story on everything in the batch. It buys something back only when each release costs a lot to perform — so weigh the holding cost against the per-release transaction cost:

  - **Producer-side cost is usually near zero here**: release is automated on merge, and this repo has shipped three times in a day. When transaction cost approaches zero the optimal batch approaches one, and bundling is pure loss.
  - **Adopter-side cost is not zero.** Every release asks an adopter to upgrade, and upgrading has known friction. That is the real argument for a larger batch.
  - **Watch for the story that REDUCES that cost.** It ships first and alone. Queueing your transaction-cost reducer behind other work is the expensive mistake, because it makes every later release cheaper — attack the cost, then the batch size falls out.
  - **Cost of delay is per persona, not per story.** A gate blocking most adopters today outweighs an intermittent failure that bites across an upgrade. Name who waits, and what waiting costs each of them, before deciding the row.
  - **Check the package boundary.** Stories in packages that version independently cannot share a release the tooling will actually produce; a row spanning them claims something no changeset emits.

  The default is one story per row. Two stories share a row when the answer to question 1 is yes, or when question 2 shows a transaction cost high enough to pay for the delay. Neither is assumed.

- **A row IS an RFC (ADR-103).** A row a problem has proposed carries its `rfc`; drawing the row is what allocates the identity. There is no separate "not yet allocated" state and no `badge` field — a row's status is derived from its stories, and its label is its RFC id.
- **Every row carries an identity, and finishing one earns no exemption (ADR-107).** A row with no `rfc` renders as a defect — a red "Untraced" badge — whether or not its stories are done. Delivery cannot excuse a missing identity, because every row is delivered eventually; that reading would let work nobody proposed become legitimate by being finished.

  The only exception is a row holding work that shipped **before rows carried identities**, and such a row says so explicitly with `"preRfc": true`. That set is closed. Do not add the marker to a new row: it is a statement about history, not a way to skip allocating an RFC. It appears in no example above because a row that has an `rfc` does not need it, and the example shows the normal case.
- **A map carries no `traces.rfcs` (ADR-107).** The map's RFC list is the union of its row identities, so authoring it restates the rows and drifts from them the moment one changes.
- `storyId` / `rfc` / `jtbd` are optional per task and emit the `data-*` reference layer that reverse-trace and the story-map queries consume. Omit them until stories exist; add them as stories are captured onto the map.
- **Author nothing a story file already says (ADR-104).** A story's lifecycle state, its value statement, and the problems it closes are all read from the story when the map renders — so a transition needs no map edit and does not re-open the map's ratification. There are no `storyStatus`, `value` or row-level `problems` fields, and no `--status` or `--value` flags. A row's problems are the union of its stories'; a map's are the union of its rows'.
- **A map carries no decision trace (ADR-106).** There is no `traces.adrs`. A decision constrains how something is built, and the thing built is the story — so a decision reference belongs on the story (`adrs:` in its frontmatter), not on the lens drawn over it.
- **Write no prose the grid already carries.** There is no `lead` and no `traceProse`. A map is a title, a grid, and the jobs it is drawn for. Where a column or a row needs a note, both carry a `note` field — put it next to the thing it describes, not in a paragraph at the top restating the picture below it. Six kinds of duplication were removed from this format for exactly this reason; the seventh will be whatever gets added back.
- **Prefer the edit command over hand-editing the island** for structural changes — it validates against the map's own backbone and bands, names what is available when you get an id wrong, and leaves the file untouched on failure:

```bash
wr-itil-story-map-edit <map.html> add-card     --story STORY-<NNN> --activity <id> --release <id> --title "..." [--ref "..."]
wr-itil-story-map-edit <map.html> move-card    --story STORY-<NNN> [--activity <id>] [--release <id>]
wr-itil-story-map-edit <map.html> remove-card  --story STORY-<NNN>
wr-itil-story-map-edit <map.html> add-band     --id <id> --name "..." [--rfc RFC-<NNN>] [--note "..."]
wr-itil-story-map-edit <map.html> add-activity --id <id> --title "..." [--note "..."]
```

Hand-editing the island still works — the renderer reads whatever is there — but the command is the safer path and the one to reach for by default.
- Every task needs `activity` and `release` matching an `id` in `backbone` / `releases`, or it renders nowhere.
- Presentation is not yours to set. There is no CSS in the JSON and no inline `style` anywhere; the template is the only styling source.
- Escape a literal `<` in any string as `\\u003c`. A raw `</script>` inside the island terminates the block early — in the renderer and in a browser — and the renderer will refuse the file rather than emit a truncated map.

**Born unconfirmed (ADR-090).** Do NOT author `humanOversight` at all: the renderer treats an absent field as `unconfirmed`, so writing it is writing the default, and the field exists so that `wr-itil-mark-story-oversight-confirmed` can set `confirmed` — which an agent must never hand-write (P348). The `<meta name="human-oversight">` tag is a projection the renderer regenerates from the island; never author it directly (ADR-102). The map is NOT ratified until a human confirms it via `/wr-itil:manage-story-map <NNN> ratify`, which writes `confirmed` + an `oversight-hash` fingerprint through `wr-itil-mark-story-oversight-confirmed`. Until then `wr-itil-detect-unratified-stories-maps` surfaces it and an RFC may not reference its stories (`wr-itil-check-rfc-stories-ratified`).

**What re-opens ratification, and what does not (ADR-103).** A later edit to the map's SUBSTANCE — the map's own substance as ADR-090 defines it — its journey, its identity, and what it traces to; `oversight_map_substance_keys()` is the field list — drifts the fingerprint and silently re-opens ratification. Release rows and the cards in them sit OUTSIDE the basis, so drawing a row or adding a story to one changes nothing. Presentation is outside it too: restyling the shared template cannot revoke an approval. Do NOT hand-write `confirmed` — born-unconfirmed is the load-bearing default.

### 6. Single commit — `## Story Maps` reverse-trace refresh

**Stage list**: the map `.html` (it carries its own data island) AND, on a repository's first map, the shared `docs/story-maps/story-map.css` the renderer places beside them, PLUS driving problem files (refresh `## Story Maps` section via `update-problem-references-section.sh <file> "Story Maps"`) PLUS driving JTBD files (refresh `## Story Maps` section via `update-jtbd-references-section.sh <file> "Story Maps"`). Do NOT stage `docs/story-maps/README.md` (deferred).

```bash
for pid_token in $(echo "$problem_trace" | tr ',' ' '); do
  pid_num="${pid_token#P}"
  problem_file=$(ls docs/problems/${pid_num}-*.md docs/problems/*/${pid_num}-*.md 2>/dev/null | head -1)
  [ -z "$problem_file" ] && continue
  wr-itil-update-problem-references-section "$problem_file" "Story Maps"
  git add "$problem_file"
done

for jid_token in $(echo "$jtbd_trace" | tr ',' ' '); do
  jtbd_file=$(ls docs/jtbd/*/${jid_token}-*.md 2>/dev/null | head -1)
  [ -z "$jtbd_file" ] && continue
  wr-itil-update-jtbd-references-section "$jtbd_file" "Story Maps"
  git add "$jtbd_file"
done

git add docs/story-maps/draft/STORY-MAP-<NNN>-<slug>.html
```

Commit message:

```
feat(itil): capture STORY-MAP-<NNN> <title>

Refs: STORY-MAP-<NNN>
```

### 7. Report

After commit, report:
- New story-map file path + ID.
- Traced problems + JTBDs.
- Trailing pointer: `Run /wr-itil:manage-story-map <STORY-MAP-<NNN>> next to author backbone/ribs/slices structure and advance draft → accepted; refresh docs/story-maps/README.md.`

## Composition with manage-story-map

| Concern | manage-story-map | capture-story-map |
|---------|------------------|-------------------|
| I3 + I4 enforcement | Re-validated at every lifecycle transition | Hard-block at capture-time |
| I5 no-WSJF-leak | Behavioural test asserts no WSJF field at every transition | Already absent at capture (frontmatter has no WSJF) |
| Backbone/ribs/slices authoring | Step 7-9 author the spatial layout | Deferred-placeholder pattern; one rib placeholder only |
| Status transitions | draft → accepted → in-progress → completed → archived | Out of scope (creation only) |
| README refresh | Inline per transition | Deferred to `/wr-itil:manage-story-map review` or `wr-itil-reconcile-story-maps` |
| Commit grain | One commit per intake / per transition | One commit per capture |

## Related

- **ADR-060** — Problem-RFC-Story framework + Phase 2 amendment 2026-05-10 + encoding amendment 2026-05-12.
- **ADR-060 lines 145-189** — story-map tier spec + I3-I5 invariants.
- **ADR-060 lines 381-435** — HTML encoding schema (the source-of-truth for the file template).
- **`docs/STYLE-GUIDE.md`** — story-map HTML style rules (prohibited inline `style=""` on data-bearing elements).
- **`docs/VOICE-AND-TONE.md`** — story-map prose guidance (HTML content section).
- **`docs/story-maps/README.md`** — story-map tier lifecycle index + schema spec.
- **P170** — driver problem ticket.
- **JTBD-008** — Decompose a Fix Into Coordinated Changes. Primary persona-anchor.
- **JTBD-302** — Trust That the README Describes the Plugin I Just Installed (README-currency rule for `docs/story-maps/README.md`).
- **ADR-032** — governance-skill aside-invocation pattern.
- **ADR-049** — bin/ on PATH; `wr-itil-reconcile-story-maps` shim ships in Slice 5.
- **ADR-052** — behavioural-tests default. Bats at `packages/itil/skills/capture-story-map/test/capture-story-map-behavioural.bats`.
- **Capture-story precedent** — `packages/itil/skills/capture-story/SKILL.md` — sibling skill at the story tier; capture-story-map mirrors with story-map-tier extensions (HTML encoding, no optional --rfc / --story-map flags).

$ARGUMENTS
