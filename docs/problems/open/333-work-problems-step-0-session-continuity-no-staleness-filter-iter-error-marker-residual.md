# Problem 333: /wr-itil:work-problems Step 0 session-continuity detection has no staleness filter on .afk-run-state/iter-*.json error markers — stale residuals false-positive the halt/ask gate indefinitely

**Status**: Open
**Reported**: 2026-05-30
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**Type**: technical

## Description

Step 0 session-continuity detection in /wr-itil:work-problems has no freshness filter on .afk-run-state/iter-*.json error markers. The directory is gitignored so iter state accumulates indefinitely; an iter-4-p246.json with is_error: true written 2026-05-18 was still firing the Step 0 halt/ask gate today (2026-05-30) despite P246 having been verified-closed in commit 9eea44c on a subsequent session. The signal rule "iter-*.json containing is_error: true" needs a staleness filter (e.g. mtime-vs-latest-commit, or "no longer referenced by an open ticket", or "older than HEAD by N commits") so the orchestrator can self-discriminate stale residuals from load-bearing partial work and avoid round-tripping the user on signals that have long since been resolved. Witnessed 2026-05-30 work-problems invocation — user direction was "Proceed, but capture a problem for not being able to detect that it's stale and having to ask." Compose with P109 (the parent ADR for session-continuity detection) and P122/P126/P130 ask-discipline (false-positive asks at Step 0 dilute the Step 2.5b accumulated-question discipline).

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
- **Composes with**: P109, P122, P126, P130

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)
