---
"@windyroad/itil": minor
"@windyroad/retrospective": patch
---

Propose a fix as a release row on a story map, not as a new RFC document.

Working a known error used to create a standalone file under `docs/rfcs/`. That file was approved on its own, separately from the story map — so a fix proposed that way never reached the map, which is where the work is actually agreed. A fix proposal is now a release row: the row carries the RFC identity, its cards carry the stories, and approving the map approves the row.

The propose-fix check now answers from both — a release row's cards, or a legacy document's problem list — so nothing that read as traced before reads as untraced now. It also stops telling you to create a document, and instead names the row to draw and the identity to give it. Two situations it refuses rather than guesses at: a story map edited without being re-rendered (re-render it and ask again — nothing needs deciding), and a repository with no story maps at all (drawing the first map for a journey decides what that journey is, so it asks you rather than inventing one, and carries on to the next problem instead of stopping).

RFC identities are now allocated by one rule that sees release rows, RFC documents and git history at once, via `wr-itil-next-rfc-id`. The previous rule read the document directory alone, and release rows already held identities above the highest document — so it was handing back an identity a row already owned. If you have a copy of that rule anywhere, replace it with a call to the allocator.

**There is no migration, and none is coming.** The RFC documents already in your repository keep working exactly as they do today: they stay readable, they stay linked, and the checks that read them keep reading them. They simply stop being the thing a fix proposal creates. Each one becomes a release row if and when its own problem is next worked. There is no command to run and no moment at which you are behind.

`/wr-itil:capture-rfc` keeps its name and its entry point. Repointing what it writes is a following change; this one moves the readers first, so the check can answer from rows before anything stops producing documents.
