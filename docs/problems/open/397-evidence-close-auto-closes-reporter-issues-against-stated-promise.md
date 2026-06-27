# Problem 397: Silent evidence-based close auto-closes external reporters' GitHub issues against the confirmation/14-day promise we post

**Status**: Open
**Reported**: 2026-06-28
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-301
**Persona**: plugin-user

## Description

When a Verification Pending ("verifying") ticket is closed, two things happen that compose into a trust-boundary defect:

1. **The close is silent and evidence-based, not reporter-confirmed.** `/wr-retrospective:run-retro` Step 4a closes verifying tickets on in-session evidence (test invocations, dependent commits, hook firings) as a "silent agent action per P135 / ADR-044" — no per-ticket `AskUserQuestion`. The framework has resolved "in-session evidence = verified."
2. **The close propagates to the external GitHub issue.** `/wr-itil:update-upstream` runs `gh issue close` on the Verifying → Closed transition for both reported-upstream tickets (Step 5b) and inbound-reported `**Origin**: inbound-reported (#NN)` tickets (the P363 inbound leg).

The contradiction: the fix-released comment we post to reporters (the Known Error → Verification Pending template) explicitly promises *"We'll close this issue after **your** confirmation OR after a 14-day quiet period."* But the drain closes on **our** in-session evidence — reporter-independent, often within days. So a reporter watches their GitHub issue get auto-closed before they confirmed and before 14 days elapsed, directly contradicting the commitment in our own comment.

ADR-044's "evidence = verified" framework-resolution is defensible for *internal* tickets (the maintainer is both author and verifier). It crosses a different trust boundary when the close auto-propagates to an *external* party's issue and overrides a promise we made them. The reporter is not the one who verified, and the quiet-period we cited never ran.

## Symptoms

- A reporter files an issue; we post "we'll close after your confirmation or 14 days"; days later the issue is auto-closed by an evidence-based drain with a "closed after verification" comment the reporter never triggered.
- The user's observed alarm: "Why are issues being automatically closed?" — reporters' issues closing without their confirmation.

## Workaround

Exclude inbound-reported / reported-upstream tickets from the silent evidence-close pass by hand (close them only after the reporter confirms or the 14-day quiet period genuinely elapses). No mechanism enforces this today.

## Impact Assessment

- **Who is affected**: plugin-user (external reporters) whose issues are closed before they confirm; secondarily the maintainer's credibility on a trust-ramp product.
- **Frequency**: every inbound-reported / reported-upstream verifying ticket caught by an evidence-based drain before reporter confirmation or the 14-day window.
- **Severity**: breaks an explicit promise made to an external party (JTBD-301 reporter feedback loop); reputational, distinct from a functional break. Compounded by P396 (the drain runs in large delayed batches, so many issues close at once).
- **Analytics**: diff `gh issue close` events on inbound/upstream issues against (a) whether a reporter-confirmation comment exists and (b) whether 14 days elapsed since the fix-released comment.

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Investigate root cause — confirm run-retro Step 4a close-on-evidence reaches the `gh issue close` leg for inbound/upstream tickets without a reporter-confirmation or elapsed-quiet-period gate
- [ ] Decide the fix — e.g. evidence-close may transition the LOCAL ticket but MUST NOT `gh issue close` an external reporter's issue until reporter-confirmed OR the 14-day quiet period actually elapses; OR change the promise wording to match the evidence-close behaviour (less good — the promise is the right one)
- [ ] Create reproduction test (inbound verifying ticket + in-session evidence → assert the external issue is NOT auto-closed before confirmation/quiet-period)

## Dependencies

- **Blocks**: trustworthy reporter feedback loop (JTBD-301 — reporters' issues reflect their own verification, not our internal evidence)
- **Blocked by**: (none)
- **Composes with**: P363 (inbound fix-released verdict + `gh issue close` leg — the close mechanism), P396 (the drain's missing cadence — the trigger side of the same broken loop)

## Related

Captured via /wr-itil:capture-problem. Hang-off-check skipped — candidate-cap short-circuit (sub-step 2b): mechanical pre-filter on shared signals (P363 / `/wr-itil:update-upstream` / verifying-close / ADR-044) matched > 5 open/verifying candidates, so subagent dispatch was skipped per the SKILL contract; re-evaluate absorption at next /wr-itil:review-problems. Nearest parent is P363 (it owns the inbound `gh issue close` leg) but this defect is the close-policy trust boundary, not P363's leg-correctness — surfaced for review-time absorption decision.

- **P363** (`docs/problems/known-error/363-inbound-reported-tickets-never-receive-fix-released-verdict-on-originating-issue.md`) — owns the inbound fix-released verdict + `gh issue close` machinery. This ticket is the *should-we-auto-close-at-all* policy question sitting on top of P363's *how-to-close* mechanism.
- **P396** (`docs/problems/open/396-verification-queue-drain-has-no-self-firing-cadence-bloats-to-188.md`) — the trigger side: the drain has no cadence, so it fires late and in big batches. This ticket is the close side: when it does fire, it closes external issues against the stated promise.
- **P048** (`docs/problems/verifying/048-manage-problem-does-not-detect-verification-candidates.md`) — owns the 14-day quiet-period default that this defect's promise cites.
- **Witness**: surfaced 2026-06-28 when the user asked "Why are issues being automatically closed?" after a reporter saw issue auto-closure. The fix-released comments posted this session on #274 / #284 / #282 each carry the "your confirmation OR 14-day quiet period" promise the evidence-close would override.
