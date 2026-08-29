---
"@windyroad/itil": patch
---

Relevance evaluator: `ADR-shipped-confirmed` no longer closes a ticket on its own

`evaluate-relevance.sh` treated a decision record carrying
`human-oversight: confirmed` as evidence that a ticket's fix had shipped. That
marker records that a human ratified a decision, not that anything was built or
released. Because most decision records carry it and most tickets cite one, the
shape matched most of the backlog and carried almost no signal — and
`/wr-itil:review-problems` Step 4.6 closes clean candidates silently when
running unattended.

The shape is now corroborating-only. It is still detected and still cited, and
its behaviour alongside any other evidence shape is unchanged. When it is the
only shape that matched, the verdict is demoted to
`CLOSE-CANDIDATE-WITH-CAVEAT` under the tag `ratification-is-not-delivery`,
which the same step already routes to the maintainer's confirmation surface
instead of closing.
