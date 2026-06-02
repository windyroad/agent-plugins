# Problem 333: /wr-itil:work-problems Step 0 session-continuity detection has no staleness filter on .afk-run-state/iter-*.json error markers — stale residuals false-positive the halt/ask gate indefinitely

**Status**: Verification Pending
**Reported**: 2026-05-30
**Fix Released**: pending (held in `@windyroad/itil` patch changeset `wr-itil-p333-iter-error-marker-staleness-filter.md`)
**Priority**: 6 (Medium) — Impact: 2 (Minor — false-positive halt; recoverable via explicit user direction "Proceed") × Likelihood: 3 (Possible — fires on every session-start after any iter that left an error marker until the staleness gap is closed)
**Origin**: internal
**Effort**: M (Step 0 SKILL.md amendment + staleness predicate + behavioural bats)
**WSJF**: 3.0 (re-rated 2026-05-31; was placeholder I=3×L=1; honest grounding lands at S6/L3/M)

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

Step 0 session-continuity detection at `packages/itil/skills/work-problems/SKILL.md` line 67 enumerated `.afk-run-state/iter-*.json` error markers (`is_error: true` OR `api_error_status >= 400`) with no freshness predicate. Because `.afk-run-state/` is gitignored, iter state accumulates across sessions indefinitely; any iter-error-marker written during a prior session that hit quota / API error remained in the working tree until manually removed. The Step 0 enumerator treated every accumulated marker as a load-bearing partial-work signal regardless of age, so the moment ≥1 stale residual existed the AFK fail-safe routed the loop to halt-with-report (Rule 6) or the interactive AskUserQuestion branch (Rule 1) — even when the prior session's work had since been verified-closed via a subsequent commit. Witnessed instance: iter-4-p246.json (mtime 2026-05-18, P246 Known-Error fix attempt) was still firing the gate on 2026-05-30 despite P246 being verified-closed in commit 9eea44c on an intervening session.

### Fix

Amend the Step 0 enumerator at SKILL.md line 67 to gate the load-bearing signal on a staleness predicate: a marker is load-bearing only if its mtime is newer than HEAD's commit time (`git log -1 --format=%at HEAD`) OR within the last 24h, whichever is more permissive. Stale residuals (older than HEAD AND older than 24h) are skipped silently. Directional asymmetry: fresh = halt, stale = silent skip. To preserve JTBD-006 audit-trail outcome (every action taken during AFK mode should be traceable via the progress summary), when ≥1 stale marker is silently skipped the iter summary emits a one-line annotation naming the count, the oldest marker's filename, and a recovery command.

### Investigation Tasks

- [x] Re-rate Priority and Effort at next /wr-itil:review-problems (done 2026-05-31; landed at S6/L3/M, WSJF 3.0)
- [x] Investigate root cause (above)
- [x] Create reproduction test (`packages/itil/skills/work-problems/test/work-problems-step-0-iter-error-staleness.bats` — contract-assertion bats per ADR-037)

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P109, P122, P126, P130

## Related

- **RFC-015** — problem-traced RFC for the staleness-filter fix (ADR-071/072/073 unconditional RFC-first compliance, modelled on RFC-007's retro-fit pattern).
- **ADR-019 in-place amendment** — DEFERRED to a follow-up ticket per architect advisory (this iter's no-ADR-edits scope constraint). The amendment paragraph cites the staleness predicate at ADR-019 lines 93–106 so the contract document and SKILL.md don't drift; advisory-not-load-bearing per architect (a78b6cbb7155568bb 2026-06-03).
- **Existing bats fixture extension** — DEFERRED per the same scope constraint. `packages/itil/skills/work-problems/test/work-problems-preflight-session-continuity.bats` (existing) should gain one assertion that the SKILL.md prose for the iter-*.json row also names "staleness" / "stale" / "mtime" so the contract test is complete vs SKILL.md after this amendment. The new fixture `work-problems-step-0-iter-error-staleness.bats` covers the staleness-specific assertions; the cross-fixture coupling is advisory-not-load-bearing per architect.

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-015 | proposed | P333 — `.afk-run-state/iter-*.json` error-marker staleness filter for /wr-itil:work-problems Step 0 |
