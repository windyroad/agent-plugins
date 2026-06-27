---
"@windyroad/itil": patch
---

work-problems Step 3.5 — orchestrator-layer JTBD ratification predicate-check (P344, RFC-016)

Adds a new Step 3.5 between Step 3 (selection) and Step 4 (classification) that
predicate-checks the cited JTBDs of the selected ticket BEFORE dispatching the
iter-subprocess. The per-iter JTBD review subagent (ADR-068 surface 3) still
catches the same class INSIDE the iter, but only after spending dispatch cost
(~$3-5 + 5-10 min per skip). The new orchestrator-layer predicate shifts the
check left for the cost of one grep + per-JTBD shim call.

Driving exemplar: 2026-05-31 session 9 iter 5 dispatched P082 against unratified
JTBD-001 + JTBD-006; iter correctly skipped per ADR-074 substance-confirm-before-
build, but the dispatch cost was wasted.

On unratified-JTBD detection, the ticket routes to Step 4's user-answerable skip
+ queues an `outstanding_questions` entry (category: "direction") naming the
unratified JTBDs + remedy. The loop re-runs Step 3 tier-first selection over the
remaining backlog. Loopback preserves ADR-076 tier ordering.

Ships:
- `packages/itil/scripts/check-ticket-jtbd-ratification.sh` (helper)
- `packages/itil/bin/wr-itil-check-ticket-jtbd-ratification` (ADR-049/080 PATH shim)
- `packages/itil/skills/work-problems/SKILL.md` Step 3.5 amendment
- `packages/itil/skills/work-problems/test/work-problems-step-3-5-jtbd-ratification-predicate.bats` (behavioural fixture, 8 cases)

Closes the wasted-iter-dispatch class. P344 transitions Open → Verification
Pending (fold-fix per ADR-022 P143); RFC-016 transitions proposed → verifying on
release.

@rfc RFC-016
@problem P344
