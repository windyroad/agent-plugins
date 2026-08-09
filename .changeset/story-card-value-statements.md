---
"@windyroad/itil": minor
---

Story map cards now show the value statement a story actually wrote, and a map is refused rather than rendered when one cannot be shown properly.

A card renders a story's value statement as three lines — the value, who it is for, and what they want. Three faults meant the card could differ from the story it was showing, and none of them said so.

The section was flattened with blank lines removed, so a paragraph written *below* the statement glued itself onto the end of the last clause. One card ran to 169 words, most of it the author's supporting evidence. The card now takes the statement and stops; a story is still free to explain itself underneath.

The clause openings were re-emitted from memory rather than read. Eighteen stories written "In order that ..." were relabelled "In order to ..." on every map that carried them, and requiring the persona clause to begin with "a", "an" or "the" turned "as whoever picks the ticket up" into an unsplittable statement. Both are gone: the shape is the rule — value, who, want, in that order — and the wording is the author's.

The last fault is the one that matters. A statement that could not be split fell through to a path that rendered it as a single undifferentiated block. On a map where every other card shows three labelled clauses, that is indistinguishable from a story written badly, so the renderer's failure was read as the author's by a reader with no way to tell them apart. This had happened before; the recorded fix was to widen the pattern, which fixed the statements in front of it and left the fault open for the next unanticipated wording. Rendering now stops, names the story and the text, and says what to do — including that a statement already in the house shape means the pattern has found a new edge and should be widened, rather than the story reworded to suit it.

Maps also now open with what they are and what is being asked, in prose. Whether a map was still a draft, and whether anyone had agreed it, previously existed only in `<meta>` tags, which do not render — so a reader opening a map got a title and a grid, and had to infer the rest. Column headers stay in view while scrolling, which matters because a single row can run taller than the screen.
