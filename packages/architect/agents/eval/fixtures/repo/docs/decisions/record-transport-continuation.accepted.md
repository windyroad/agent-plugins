---
status: accepted
human-oversight: confirmed
---

# Record transport continuation

Synthetic decision for the review fixture.

## Decision Outcome

Return up to 100 matching records per response. When more matching records
exist, return a cursor that retrieves the next page. Continue until the
matching records are exhausted.
