# Problem 253: No process or cadence for house cleaning of cruft and deprecations

**Status**: Closed

## Closed as no longer relevant

- **Evidence shape**: ADR-shipped-confirmed (ADR-079 Phase 2)
- **Closed on**: 2026-06-10
- **Closed by**: /wr-itil:review-problems Step 4.6 relevance-close pass (batch 4)
- **Cite**: ADR-079 (evidence-based relevance-close pass for the problem backlog) ratified 2026-06-08 + Phase 1/2 evaluator + this very review-problems Step 4.6 IS the house-cleaning cadence. Reusable for sibling cleanup classes via the same evaluator pattern.
- **Caveat**: multi-phase-mixed-progress: 0/3 Investigation Tasks done. User confirmed close at interactive batch review 2026-06-10.
- **Persist**: `packages/itil/scripts/evaluate-relevance.sh` is the re-runnable cadence; the evaluator pattern can extend to code-cruft / deprecation classes via sibling evaluators sharing the same harness
- **Uncertainty / reversibility**: reversible via `git revert` or `git mv` back to open/.
**Reported**: 2026-05-17
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Description

There's no process or cadence for house cleaning. Cruft accumulates over time, features or behaviours get deprecated, but never removed.

## Symptoms

(deferred to investigation)

## Workaround

(deferred to investigation)

## Impact Assessment

- **Who is affected**: (deferred to investigation)
- **Frequency**: (deferred to investigation)
- **Severity**: (deferred to investigation)
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Investigate root cause
- [ ] Create reproduction test

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: (none)

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)
