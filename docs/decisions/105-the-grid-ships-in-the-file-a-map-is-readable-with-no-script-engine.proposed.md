---
status: proposed
date: 2026-08-07
decision-makers: Tom Howard
human-oversight: confirmed
oversight-date: 2026-08-07
oversight-note: "2026-08-07 — confirmed via a P357 post-change brief; the record was sent to the maintainer and read before confirmation. This decision reverses one taken the previous day, and the brief said so plainly: the 2026-08-06 amendment named this exact failure mode — the grid is unreachable without script — and accepted it in a sentence, which it could do because it arrived as an amendment with no option to defend against. Two judgements were surfaced for the maintainer rather than left implicit: rejecting option C (render-plus-enhance) as unearned, which is a claim about future need and the most likely of the two to be wrong; and the affordability premise, that regenerated markup cannot drift a ratification because ADR-103 scopes the fingerprint to the map's own substance."
consulted: [wr-architect:agent]
informed: []
---

# ADR-105: The grid ships in the file — a map is readable with no script engine

## Context and Problem Statement

A story map is a document. Its purpose is to be opened and read, and the places it gets opened are not all browser tabs: a phone's file preview, a sandboxed viewer, GitHub's HTML rendering, print, a diff.

On 2026-08-06 grid rendering moved into the browser. A map became a shell plus a `<script id="story-map-data">` island, with a shared `story-map.js` drawing the table at view time. The file itself carried **zero** grid markup.

That amendment wrote its own failure mode into the record and accepted it in one sentence: *"The grid is unreachable without script, which the server-rendered version did not require; a `<noscript>` note names the data block as the fallback."*

On 2026-08-07 the maintainer opened a map on a phone and got the fallback message instead of the map. The `<noscript>` note pointed at the data block, which is not a map — it is the JSON a map is generated from. The page kept its heading and its lead, so it looked finished while seventeen stories were missing.

## Decision Drivers

- A document that needs a live script engine to be read is not a document. Every other artefact in this repository — problems, RFCs, stories, decisions — is readable as bytes.
- The failure is silent and total. The page renders, keeps its title, and loses all its content; nothing about it says "this is broken".
- The duplication the 08-06 amendment set out to remove was real: one stylesheet copied byte-for-byte across eight files, where a single tweak rewrote all of them. Whatever is chosen must keep that removed.
- Committed generated markup was a real cost before, because it churned ratification. Whether it still is depends on what the fingerprint covers.

## Considered Options

- **A. Render the grid into each map.** `wr-itil-render-story-map` writes the table, its cards and both header axes into the file, which is what it already does for the `<meta>` block. Generated markup is committed.
- **B. Build the grid at view time.** The file carries the island and a `<script src="../story-map.js">`; the browser draws the table. No generated markup is committed.
- **C. Ship both.** Render into the file, and let a script enhance it afterwards — sorting, filtering, collapsing. Readable without script, richer with it.

## Decision Outcome

**Chosen option: A.**

The grid is rendered into each map. `story-map.js` is deleted. The two `<script>` elements a map still carries are both `type="application/json"` data islands, which a viewer ignores rather than executes.

The markup is what the script produced, including the focusable `<div class="scroll" role="region" aria-label="Story map grid">` wrapper — that is what makes a wide grid scrollable, and reachable by keyboard, on a narrow screen. It was dropped during the port and the accessibility test caught it.

**The stylesheet stays shared.** That is what the 08-06 amendment got right, and it is retained: `story-map.css` remains a single copy beside the maps, and the prohibition on a per-map `<style>` block still stands. Only the grid returns. The two changes were bundled on 08-06 and only one was load-bearing — client rendering was never required to de-duplicate the stylesheet.

Option C was rejected as unearned. Nothing wants to sort or filter a map today, and shipping a script that only enhances means keeping a second rendering path in step with the first for a benefit nobody has asked for. It stays available: A is the floor C would build on, so choosing A now does not foreclose it.

### Why committed markup is affordable now, when it was not before

Under ADR-103 the oversight fingerprint covers the map's own substance within the data island — what ADR-090 defines as substance. *(Enumerated as seven field names until 2026-08-08. Six sites restated the same tuple; by that morning the ADRs still named `lead` and `traceProse`, dead the previous day, while a SKILL had lost live keys. The rule stays here; the list moved to code.)* *(Read “… lead, traces, trace prose and caption” until 2026-08-08. `lead` and `traceProse` left the map format on 2026-08-07. Because the basis includes only keys PRESENT in the island and no map carries either, removing them moved no stored hash and re-opened no ratification — STORY-MAP-002 stayed ratified across the change. Reconciled in place; leaving the enumeration stale would have made this decision the re-introduction vector the code change closes.)* Generated markup sits outside that basis entirely. So a template change still rewrites every map, but it **cannot un-ratify one**. That is the premise this whole decision rests on, and it is why the same choice would have been wrong before ADR-102 scoped the hash to the island.

### What this does not restore

Cards being back in the file does not re-promote the single-line `data-story-id` rule to a correctness constraint. ADR-103 demoted it to a readability convention when cards left the fingerprint basis, and they are still outside it. The whole-line filter that rule protected is gone.

## Consequences

- Good: a map is readable as bytes. No browser, no script engine, no build step. Separated from its shared stylesheet it degrades to unstyled-but-readable rather than to a fallback message — that gradient is the property worth having.
- Good: the "did the script run?" failure mode is gone, along with 340 lines of client code and the jsdom-injection harness the tests needed to exercise it.
- Bad: generated markup is committed again, so a template change rewrites every map. Bounded, as above, by the fingerprint being narrower than the file.
- Bad: a map now looks hand-editable, because the grid is right there and reads as ordinary HTML. It is regenerated on the next render, and the prohibition on hand-editing matters more than it did when there was nothing to edit.
- Neutral: `jsdom` remains a devDependency — not to run a map's scripts, of which there are none, but for header-association and cell-count assertions a grep cannot make.

### On the reversal

This decision reverses one taken the previous day, and the record should say why plainly rather than quietly. The 08-06 amendment named this exact cost — "the grid is unreachable without script" — and accepted it in a sentence, because it arrived as an amendment and no option had to be argued against it. Had it been written as a decision with a Considered Options section, option B would have had to defend the `<noscript>` fallback against the case where someone opens the file outside a browser, which is the case that broke it a day later. That mechanism is captured as P479.

## Confirmation

- A map's own bytes carry the grid: the table, its cards and both header axes are present in the file as shipped, and every surviving `<script>` element is `type="application/json"`. Asserted against the **file's bytes**, deliberately, not against a parsed DOM — reading it through a DOM would run whatever scripts are present and prove nothing. Behavioural test: `packages/itil/scripts/test/render-story-map.bats` § "the map is readable with no script engine at all".
- No fallback message survives, because there is nothing left to fall back from.
- The scroll region is present and focusable, so a wide grid is scrollable by keyboard and on a narrow screen.
- Re-rendering an unchanged source is byte-identical, and the map's oversight fingerprint is stable across a presentation-only template change.

## Related

- **ADR-102** (story maps render from JSON through a canonical template) — this was its 2026-08-06 view-time-rendering amendment and its 2026-08-07 reversal, split out on 2026-08-07.
- **ADR-103** (a release row is the RFC, and the map is the approval surface) — supplies the narrowed fingerprint basis that makes committed markup affordable.
- **ADR-104** (a story map card stores no value a story file already carries) — the other half of the 08-06 amendment, split out at the same time and retained rather than reversed.
- **P479** — the mechanism that let this ship as an amendment with its failure mode accepted in a sentence.

## Reassessment Criteria

Reassess if a template change ever does drift a ratification, since that would mean the fingerprint is wider than ADR-103 says and the affordability premise is wrong. Reassess if committed markup makes map diffs unreviewable in practice — the signal is a reviewer skipping map files because the generated hunks bury the island change. Reassess toward option C if a genuine interaction need appears, since A is the floor C builds on.
