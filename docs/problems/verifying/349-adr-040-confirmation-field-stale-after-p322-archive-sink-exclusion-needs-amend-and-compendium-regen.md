# Problem 349: ADR-040 Confirmation field stale after P322 archive-sink exclusion — needs Confirmation amend + docs/decisions/README.md compendium regen

**Status**: Verification Pending
**Reported**: 2026-06-03
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Description

`docs/decisions/040-session-start-briefing-surface.proposed.md` Confirmation field currently asserts the script "reads `docs/briefing/*.md`...README.md excluded". After P322's fix landed (this iter), `check-briefing-budgets.sh` also excludes `*-archive*.md` rotation sinks. The Confirmation assertion is now stale: a future architect-review pass on any ADR-040 touchpoint will flag a [Confirmation Violation], and the ADR-077 generated compendium (`docs/decisions/README.md`) is also out of sync.

Architect verdict on the P322 fix (ALIGN-WITH-CONDITIONS) flagged this as condition C1:

> **C1 — Amend ADR-040 Confirmation (line 149).** Update the "README.md excluded" clause to also name `*-archive*.md` excluded with a parenthetical pointing at P322 + rotation-sink rationale (one sentence). Regenerate `docs/decisions/README.md` per ADR-077.

The P322 iter ran under an AFK constraint that forbade ADR edits in the same grain — queued here rather than folded into the P322 commit. The behavioural fix is in place (bats fixtures pin the contract); this ticket exists to close the doc-sync lag.

## Symptoms

- Next architect-review pass against any change touching `check-briefing-budgets.sh` (or any change that triggers the ADR-040 review path) will surface a [Confirmation Violation] on ADR-040.
- `docs/decisions/README.md` compendium misses the archive-sink carve-out row.

## Workaround

The behavioural fix is in place — only the documentation/compendium lags. Architects reading ADR-040 must read the script source for the up-to-date exclusion list until this lands.

## Impact Assessment

- **Who is affected**: (deferred to investigation)
- **Frequency**: (deferred to investigation)
- **Severity**: (deferred to investigation)
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems.
- [ ] Amend `docs/decisions/040-session-start-briefing-surface.proposed.md` Confirmation field: name `*-archive*.md` as excluded alongside `README.md`, with a parenthetical pointer to P322.
- [ ] Regenerate `docs/decisions/README.md` per ADR-077 (`wr-architect-generate-decisions-compendium && git add docs/decisions/README.md`).
- [ ] Single grain commit, paired transition Open → Verifying per ADR-022 fold-fix pattern.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P322 (the upstream behavioural fix that triggered the staleness), ADR-040 (the ADR with the stale Confirmation), ADR-077 (compendium regen contract).

## Related

(captured via /wr-itil:capture-problem on 2026-06-03 during work-problems AFK iter on P322; hang-off-check ran title-keyword pre-filter, considered P302/P322/P288 as candidates, verdict PROCEED_NEW — P322 is the upstream behavioural fix entering Verifying, this ticket carries the downstream documentation-sync that architect verdict C1 named as a separate condition the AFK constraint required to queue. expand at next investigation.)

## Fix Released

- **Fix commit**: `198ce21` — `docs(architect): amend ADR-040 — Confirmation field gains *-archive*.md exclusion (closes P349)`
- **Fix date**: 2026-06-03
- **Fix**: ADR-040 Confirmation bullet at line 149 amended to add `*-archive*.md` exclusion. New Amendment 2026-06-02 section codifies the P322 rationale. User-ratified 2026-06-03 morning via AskUserQuestion.
- **Transition**: Open → Verification Pending per ADR-022 P143 fold-fix (RCA + Fix Strategy + Workaround documented inline; fix landed same iter).
- **No release vehicle**: docs-only ADR amendment; no changeset needed (governance doc, not @windyroad/* package source).
