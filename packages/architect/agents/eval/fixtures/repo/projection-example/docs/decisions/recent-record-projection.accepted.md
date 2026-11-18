---
status: accepted
human-oversight: confirmed
---

# Browse recent records through a bounded query projection

## Decision Outcome

Use a query-identified recent-record projection retaining the latest 1,024 rows
across selected sources. Ordered changes include corrections, removals,
evictions and refresh facts. Ordinary presentation paging remains separate.

Browser and server use the same recent-record definition. Browser loading
restores the complete projection state, including future-affecting eviction
state and consumed progress, with paired direct-input positions. It continues
that projection through its declared input feeds. The server also exposes
public display rows for authorized HTTP consumers.

## Confirmation

Restore and replay produce the same rows, corrections and eviction results as
uninterrupted processing. Current authority withdrawal retires the view.
Measure representative retained row and metadata sizes.
