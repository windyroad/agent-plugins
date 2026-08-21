---
"@windyroad/itil": patch
---

Make story-map reference links and keyboard focus visible without relying on colour or on browser defaults.

Reference links inside a map's prose — the `closes` run on a release row and the `Traces:` line on a task card — now carry an underline stated in the stylesheet rather than inherited from the browser. Nothing had removed the default underline, so maps rendered correctly; but the rule was unstated, and any later reset would have dropped it silently. There is no contrast to fall back on if that happens: the link colour sits at 1.09:1 against the muted text around it in dark mode, where 3:1 is the floor for colour to carry a link on its own.

Keyboard focus is no longer hidden behind the pinned release-slice column. Below 940px the grid scrolls sideways, and browsers scroll a focused link flush to the edge of the scroll region — underneath the sticky column, which is opaque. Reference links are narrower than that column, so they disappeared entirely rather than partly. The scroll region now reserves room for the column and the focus ring.

Also retires the unused `.b-later` badge rule and its glyph, left behind when a row with no trace became a defect rather than a third resting state.
