---
"@windyroad/itil": patch
---

work-problems: add Step 3.6 pre-dispatch relevance gate (P385)

On a mature backlog a meaningful fraction of open/known-error tickets have
already been fixed by later work but never transitioned. The AFK
`/wr-itil:work-problems` orchestrator dispatched a full `manage-problem`
iteration (~$3-5 + 5-10 min) per such ticket only to rediscover the shipped
fix and transition it.

Step 3.6 runs the existing `wr-itil-evaluate-relevance` evaluator (the same
one `/wr-itil:review-problems` Step 4.6 uses, ADR-079) on the selected ticket
before dispatch. A clean `CLOSE-CANDIDATE` routes to a single
`/wr-itil:review-problems` relevance-close sweep instead of a full iter;
`CLOSE-CANDIDATE-WITH-CAVEAT` routes to a user-answerable skip; KEEP/SKIP/error
fall through to normal dispatch. The shift-left sibling of Step 3.5's JTBD
predicate. No new script — routing reuses the already-behaviourally-tested
evaluator (`packages/itil/scripts/test/evaluate-relevance.bats`).
