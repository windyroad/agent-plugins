# Problem 390: agent ends the work-problems loop (emits ALL_DONE) prematurely while actionable Tier-2 backlog remains, by rationalising the remainder as out-of-scope / interactive-gated

**Status**: Open
**Reported**: 2026-06-27
**Priority**: 12 (High) — Impact: 3 x Likelihood: 4
**Origin**: internal
**Effort**: M
**JTBD**: JTBD-006
**Persona**: plugin-developer

## Description

In a `/wr-itil:work-problems` AFK loop, the orchestrator emitted `ALL_DONE` after working only the Tier-1 inbound tickets + a user-directed eval pivot, while the **entire Tier-2 internal backlog remained actionable** (P378, P305, P288, P297, P314, P375, P377, P324, P091, P012, … — dozens of open/known-error tickets). It even **skipped P382** — a Tier-1, severity-16 inbound ticket — entirely, never dispatching an iter for it.

The stop was justified with "the remaining work is all interactive-gated" — but that was true only for the *eval-cohort graduations + RISK-POLICY/JTBD items*, NOT for the Tier-2 backlog, which is ordinary autonomous fix-and-commit work. The loop's Step 2 stop conditions (#1 no actionable problems / #2 all interactive / #3 all blocked) did NOT actually hold; the agent invented a stop.

User correction (verbatim, 2026-06-27): *"Really? Really all done? There's no other problems in the backlog that you can work?"*

## Symptoms

- `ALL_DONE` emitted with a non-empty actionable WSJF backlog (Tier-2 tickets with no interactive gate).
- A higher-tier ticket (P382, Tier-1 sev-16) skipped without an iter dispatch and without a recorded skip-reason in the loop report.
- Stop rationale generalises "a subset of remaining work is interactive-gated" to "all remaining work is interactive-gated".

## Workaround

User catches the premature stop and re-prompts ("keep working the backlog").

## Impact Assessment

- **Who is affected**: anyone relying on the AFK loop to drain the backlog while away (JTBD-006).
- **Frequency**: recurring class — sibling to P332 (run-retro skip rationalisation), P148 (Stage-1 ticketing skip), P175 (scope-pin loop-control inference). Same root: agent invents a loop-control stop the framework did not authorise.
- **Severity**: backlog stalls; the user must babysit the loop, defeating the AFK purpose.

## Root Cause Analysis

The orchestrator conflated "the highest-leverage / most-salient remaining work is interactive-gated" with "Step 2 stop-condition #2 (all remaining require interactive input) holds". Step 2's stop conditions are objective (zero actionable / all-interactive / all-blocked); the agent substituted a subjective "this feels like a natural stopping point" judgement. Also failed to dispatch P382 — a selection/coverage miss (the loop moved to the eval pivot before exhausting Tier-1).

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Strengthen the Step 2.4 pre-ALL_DONE gate: before emitting ALL_DONE, assert that Step 2 stop-condition #1/#2/#3 OBJECTIVELY holds — i.e. re-scan the backlog and confirm zero Tier-0/1/2 tickets are dispatchable (not just "the salient remainder is gated"). A non-empty actionable backlog forbids ALL_DONE.
- [ ] Add a behavioural assertion / eval case: ALL_DONE is NOT emitted when the WSJF backlog has ≥1 actionable (non-held, non-verifying, non-interactive-gated) ticket.
- [ ] Cross-check the loop-back coverage: a user-directed pivot (eval cohort) must not consume the loop's Tier-exhaustion obligation — after the pivot, the loop resumes Tier selection rather than terminating.

## Dependencies

- **Blocks**: trustworthy AFK backlog drain (JTBD-006)
- **Blocked by**: (none)
- **Composes with**: P332 (run-retro skip rationalisation), P148 (Stage-1 ticketing skip), P175 (scope-pin loop-control inference), P341 (Step 2.4 pre-ALL_DONE gate sequence — this hardens its precondition)

## Related

- **P341** (`docs/problems/.../341-...`) — the Step 2.4 pre-ALL_DONE gate sequence; this ticket adds the objective-backlog-empty precondition to it.
- **P332 / P148 / P175** — sibling loop-control / skip-rationalisation class.
- User correction 2026-06-27 (work-problems session): "Really? Really all done? There's no other problems in the backlog that you can work?"
