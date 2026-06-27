# Problem 396: the VP carve-out holds changesets for already-shipped (verifying) code indefinitely — pointless changelog stranding

**Status**: Open
**Reported**: 2026-06-28
**Priority**: 9 (High) — Impact: 3 x Likelihood: 3
**Origin**: corrective-feedback (user, 2026-06-28)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-007
**Persona**: plugin-developer

## Description

The ADR-061 Rule 2 Verification-Pending carve-out marks a held changeset `vp-blocked` (skip graduation) whenever its joined problem ticket is in `.verifying.md`. But a `.verifying.md` ticket means **the fix already shipped** (`## Fix Released` populated) — the code is live on npm; only the changelog-attribution changeset is held. The carve-out therefore strands the changelog entry in `docs/changesets-holding/` **indefinitely** (until the ticket goes verifying → closed, which itself has no automatic cadence — P375 class), so the published CHANGELOG never attributes a fix that is demonstrably live.

User correction 2026-06-28: *"For the ones that I've already shipped, we shouldn't be holding their changesets. There's no point in holding that when the code is shipped."* (Sharpens the earlier P359 observation: *"changesets-holding doesn't actually hold anything except the changelog notes; the code got deployed and released."*)

Witnessed 2026-06-28: `wr-risk-scorer-evaluate-graduation` reported **16 vp-blocked** held changesets — all with tickets in verifying (code shipped) — including the 4-changeset P350 brief-before-ID cohort, P352, P204, P082, P208, P220, P344, P308, P205, P313, P351, P358, P214. Their changelog attribution is stranded.

**Why the carve-out exists vs why it over-fires.** ADR-061 Rule 2 protects against releasing a changeset for a verifying fix that might later be **rejected** (flipped back to known-error) — you can't un-release a changelog claim. But that protection is moot once the **code** has shipped: the ship has already sailed for the behaviour; holding only the changelog makes the CHANGELOG *inaccurate* (omits a live fix) rather than protecting anything. The carve-out conflates "don't auto-revert a verifying commit" (correct) with "don't graduate a verifying changeset" (over-broad for already-shipped code).

**Candidate fix:** amend the ADR-061 Rule 2 VP carve-out so the graduation evaluator's `vp-blocked` status fires only when the fix is **NOT yet shipped** (no `## Fix Released`); a verifying ticket whose code already shipped should be `resolved` (graduate the changelog-attribution changeset) rather than indefinitely held. OR a periodic "drain shipped-code holds" sweep. The rejection-risk residual (a later flip-back makes one changelog line stale) is accepted per user direction — rare, and correctable.

## Symptoms

- `wr-risk-scorer-evaluate-graduation` → `vp_blocked=16` on 2026-06-28, all tickets in verifying.
- `docs/changesets-holding/` accumulates shipped-code changesets that never graduate.
- Published CHANGELOG omits fixes that are live on npm.

## Workaround

Manually graduate the vp-blocked shipped-code holds (overriding ADR-061 Rule 2 per user direction) so the next release publishes the changelog attribution — executed 2026-06-28 for the 16-entry backlog (see the graduation commit).

## Impact Assessment

- **Who is affected**: plugin-developer (changelog accuracy / release hygiene) + adopters reading the CHANGELOG to know what shipped. JTBD-007 (Keep Plugins Current) — adopters can't see fixes that are live.
- **Frequency**: every verifying ticket whose changeset was held (16 currently).
- **Severity**: no functional break (code is live) — but changelog inaccuracy + unbounded holding-area growth + the P375 no-cadence rot (verifying→closed never auto-fires).
- **Analytics**: (deferred)

## Root Cause Analysis

(leading hypothesis above — ADR-061 Rule 2 VP carve-out conflates the no-auto-revert protection with a no-graduate rule that over-fires on already-shipped code.)

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Amend ADR-061 Rule 2: vp-blocked only when fix NOT yet shipped; shipped-code verifying → graduate the changelog changeset (architect review + user ratification per P357)
- [ ] Update `wr-risk-scorer-evaluate-graduation` (`packages/risk-scorer/scripts/evaluate-graduation.sh`) to read `## Fix Released` and classify shipped-code verifying as resolved
- [ ] Behavioural test for the shipped-code-graduates / unshipped-verifying-holds split
- [ ] Decide the verifying→closed cadence gap (P375 sibling) so holds don't re-strand

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P359 (the originating observation — changesets-holding holds only changelog for shipped code), P375 (nothing-triggers-the-work — the verifying→closed no-cadence that strands holds), ADR-061 (Rule 2 VP carve-out — the decision to amend), ADR-042 (Rule 2b sibling revert carve-out)

## Related

- **P359** — sibling/originating observation; this ticket is the framework-fix for the class.
- **ADR-061** Rule 2 — the VP carve-out being amended.
- `packages/risk-scorer/scripts/evaluate-graduation.sh` — the evaluator emitting `vp-blocked`.
- (captured via /wr-itil:capture-problem; PROCEED_NEW — distinct framework-fix from P359's observation + P375's cadence meta.)
