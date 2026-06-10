# Problem 360: Voice-tone gate demands review of commit messages the policy doc explicitly excludes

**Status**: Open
**Reported**: 2026-06-11
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-001
**Persona**: developer

## Description

The external-comms gate (P082 surface) blocks `git commit` until `wr-voice-tone:external-comms` has reviewed the commit-message draft — but `docs/VOICE-AND-TONE.md` § Scope explicitly excludes commit messages ("It does NOT apply to: ... Commit messages (covered by ADR-014 + ADR-018)", lines 66-68). Every commit-message voice-tone review is therefore a guaranteed-PASS no-op: the agent reads the policy, declares the surface out of scope, and emits PASS.

Evidence (2026-06-11 P220 AFK iter 2): two consecutive commit-message drafts each required a `wr-voice-tone:external-comms` subagent round-trip (~19K tokens each); both verdicts opened with "Out of scope — docs/VOICE-AND-TONE.md § Scope explicitly excludes commit messages" before emitting `EXTERNAL_COMMS_VOICE_TONE_VERDICT: PASS`. The gate also discovers requirements serially — each blocked `git commit` attempt reveals only the NEXT unmet evaluator (risk → voice-tone → pipeline score), costing three blocked attempts to learn three requirements.

Inconsistency to resolve (either direction): (a) the gate stops demanding voice-tone review on the `git-commit-message` surface (policy-excluded → skip evaluator), or (b) `docs/VOICE-AND-TONE.md` gains a commit-message section so the review is meaningful (this direction belongs to P082's intent — voice-gating commit messages — and would amend the policy doc's scope exclusion). Also worth fixing independently: the gate's block message could enumerate ALL unmet evaluators at once instead of serial discovery.

## Symptoms

(deferred to investigation)

## Workaround

Accept the no-op round-trip: delegate to `wr-voice-tone:external-comms`, receive the out-of-scope PASS, retry the commit.

## Impact Assessment

- **Who is affected**: (deferred to investigation)
- **Frequency**: every commit whose message draft has not been pre-reviewed — multiple times per AFK iter
- **Severity**: (deferred to investigation)
- **Analytics**: ~19K subagent tokens + one blocked-commit round-trip per no-op review, ×2 observed this iteration

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Investigate root cause
- [ ] Create reproduction test

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P082 (verifying — added the commit-message gate this ticket evidences against), P338 (P082 Phase 2 cognitive evaluator), P257 (voice-tone hook prompt-derivation pattern), P276 (external-comms marker over-fire), P166 (double-invocation hash helper), P353 (hash-marker brittleness umbrella)

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)

- Hang-off pre-filter (capture Step 2b): 47 candidates shared ≥1 signal (voice-tone / VOICE-AND-TONE.md) — above the 5-candidate dispatch cap, so the hang-off-check subagent was skipped per the candidate-cap short-circuit; re-evaluate absorption at next `/wr-itil:review-problems`. Strongest absorb candidate: P082 (verifying) — but per run-retro Step 4a "exercised with regression" contract, regression evidence against a verifying ticket routes to a NEW ticket, leaving the `.verifying.md` alone.
- This ticket is the Step 4a regression flag for P082's verification: the gate mechanism works (blocks, unlocks on PASS marker), but the voice-tone half of the fix's intent cannot be met while the policy doc excludes the surface.
