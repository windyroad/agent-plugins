# Problem 538: Problem creation is gated on the problem index existing

**Status**: Open
**Reported**: 2026-09-11
**Priority**: 20 (Very High) - Impact: Significant (4) x Likelihood: Almost certain (5)
**Origin**: internal
**Effort**: M - creation preflight shared by multiple problem-management skills plus focused behavioural coverage
**WSJF**: 10 - (20 x 1.0) / 2
**JTBD**: JTBD-001
**Persona**: developer

## Description

An adopter repository's retrospective could not create problem tickets because the problem-capture skill's mandatory preflight halted when `docs/problems/README.md` was absent. Problem creation is the recovery path for defects in governance state, so a missing or inconsistent problem index must not make that recovery path unavailable.

The capture should preserve the report first, then repair or defer repair of the derived index without discarding the problem.

## Symptoms

- The retrospective reported that problem tickets were not created.
- The stated blocker was the capture skill's mandatory preflight halting because `docs/problems/README.md` did not exist.
- The lifecycle gate prevented the defect describing that gate from being recorded.

## Workaround

None confirmed yet. Manually creating or rebuilding the index may unblock a later capture, but the reported workflow did not exercise that path.

## Impact Assessment

- **Who is affected**: developers using problem-management skills in adopter repositories without a complete local problem index.
- **Frequency**: deterministic whenever creation reaches the current preflight with the index absent; no creation-safe fallback is documented.
- **Severity**: Significant. An installed governance skill fails to preserve a problem report and removes the normal recovery path.
- **Analytics**: one user-visible occurrence supplied as screenshot evidence on 2026-09-11.

## Root Cause Analysis

### Investigation Tasks

- [ ] Reproduce problem creation with an absent `docs/problems/README.md`.
- [ ] Trace every creation caller through the README reconciliation preflight.
- [ ] Identify the shared boundary where creation can preserve the report without accepting stale derived state.
- [ ] Document a safe workaround.
- [ ] Create a focused behavioural regression test.
- [ ] Create an INVEST story for the permanent fix.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P351, P065, P199

## Related

- P351 covers missing configuration preconditions that skip optional skill work. This ticket is narrower and stronger: an absent derived index blocks the act of recording a problem.
- P065 scaffolds downstream OSS intake files, not the local problem-management index.
- P199 covers same-session README drift after capture, not an index that is absent before creation starts.
- The duplicate search found these related themes; the user selected a focused ticket rather than expanding P351.
- The hang-off candidate pre-filter exceeded its five-ticket cap because the shared skill and README paths are widely referenced, so the fresh-context arbitration was skipped per the workflow contract.
