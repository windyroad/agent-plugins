---
"@windyroad/itil": patch
---

Relevance evaluator: an abbreviated path in ticket prose is no longer read as a deleted file

The path-extraction regex in `evaluate-relevance.sh` admits `.` and `/`, so an
elided reference written inside backticks — `packages/itil/hooks/lib/.../detectors.sh`,
or `docs/decisions/044-....md` — extracted as though it were a real path, was
found absent, and counted as evidence that the file had been deleted. A ticket
could therefore be judged fixed because its prose had been shortened.

Candidates carrying an ellipsis are now skipped. (The Unicode form never
matched the extractor in the first place; a regression case keeps it that way.) Genuinely absent paths are
unaffected, and a ticket that cites both still reports only the real one.
