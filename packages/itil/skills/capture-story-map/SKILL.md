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

**I3 hard-block** (per ADR-060 line 187): trace absent / malformed / unresolved → emit deny log entry to `logs/story-map-capture-denials.jsonl`, halt with stderr directive naming `/wr-itil:capture-problem` as the open-the-driving-problem-first surface.

### 2.5. Validate JTBD trace + I4 hard-block

For each `JTBD-<NNN>`:

```bash
jtbd_file=$(ls docs/jtbd/*/JTBD-<NNN>-*.md 2>/dev/null | head -1)
```

**I4 hard-block** (per ADR-060 line 188): trace absent / malformed / unresolved → emit deny log + halt. Story-maps without JTBD trace are structurally meaningless per ADR-060 ("a map with no JTBD trace is structurally meaningless"; Patton's central thesis is journey-around-user-value).

### 3. Compute next STORY-MAP ID

Inline `max(local, origin) + 1` per ADR-019 collision-guard (architect Slice 3 design review option a — inline-only path, mirrors capture-rfc + capture-story precedent):

```bash
local_max=$(ls docs/story-maps/*/STORY-MAP-*.html 2>/dev/null | sed 's|.*/STORY-MAP-||;s|-.*||' | grep -oE '^[0-9]+' | sort -n | tail -1)
origin_max=$(git ls-tree -r --name-only origin/main docs/story-maps/ 2>/dev/null | sed 's|.*/STORY-MAP-||;s|-.*||' | grep -oE '^[0-9]+' | sort -n | tail -1)
next=$(printf '%03d' $(( 10#$(echo -e "${local_max:-0}\n${origin_max:-0}" | sort -n | tail -1) + 1 )))
```

### 4. Optional taste prompt for title

Same shape as capture-story Step 4 — silent-default when unavailable.

### 5. Write the story-map file

**File path**: `docs/story-maps/draft/STORY-MAP-<NNN>-<kebab-title>.html`

**Template** (per ADR-060 § Phase 2 encoding amendment 2026-05-12 lines 381-420 + `docs/STYLE-GUIDE.md` rules):

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>STORY-MAP-<NNN>: <Title></title>
  <meta name="story-map-id" content="STORY-MAP-<NNN>">
  <meta name="status" content="draft">
  <meta name="problems" content="<P<NNN>[,P<NNN>...]>">
  <meta name="rfcs" content="">
  <meta name="jtbd" content="<JTBD-<NNN>[,JTBD-<NNN>...]>">
  <meta name="adrs" content="">
  <meta name="reported" content="<YYYY-MM-DD>">
  <meta name="decision-makers" content="<git config user.name>">
  <style>
    body { font-family: system-ui, sans-serif; max-width: 1200px; margin: 1rem auto; padding: 0 1rem; }
    h1 { font-size: 1.5rem; }
    h2 { font-size: 1.125rem; margin-top: 1.5rem; }
    .backbone { display: grid; grid-template-columns: repeat(var(--cols), 1fr); gap: 1rem; margin-bottom: 2rem; }
    .rib-header { grid-column: 1 / -1; border-bottom: 1px solid #ccc; padding-bottom: 0.25rem; }
    .rib { display: contents; }
    .slice { border: 1px solid #ccc; padding: 0.5rem; text-decoration: none; color: inherit; display: block; }
    .slice:hover { border-color: #666; }
  </style>
</head>
<body>
  <h1>STORY-MAP-<NNN>: <Title></h1>

  <p>(Story-map purpose paragraph — populated at /wr-itil:manage-story-map accepted transition.)</p>

  <section class="backbone" style="--cols: 1">
    <header class="rib-header">
      <h2 data-rib="placeholder">Backbone — populate at /wr-itil:manage-story-map accepted transition</h2>
    </header>
    <div class="rib">
      <!-- Slice cards as <a class="slice" href="../../stories/<state>/STORY-NNN-<slug>.md"
           data-story-id="STORY-NNN" data-rfc="RFC-NNN" data-jtbd="JTBD-NNN"
           data-status="<draft|accepted|in-progress|done|archived>">Story title</a>
           per docs/story-maps/README.md schema. Populated by manage-story-map.
      -->
    </div>
  </section>
</body>
</html>
```

Per `docs/STYLE-GUIDE.md`: NO inline `style=""` on `<a class="slice">` or `<h2 data-rib>` data-bearing elements; embedded `<style>` block in `<head>` is the only permitted styling source; `--cols` custom-property on `.backbone` is the layout-container exception.

### 6. Single commit — `## Story Maps` reverse-trace refresh

**Stage list**: new HTML file PLUS driving problem files (refresh `## Story Maps` section via `update-problem-references-section.sh <file> "Story Maps"`) PLUS driving JTBD files (refresh `## Story Maps` section via `update-jtbd-references-section.sh <file> "Story Maps"`). Do NOT stage `docs/story-maps/README.md` (deferred).

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
