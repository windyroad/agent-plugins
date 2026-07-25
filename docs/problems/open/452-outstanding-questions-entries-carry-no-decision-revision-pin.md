# Problem 452: outstanding_questions queue entries carry no decision-revision pin — stale entries outlive amendments and get adjudicated against retired mechanisms

**Status**: Open
**Reported**: 2026-07-15
**Priority**: 6 (Medium) — Impact: 3 (Moderate — a stale adjudication can produce a rework decision contradicting the CURRENT decision text; observed once with user-visible impact 2026-06-10, caught only by an accidental fresh read) × Likelihood: 2 (Unlikely — needs a queued entry to outlive an amendment to its cited decision before the next loop-end drain) — derived at capture per Step 4a
**Origin**: inbound-reported (#338)
**Effort**: M — queue-entry schema extension (blob SHA / amendment-date pin at queue time) + Step 2.5 surfacing-pass mismatch flag and/or pre-present re-read; behavioural test
**WSJF**: 3 — (6 × 1.0) / 2 (added 2026-07-26 review)
**JTBD**: JTBD-006
**Persona**: developer

## Description

Entries in the work-problems ADR-044 loop-end queue (`.afk-run-state/outstanding-questions.jsonl`) reference decisions by bare ID (e.g. `existing_decision: "ADR-060 § Bypass mechanism line 158"`) with no revision pin — no commit SHA, no amendment-date snapshot. A deviation-approval entry queued against one revision can survive an amendment that changes or retires the very mechanism it cited, and be surfaced at a later loop-end for adjudication against a revision that no longer matches. Observed: a 2026-06-02 entry cited a bypass-trailer encoding retired entirely by a 2026-06-08 amendment; at the 2026-06-10 loop-end the user adjudicated the stale framing against a mechanism that no longer existed. The mismatch was caught only by accident (a fresh-context subagent happened to read the current ADR text during an unrelated capture).

Fix direction (either or both, per the report): (a) queue entries record the cited decision file's git blob SHA / last-amendment date at queue time; the Step 2.5 surfacing pass compares against current state and prefixes the question with a decision-amended-since-queued note on mismatch; (b) Step 2.5's ranking step re-reads each cited decision before presenting and drops/flags entries whose cited section no longer exists.

## Symptoms

- Loop-end outstanding_questions entries presented with framing that no longer matches the cited decision's current revision.
- Without an accidental fresh read, a rework decision contradicting current decision text can be produced.

## Workaround

None systematic — relies on incidental fresh reads of the cited decision during unrelated work.

## Impact Assessment

- **Who is affected**: developer persona — AFK loop users adjudicating queued decisions.
- **Frequency**: latent on every queued entry that outlives an amendment; one observed user-visible hit (2026-06-10).
- **Severity**: Moderate — wrong-basis adjudication risk on governance decisions.
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [ ] Add the revision pin (blob SHA + amendment date) to the outstanding_questions schema at queue time.
- [ ] Add the Step 2.5 pre-present staleness check (compare pin / re-read cited section; flag or drop on mismatch).
- [ ] Create reproduction test.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P416 (drain appends superseding decision without reconciling the stale ticket Fix Strategy — same outstanding-questions temporal-consistency family, post-decision side; this ticket is the pre-decision side)

## Related

- Upstream issue #338 (inbound).
- Hang-off arbitration 2026-07-15 (wr-itil:hang-off-check): PROCEED_NEW — P416 fires AFTER the human decides (ticket-body reconciliation); this fires BEFORE (queue-entry integrity); absorbing would dilute P416's INVEST shape. P444 is authoring-time oversight granularity; P341 (verifying) is gate-ordering, not queued-content fidelity. Sibling cluster "outstanding-questions temporal consistency" (P452+P416) flagged for the next review pass.
