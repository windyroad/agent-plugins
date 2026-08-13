---
status: proposed
date: 2026-08-07
decision-makers: Tom Howard
human-oversight: confirmed
oversight-date: 2026-08-07
oversight-note: "2026-08-07 — confirmed via a P357 post-change brief; the record was sent to the maintainer and read before confirmation. The brief distinguished, and the maintainer confirmed knowing, which parts are an EXTRACTION of already-ratified substance and which are a FIRST recording: `storyStatus` moved from ADR-102's 2026-08-06 amendment, while card titles, card values, and row and map problems had been recorded in no decision at all. The join-key and row-membership carve-out was surfaced as its own point — without it the rule reads onto `data-story-id` and onto a card's presence in a row, and deletes the card. The cost of the chosen option was stated rather than buried: a map edited and not re-rendered shows stale derived values, bounded by a discipline (`story-map-edit` re-renders) and not by a guarantee."
consulted: [wr-architect:agent]
informed: []
---

# ADR-104: A story map card stores no value a story file already carries

## Context and Problem Statement

A story map card names a story. The story has its own file, with its own frontmatter and body. Wherever a card also stored something that file already said, the two drifted — and every time, the drift was found by someone noticing wrong output, never by anything detecting it.

Six instances, all surfaced in a single session on 2026-08-07:

| Stored on the card | Already in | How it showed up |
|---|---|---|
| `storyStatus` | the story's `status:` | three of eight maps out of date |
| card title | the story's title | titles diverged from the stories they named |
| RFC story list | the row's membership | an RFC listed stories the row did not hold |
| row status | its stories' states | a delivered row still reading as proposed |
| card `value` | the story's `## User value` | **every** value on STORY-MAP-002 had decayed into a paraphrase, while the stories carried proper value-first statements |
| row and map `problems` | the stories' `problems:` | the map claimed two problems no story mentioned, and omitted three that stories did |

The last is the clearest. Three places named problems — the map's `traces.problems`, an authored list on each row, and the story files — and all three disagreed. The story is the only one that can be right, because it is where the work and the problem meet.

Each was fixed as a defect. None of the fixes prevented the next, because there was no rule to apply — only a growing pile of cases.

## Decision Drivers

- A stored copy imposes a sync obligation on every transition that changes the fact. Nobody honours it reliably; that is what drift is.
- Ratification churn. Under ADR-090 a stored value sits inside the map's fingerprint, so ticking a story to `done` re-opened the map's approval. Progress is not a revision of what a human approved.
- The alternative's cost must be stated plainly: derived data is only as fresh as the last render, so a map edited and not re-rendered shows stale values.
- Six rediscoveries of one rule is evidence it needs writing once, rather than being re-derived each time it is broken.

## Considered Options

- **A. Store on the card, and keep the copies in sync.** What the maps did. Every lifecycle transition must update every map holding that story.
- **B. Derive at render time from the story corpus.** The renderer already reads the story tree; it resolves status, value and problems and emits them beside the data island.
- **C. Store, and add a drift detector.** Keep the copies and lint for disagreement. Maps stay readable standalone, and silent drift becomes a reported failure.

## Decision Outcome

**Chosen option: B.**

A card carries only what identifies it. Anything the story file already says is derived at render time — lifecycle status, the value statement, and the problems the story closes. A row's problems are the union of its stories'; a map's are the union of its rows'.

Derived values are emitted into a `<script id="story-map-status" type="application/json">` block beside the data island, so a consumer reads them without re-walking the corpus, and the grid and any tool asking about the same map cannot disagree.

Option C was rejected because it accepts the drift and then reports it. A detector makes a fixable problem visible; deriving makes it unrepresentable. The corpus had already shown "someone will notice" is not a control — all six were found by eye.

Option A's genuine advantage — a map read outside the repository still shows status and values — is preserved, because the derived block ships in the file. It is lost only for a map edited and not re-rendered, which `story-map-edit` prevents by re-rendering after every operation.

### What this does not decide

**The join key and row membership are the one duplication that must survive.** This rule governs what a card stores *about* a story, not the fact that it names one. A card keeps its `data-story-id` — that is the reverse-trace layer ADR-102 names as load-bearing, and deriving it is incoherent, since it is the key everything else is derived *by*. A card's presence in a row likewise stays authored, even though the story's `story-maps:` field carries the inverse relation, because that field is the side ADR-103 derives approval from and the two are one edge seen from two ends. Read literally without this carve-out, the rule would delete the card.

**Row status and RFC story lists are ADR-103's**, decided there and not re-opened. This ADR states the general rule they are instances of.

**Not everything here is an extraction.** The `storyStatus` instance was ADR-102's 2026-08-06 amendment, moved. Card titles, card values, and row and map problems were recorded in no decision before now, so for those this is a first recording. Anyone ratifying should know which is which.

## Consequences

- Good: a lifecycle transition needs no map edit. The story moves, and every map showing it is correct on next render.
- Good: the map's fingerprint stops moving for reasons that are not substance, which is what made ratification churn.
- Good: the rule is stated once. A seventh instance is now a violation of something written, not a new discovery.
- Bad: a map edited and not re-rendered carries stale derived data. Bounded by `story-map-edit` re-rendering after every operation, and by the derived block being regenerated wholesale rather than patched.
- Bad: rendering costs a walk of the story corpus per map — tens of milliseconds, at authoring time, not read time.
- Neutral: outside a repository nothing resolves and the derived block is simply absent. Cards degrade to title-only rather than showing something wrong.

## Confirmation

- A story transitioned `draft → done` changes no map file, and every map showing it renders the new status — behavioural test.
- A card carrying an authored `storyStatus` or `value`, or a row carrying authored `problems`, is ignored in favour of the derived value — behavioural test, so a pre-migration island cannot outvote the corpus.
- The map's oversight fingerprint does not move across a story's lifecycle transition.
- A map rendered outside a repository emits no derived block and shows no status, rather than a stale one.
- `data-story-id` survives on every story-bearing card, and reverse-trace resolves through it — the carve-out is asserted, not assumed.

## Related

- **ADR-102** (story maps render from JSON through a canonical template) — this was its 2026-08-06 "status is derived" amendment, split out on 2026-08-07 and widened to the rule the other five instances share.
- **ADR-103** (a release row is the RFC, and the map is the approval surface) — decided the row-status and RFC-story-list instances; not re-opened here.
- **ADR-090** (drift-invalidated oversight marker) — the ratification churn this removes.
- **P479** — why this arrived as an amendment to ADR-102 rather than its own record.

## Reassessment Criteria

Reassess if staleness in an un-re-rendered map causes a real error — the signal is someone acting on a derived value the corpus had already changed. Reassess if the render-time corpus walk becomes slow enough to be felt while authoring. Reassess if a seventh instance appears that this rule does not cover, since that would mean the rule is narrower than the pattern.
