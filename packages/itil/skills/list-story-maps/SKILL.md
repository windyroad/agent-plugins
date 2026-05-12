---
name: wr-itil:list-story-maps
description: List story-map artefacts from docs/story-maps/ as a markdown table. Read-only display — no edits, no interaction. Renders <meta> block data (problems / rfcs / jtbd / status) from each HTML map per ADR-060 § Phase 2 encoding amendment 2026-05-12.
allowed-tools: Read, Bash, Grep, Glob
---

# List Story Maps

Display the story-map corpus from `docs/story-maps/` as a markdown table. Read-only view per ADR-060 Phase 2; does not edit, transition, or create maps.

Mirrors `/wr-itil:list-stories` precedent (P071 phased-landing split per ADR-010). I5 invariant: story-maps MUST NOT carry WSJF (no Story Rankings table — maps are planning artefacts, not work items per ADR-060 line 145).

## Scope

Story-maps live under `docs/story-maps/<state>/STORY-MAP-<NNN>-<slug>.html`:
- `draft/` — captured (problem + JTBD traces present); pre-acceptance authoring
- `accepted/` — backbone/ribs/slices authored; ready for implementation dispatch
- `in-progress/` — slices being implemented; stories transitioning
- `completed/` — all slices done
- `archived/` — closed without completion

## Argument grammar

No arguments (read-only display).

## Steps

### 1. Check `docs/story-maps/README.md` cache freshness

```bash
readme_commit=$(git log -1 --format=%H -- docs/story-maps/README.md 2>/dev/null)
if [ -z "$readme_commit" ] || \
   git log --oneline "${readme_commit}..HEAD" -- 'docs/story-maps/*/*.html' ':!docs/story-maps/README.md' 2>/dev/null | grep -q .; then
  echo "stale"
fi
```

**Cache fresh**: read `docs/story-maps/README.md` directly. **Cache stale**: live-scan in Step 2.

### 2. Live scan

Enumerate each lifecycle subdir:

```bash
ls docs/story-maps/draft/*.html docs/story-maps/accepted/*.html docs/story-maps/in-progress/*.html docs/story-maps/completed/*.html docs/story-maps/archived/*.html 2>/dev/null
```

For each map file, parse the `<meta>` block to extract: `story-map-id`, `status`, `problems`, `rfcs`, `jtbd`. Use `xmllint --xpath` when available; fall back to `grep` on `<meta>` lines:

```bash
status=$(xmllint --xpath 'string(//meta[@name="status"]/@content)' "$map" 2>/dev/null || \
         grep -oE '<meta name="status" content="[^"]*"' "$map" | grep -oE 'content="[^"]*"' | sed 's/content="//;s/"$//')
```

### 3. Display

Render lifecycle-grouped sections:

```markdown
## Draft

| ID | Title | Problems | RFCs | JTBD |
|----|-------|----------|------|------|
| STORY-MAP-<NNN> | <title> | <P<NNN>...> | <RFC-<NNN>...> | <JTBD-<NNN>...> |

## Accepted / In Progress / Completed / Archived

(same shape; sections omitted when empty)
```

NO WSJF column per I5. NO ranking table per the "story-maps are planning artefacts, not work items" principle (ADR-060 line 145).

### 4. Trailing suggestions

- Draft section non-empty: `Run /wr-itil:manage-story-map <STORY-MAP-<NNN>> accepted to author backbone/ribs/slices and advance the draft.`
- In-progress section non-empty: `Run /wr-itil:list-stories --rfc <RFC-<NNN>> to see the next story under each in-progress map's referenced RFC.`
- All sections empty: `No story maps captured yet. Run /wr-itil:capture-story-map <P-<NNN>> <JTBD-<NNN>> <description> to capture the first.`

## Ownership boundary

Does not modify, rename, or commit files. Cache-stale path performs live scan only; never rewrites `docs/story-maps/README.md` — refresh is `/wr-itil:manage-story-map review`'s ownership.

## Related

- **ADR-060** — Problem-RFC-Story framework; Phase 2 amendment lines 145-189 (story-map tier spec).
- **ADR-060 line 145** — story-maps are planning artefacts; no WSJF (I5).
- **ADR-060 lines 381-435** — HTML encoding schema; `<meta>` block parse target.
- **`docs/story-maps/README.md`** — story-map directory index.
- **`/wr-itil:list-stories`** — sibling read-only display at the story tier.
- **`/wr-itil:list-problems`** — sibling at the problem tier (P071 precedent).
- **JTBD-008** — Decompose a Fix Into Coordinated Changes.

$ARGUMENTS
