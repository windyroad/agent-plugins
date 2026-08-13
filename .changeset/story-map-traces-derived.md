---
"@windyroad/itil": minor
---

Story maps no longer carry a decision trace, and their RFC list is derived from their release rows.

A map's `traces` object held three keys. Two of them restated things the corpus already knew, and both had drifted. On the one ratified map, the authored RFC list named three RFCs whose work is not on it — two have no stories at all — while omitting both rows it does have. The decision list named six decisions of which only two appear on any of its stories.

`traces.rfcs` is now derived as the union of the release-row identities, since a row *is* an RFC. `traces.adrs` is removed outright: a decision constrains how something is built, and the thing built is the story, so a decision reference belongs on the story rather than on a lens drawn over it. `traces` keeps one authored key, `jtbd` — the jobs the map is drawn for. Nine decision references across four maps are dropped rather than relocated; the decisions themselves are unaffected.

**Every release row now carries an RFC identity.** The one exception is closed: rows holding work that shipped before rows carried identities, each marked `preRfc`. Finishing a row earns nothing — a row with no identity and no mark is drawn as a defect whether or not its stories are done, so shipping work nobody proposed cannot become legitimate by completing it. If you have maps with rows that predate this, mark those rows; anything else without an identity is a row nobody proposed.

**Problem tickets will start showing their story maps.** When a map's problems became derived, the renderer kept emitting `<meta name="problems" content="">`, and the reverse-trace helper only matches a non-empty value — so every map in every adopter corpus has been failing that match, and the `## Story Maps` section on problem tickets has been silently empty ever since. It looked like "no map traces this problem". That meta now carries the derived union, so the next map transition writes those sections for the first time. Expect a larger-than-usual diff on that commit; it is the trace working, not new behaviour.

Also in this release:

- A map is readable with no stylesheet. A story's value statement is drawn as three clauses, and they were separated only by a CSS rule — so a map opened away from its directory, in a phone preview or an email attachment or a sandboxed viewer, ran all three together as one unbroken line. The markup carries its own separation now. There is a test for it; there was not before.
- A defect row rendered its warning glyph twice, once from the badge and once from the label. The label's copy was in the accessible name, so a screen reader announced "warning" as part of the row's name.
- `story-map-query` reports a map's derived problems and its row RFC identities alongside its jobs. A row with no derived answer now reads `stale` rather than borrowing a status name the renderer can no longer produce.
- A map's data lives in an embedded JSON block, and one test checks that every field the authoring guide documents actually affects what renders. It could not see nested fields, so both removed keys sat outside the one guard built to catch exactly this. It now checks them too.
