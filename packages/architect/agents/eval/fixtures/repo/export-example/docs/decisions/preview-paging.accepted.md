---
status: accepted
human-oversight: confirmed
---

# Bound preview pages

## Context and scope

This standalone project's preview displays matching records in pages.
Operator export currently includes every matching record.

## Decision Outcome

Return up to 100 records per preview page, with a continuation cursor for
remaining preview records. This decision governs preview paging only.
It sets no cumulative operator-export limit and chooses no export transport
mechanism. No other decision is recorded for this project.
