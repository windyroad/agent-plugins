# Problem 550: The propose-fix trace predicate checks that a vehicle exists, not that a card covers the scope

**Status**: Open
**Reported**: 2026-09-19
**Priority**: 6 (Medium) — Impact: 2 × Likelihood: 3 — derived at capture from the description per Step 4a
**Origin**: internal
**Effort**: M — derived at capture per Step 4a. The predicate change is small; deciding what "covers this scope" means for a ticket with more than one reported face is the real work, and the ticket format carries no structural notion of a face.
**WSJF**: 3.0 — (6 × 1.0) / 2
**JTBD**: JTBD-008
**Persona**: developer

## Description

The propose-fix trace predicate answers "does a fix vehicle exist for this problem?" The next step needs a different answer: "does a card on that vehicle cover the scope I am about to implement?"

P435 traces RFC-062, whose release row on STORY-MAP-008 carries STORY-056 (the push-gate over-fire face) and STORY-084 (`gh pr merge`, delivered). The ticket's second inbound-reported face — the external-comms gate under-firing on static-site and deck content, issue #253 — has no card on that row and no story file anywhere. STORY-056's own Notes explicitly disclaim it: *"This story is the over-fire face."*

The 2026-09-19 P435 iteration read a clean trace, designed a fix for both faces, and learned of the gap only when `wr-architect:agent` returned ISSUES FOUND naming it. The design pass was already spent, and the iteration could not recover — drawing the missing card is a capture-skill action an AFK iteration is constrained out of.

## Symptoms

- A trace predicate reports clean on a problem whose fix vehicle covers only part of it.
- The gap surfaces at architect review, after the design work that depends on it.
- An AFK iteration that hits it cannot recover in the same run: drawing the missing card needs a capture skill, and the iteration is left with a design it cannot land.

## Workaround

Before designing, read the row's cards and check each against the ticket's enumerated faces by hand. On an inbound-reported ticket, the issue numbers in the `**Origin**` line are the face list.

## Impact Assessment

- **Who is affected**: anyone working a problem with more than one reported face, and every AFK iteration dispatched against one.
- **Frequency**: once per multi-face ticket worked.
- **Severity**: Minor — a spent design pass and a review round, recoverable on the next iteration; nothing shipped is wrong.

## Root Cause Analysis

### Investigation Tasks

- [ ] Investigate root cause
- [ ] Create reproduction test

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P435 (the witness), P508 (the vehicle is a row, not a document — same predicate, different axis), P371 (wire an existing vehicle rather than minting a new one).

## Related

Captured via `/wr-itil:capture-problem` during the 2026-09-19 P435 iteration retro; expand at next investigation.

The hang-off pre-filter surfaced 22 candidates sharing a signal (ADR-103 / ADR-096 / RFC-062 / STORY-MAP-008), over the 5-candidate cap, so the arbitration subagent was not dispatched per the capture contract's latency short-circuit. Re-evaluate the absorb-vs-proceed question at the next `/wr-itil:review-problems` cluster pass. The nearest siblings by title were P371 (closed — I13 auto-creates a new RFC instead of wiring the existing fix vehicle), P449 (the I13 trace gate is not adopter-aware) and P516 (add-card omits the back-link); none of them carries the coverage-depth concern.

- **Second witness — 2026-09-19 (AFK work-problem iteration on the inbound fix-released verdict ticket)**: the predicate read clean on a ticket whose reopened scope no card covers. The ticket traces a vehicle whose one card is about generating outbound comment prose from real issue context — a different ticket's scope entirely — while the reopened scope is an automatic reconciliation cadence that back-fills owed updates. `wr-itil-check-fix-rfc-trace` exited 0 with empty stdout, which reads as "work may proceed", and the gap was visible only by opening the card and reading it. Unlike the first witness this one cost nothing, because the iteration read the card before designing rather than after — but that is discipline, not a property of the predicate. The face here is not a second inbound issue number: it is a **reopen that widened the ticket's scope past what the original vehicle was drawn for**, which the enumerated-faces workaround does not catch. Whatever "covers this scope" ends up meaning should account for a reopen as a scope-widening event, not only for a multi-issue origin line.
