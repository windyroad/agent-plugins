---
status: proposed
date: 2026-08-08
decision-makers: Tom Howard
human-oversight: confirmed
oversight-date: 2026-08-08
oversight-note: "2026-08-08 — confirmed via a P357 post-change brief. The maintainer declined to ratify on a summary and asked for the document, then read it in full, so the confirm event covers the text rather than a description of it. Two judgements were surfaced before the choice rather than left implicit: that this is a deletion with accepted loss and not a relocation, since nothing writes the nine dropped references onto the stories they govern; and that four of STORY-MAP-002's six have no other carrier anywhere in the repository — a correction to an earlier framing that had wrongly called them reachable through the stories. The document was cut back to this one decision AFTER the confirm event and the marker retained: as ratified it also carried two amendment sections reaching into ADR-060 and ADR-102, which the maintainer ruled are not a legitimate mechanism at all — a ratified decision is immutable and is changed only by being deprecated or superseded. Those sections were riders in P480's exact sense, never part of the choice that was confirmed, so removing them narrows the document to what was actually ratified rather than altering it. Both edited documents are reverted untouched. Recorded as P483."
consulted: [wr-architect:agent]
informed: []
supersedes: []
---

# ADR-106: A story map carries no decision trace

## Context and Problem Statement

A story map's data island carries a `traces` object. Until now it held three keys: `jtbd`, `rfcs` and `adrs`. This decision is about the third.

`traces.adrs` was authored by hand — a list of the decisions a map was said to rest on, rendered as a "Decisions:" line beneath the grid. Nothing derived it and nothing checked it, and it drifted accordingly. On STORY-MAP-002, the corpus's only ratified map, it named six decisions of which only two appear on any story the map holds; the other four are the framework the map was built under rather than anything its stories rest on. Four maps carried the key with content, nine references in total.

The question surfaced while removing the sibling duplication in `traces.rfcs`, which is the union of the map's release-row identities and so is derivable. `adrs` is not derivable: the story schema has an optional `adrs:` field, but only nine of roughly fifty stories use it, so a union would have produced an empty list for five of the seven maps and deleted the nine references while appearing to preserve them.

## Decision Drivers

- A trace nothing derives and nothing checks will drift, and this one already had. The evidence is on the ratified map, which is the worst place for it.
- `traces` sits inside the ADR-090 oversight fingerprint, so whatever the key holds is substance a human is asked to ratify. A stale list is then ratified staleness.
- The decisions themselves are not at risk. They are in `docs/decisions/`, in the compendium, and in the supersession chains; the map was never their record.
- Whatever is chosen must not claim to preserve something it deletes.

## Considered Options

- **A. Derive `traces.adrs` from the union of the stories' `adrs:` frontmatter.** Symmetric with how a map's problems already work. Requires backfilling story frontmatter first, or five of seven maps silently render no decisions and STORY-MAP-002 drops from six to two.
- **B. Keep `traces.adrs` authored.** It is the one trace dimension with no story-level source, so a map-level fact is arguably what it is. Costs nothing to adopt, and leaves the drift in place with nothing checking it.
- **C. Drop `traces.adrs`.** A map carries no decision trace at all. The nine references are lost from the maps; the decisions remain where they live.

## Decision Outcome

**Chosen option: C.**

A story map's data island carries no `adrs` key, the renderer emits no `<meta name="adrs">`, and the trace line beneath the grid shows jobs only. `traces` holds one authored key, `jtbd` — the jobs the map is drawn for, which is why the map exists and is genuinely the map's own substance.

The reasoning is about where a decision belongs. A decision constrains **how something is built**, and the thing that gets built is the story. A release row is only an assertion that a set of stories ship together, and a map is only a lens drawn over stories for one persona; neither has an implementation of its own for a decision to constrain. So a decision reference that lives only on a map is not a map-level fact — it is a story-level fact recorded in the wrong place.

**This is a deletion with accepted loss, not a relocation.** Nine references across four maps are removed and nothing writes them onto the stories they govern. That was surfaced explicitly before the choice was made, including that four of STORY-MAP-002's six have no other carrier anywhere in the repository. ADR-060's story schema does specify an optional `adrs:` field, and STORY-022 already uses it, so the tier that ought to carry such a reference exists and is available — but populating it is not part of this decision, and saying otherwise would claim a preservation this change does not perform. Git history holds what was there.

Option A was rejected because it deletes while appearing to preserve: with nine of fifty stories carrying `adrs:`, the union is empty for most maps, and "derived" would have read as a tidier answer than it is. Option B was rejected because a list nothing derives and nothing checks has already been shown to drift, on the one map where drift is most expensive.


## Consequences

- Good: a `traces` object with one authored key cannot disagree with itself. There is no second list of decisions to keep in step.
- Good: the fingerprint no longer covers a stale hand-written list, so a human ratifying a map is not ratifying drift.
- Bad: nine decision references are gone from the maps, four of them with no other carrier. Recovering one means reading git history or re-deriving it from the stories.
- Bad: the "what does this map rest on" line is now shorter. Anyone who used it for orientation loses that, and the substitute — reading the stories' own `adrs:` — is only as good as how few stories populate it.
- Neutral: `traces` keeps its nesting despite holding one key. It is a named entry in `oversight_map_substance_keys()` and in the ADR-090/ADR-103 basis narration; flattening would re-touch the enumeration sites this change exists to reduce.

## Confirmation

- A map's island carries no `adrs` key and the renderer emits no `<meta name="adrs">` — behavioural test.
- An island that authors `traces.adrs` anyway renders **no** trace landmark and contributes **no** entry to the derived `hrefs` block. The second half is what makes the key inert rather than merely unrendered: while the renderer's id scan stringified the whole `traces` object, an authored `adrs` still resolved into `hrefs`. The test plants a resolvable decision file, because with no `docs/decisions/` directory every id looks inert whatever the scan does and the assertion passes vacuously.
- The documented island in `capture-story-map/SKILL.md` names no `adrs`, and the differential test that checks every documented field is load-bearing now descends into `traces` — so re-adding the key fails on its own rather than waiting to be noticed.


## Related

- **ADR-103** (a release row is the RFC, and the map is the approval surface) — a separate change in the same commit makes `traces.rfcs` derived from the release rows. Different rule: that one is derive-don't-duplicate, this one is don't-carry-it-at-all.
- **ADR-104** (a story map card stores no value a story file already carries) — the general derive-don't-duplicate rule. It does not cover this decision, because no story file carries a map's decision trace.
- **ADR-090** (story maps carry a drift-invalidated oversight marker) — unaffected. `traces` is in the fingerprint basis before and after; only its content changes, which is ADR-090 working as designed.
- **ADR-060** — its story-map frontmatter schema still lists an `adrs:` key. That schema predates ADR-102's move to HTML-plus-island and is stale in several other ways too; it is left untouched and tracked as P481, because this decision has no business editing another document.
- **P480** — an ADR's ratification is document-scoped, so riders that were never weighed inherit its authority. This document is scoped to one decision under that rule.
- **P483** — amendment sections are not a legitimate mechanism; a ratified decision is immutable. This document carried two before that rule was stated, and they were removed rather than ratified.

## Reassessment Criteria

Reassess if the story-level `adrs:` field becomes widely populated, since a map-level union would then be derivable and might earn its place. Reassess if a reader repeatedly asks what decisions a map rests on and reading the stories does not answer it — that would mean the map-level list was serving a real orientation need rather than only drifting.
