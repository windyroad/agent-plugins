# Ask Hygiene — Session 8 Iter 3 (P268 Open → Verifying)

Date: 2026-05-18
Iter: session-8 iter-3 (`/wr-itil:work-problems` AFK orchestrator)
Ticket: P268

## Calls

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|

(No `AskUserQuestion` calls fired in this iter.)

## Counts

- **Lazy count: 0**
- **Direction count: 0**
- **Deviation-approval count: 0**
- **Override count: 0**
- **Silent-framework count: 0**
- **Taste count: 0**
- **Correction-followup count: 0**

## Notes

- Iter ran under the brief's explicit "NEVER call AskUserQuestion mid-loop (P135 / ADR-044). Queue direction observations at `ITERATION_SUMMARY.outstanding_questions` for loop-end batched presentation." constraint.
- All decisions were framework-resolved per ADR-044:
  - Fix shape selection (B) — ticket-prescribed.
  - Sibling capture batch grain — 86f42e8 precedent ("capture P267 + P268 + P269 batched session-7 follow-on tickets").
  - Promotion-vs-sync for the cross-package helper consumed by P275 — architect-verdict-deferred to P275's refactor work-iter per ADR-014 one-concern boundary.
  - Helper-extraction location (`packages/itil/hooks/lib/`) — architect verdict on P268 review (no new ADR required; existing precedent covers).
- Zero-ask outcome is the target state per ADR-044 R6 numeric gate (lazy count <2 sustained across consecutive retros).
