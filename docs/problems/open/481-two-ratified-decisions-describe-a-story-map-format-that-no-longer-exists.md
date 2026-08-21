# Problem 481: Two ratified decisions describe a story-map format that no longer exists

**Status**: Open
**Reported**: 2026-08-08
**Priority**: 6 (Medium) — Impact: 3 × Likelihood: 2. Impact 3: the block is fenced, machine-shaped YAML in an `accepted`-tier ADR, so it is what a reader or an agent copies when authoring a map — and most of what it names is either derived or absent, so following it produces keys the renderer silently ignores. Not a correctness failure today, because the renderer ignores rather than misreads. Likelihood 2: it bites only when someone authors a map from the ADR rather than from the SKILL's documented island, which is the less-travelled path.
**Origin**: architect-review
**Effort**: S — one fenced block plus two prose sentences, no code
**WSJF**: 6 — (6 × 1.0) / 1 (added 2026-08-21 review)
**JTBD**: JTBD-008
**Persona**: developer

## Description

ADR-060 specifies a story map's frontmatter schema in a fenced YAML block (lines 179-192). Since ADR-102 a map has not had frontmatter at all — it is HTML with a `<script id="story-map-data">` JSON island — and ADR-104 and ADR-107 have since made two of the block's keys derived rather than authored. The block was never reconciled.

**Nothing in the block is being changed.** An earlier attempt struck `adrs:` and `rfcs:` under ADR-106's authority; that was reverted when the maintainer ruled that a ratified decision is immutable and is changed only by being deprecated or superseded (P483). A decision does not reach into another document, so ADR-106 and ADR-107 state the current rules and ADR-060's block is simply stale text that a later decision overrides. Reconciling it is this ticket's job, not theirs.

### The sites

| Line | What it says | Why it is wrong |
|---|---|---|
| 182-185 | `date-created`, `date-accepted`, `date-completed`, `methodology` | The island carries none of them. It has `reported`, which is `date-created`'s equivalent under a different name; the other three have no equivalent at all. They fell out when ADR-102 moved maps to HTML-plus-island — nothing decided to remove them, they were simply never carried across. |
| 186 | `problems:` as an authored `≥1 driver problems` array | Derived per ADR-104 — the union of the row's stories' `problems:`. An authored value is ignored unconditionally by the renderer. |
| 189 | `jtbd:` at top level | Authored, correctly — but it lives under `traces` in the island, not at top level. The block's nesting is wrong for the one key that is still real. |
| 190 | `decision-makers` | The island spells it `decisionMakers`. |
| 194 | "The flat `problems` / `rfcs` / `jtbd` arrays mirror RFC frontmatter precedent" | Falsified on all three counts: `problems` is derived (ADR-104), `rfcs` is derived (ADR-107), and none of the three is flat — all sit under `traces`. |
| 198 | The I3 invariant bullet — "Hard-block at `/wr-itil:capture-story-map` (no problem trace = capture refuses)" | Still operationally true: the gate does refuse. But it grounds capture-time enforcement in a field that is no longer authored, which is the forward-edge gap below. |
| 287 | The problem-ticket `## Story Maps` surface, predicated on "any map's `problems:` array" | That array is derived and empty at capture time, because a fresh map has no stories yet. |

### The forward edge has nowhere to land

Worth separating from the schema drift, because it is the one that could become a real defect. `/wr-itil:capture-story-map` collects and validates a problem trace under the I3 hard-block, then writes the **reverse** edge — the `## Story Maps` section into each problem file — and stages it. That half works.

The **forward** edge does not exist. There is no authored key for the map to record which problems drive it: the documented island is `"traces": { "jtbd": [...] }`, and the derived union is empty until stories are captured onto the map. So a freshly captured map knows its problems only in the direction of the problem files.

Nothing is broken today. The gate still refuses a map with no trace, so the argument is not unvalidated, and it is not discarded either — it lands in the problem files. What is unresolved is whether the forward edge should exist at all, or whether the reverse edge plus the derived union is the whole answer once stories arrive.

### The second site: ADR-102's "preserved verbatim" claim

ADR-102 states that a map's `<meta>` trace block *"is preserved verbatim, including `human-oversight` and `oversight-hash`"*. The renderer regenerates the whole block from the island on every render, drops `adrs` under ADR-106, and derives `rfcs` under ADR-107 — so the claim is false in three independent ways. The *behaviours* each have a decision record; what has none is that a ratified decision states a mechanism the code does not implement. Same shape as the ADR-060 block, different document, so it is tracked here rather than as a sibling ticket.

## Symptoms

- A fenced schema block in an `accepted` ADR naming keys the renderer does not read.
- An author following the ADR rather than the SKILL writing keys that are silently ignored.
- A prose sentence describing three arrays as flat and authored when none of them is either.

## Workaround

Author maps from `capture-story-map/SKILL.md`'s documented island, which is current and bound to the renderer by a differential test. Treat ADR-060's block as historical.

## Impact Assessment

- **Who is affected**: anyone authoring a story map from the ADR rather than the SKILL, and any future reader reconciling the two.
- **Frequency**: rare — the SKILL is the travelled path.
- **Severity**: legibility, not correctness. The renderer ignores the extra keys rather than misreading them.
- **Analytics**: none.

## Root Cause Analysis

Suspected: ADR-102 changed a map's encoding without reconciling the schema block that described the old one, and ADR-104 and ADR-107 each made a key derived without revisiting it. Each change was individually correct and locally scoped; the block was nobody's job.

### Investigation Tasks

- [ ] Decide whether ADR-060's block should be reconciled in place, replaced with a pointer to the SKILL's documented island, or struck wholesale as superseded by ADR-102's encoding amendment. The third is tempting and probably right — a schema specified in two places is the drift class this cluster keeps removing.
- [ ] Whichever is chosen, preserve the line count or accept the citation churn — see P482.
- [ ] Reconcile ADR-102's "preserved verbatim" sentence at the same time, since it is the same shape in a second document.
- [ ] Settle the forward edge: does a map need an authored record of its driving problems, or is the reverse edge plus the derived union sufficient? This is the only item here that could change behaviour.
- [ ] Reconcile lines 194, 198 and 287 with whatever the block becomes.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- **ADR-060** — the document carrying the block.
- **ADR-102** — moved maps to HTML-plus-island, which is when the block stopped matching.
- **ADR-104** — made a map's problems derived.
- **ADR-107** — made a map's RFC list derived from its rows.
- **ADR-106** — states that a map carries no decision trace, and deliberately edits nothing here.
- **P480** — the discipline being applied here: an ADR's ratification is document-scoped, so an unweighed edit inherits authority it was never given.
- **P483** — the stronger rule that supersedes the attempted fix: amendment sections are not a legitimate mechanism at all.
- **P482** — the positional-citation rot, which is why the strike comments out rather than deletes.

(captured during the ADR-106 architect review; expand at next investigation)
