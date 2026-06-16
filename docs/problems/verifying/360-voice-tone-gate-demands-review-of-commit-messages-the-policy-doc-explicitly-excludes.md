# Problem 360: Voice-tone gate demands review of commit messages the policy doc explicitly excludes

**Status**: Verifying
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

**Confirmed root cause**: The canonical external-comms gate (`packages/shared/hooks/external-comms-gate.sh`, synced byte-identically to both consumers per ADR-017) added the `git-commit-message` surface in the P082 amendment and fired *both* evaluators on it. But `docs/VOICE-AND-TONE.md` § Scope explicitly disclaims commit messages ("It does NOT apply to: ... Commit messages (covered by ADR-014 + ADR-018)"). So the voice-tone evaluator was structurally obligated to review a surface its own policy doc excludes — every fire resolved to an out-of-scope guaranteed-PASS no-op (~19K subagent tokens + one blocked-commit round-trip). The gate carried no per-evaluator surface-scope filter; the only existing per-package knob was `EXTERNAL_COMMS_LEAK_PREFILTER` (leak-scan on/off), which does not express "this surface is out of scope for this evaluator's prose review."

**Distinct from P365** (sibling, shipped 2026-06-16): P365 keys on repo *visibility* (a public-repo commit message would be external prose worth tone-gating *if the policy covered it*) and silent-passes only in private/internal repos. P360 keys on *policy scope* — the voice-tone policy never covers commit messages in *any* repo. P365's visibility precondition therefore could not close P360: in a PUBLIC repo the voice-tone no-op fire persisted.

**Fix shipped (2026-06-17)**: option (a) — conform the gate to the existing, already-confirmed § Scope exclusion (NOT option (b), amend the policy to actually voice-gate commit messages, which would reverse a confirmed exclusion and collide with ADR-014/ADR-018 ownership — explicitly out of scope). Mechanism: a new per-package config knob `EXTERNAL_COMMS_SKIP_SURFACES` (space-separated surface list, mirroring `EXTERNAL_COMMS_LEAK_PREFILTER`). When the detected surface is on the list the gate silent-passes the marker-review delegation. Voice-tone's `.conf` sets it to `git-commit-message`; risk-scorer's `.conf` leaves it empty (its leak check on commit bodies stays meaningful). Placed AFTER the leak pre-filter and BEFORE the P365 visibility precondition, so a skipped surface still gets credential/prod-URL scanning — only the prose-review deny is silenced. Recorded as ADR-028 Amendment 2026-06-17 (P360).

The serial-discovery sub-observation (the gate reveals only the NEXT unmet evaluator per blocked attempt) is left as a separate concern — not addressed here; the no-op-fire root cause is the dominant cost and is now removed for the voice-tone × commit-message pair.

### Investigation Tasks

- [x] Re-rate Priority and Effort at next /wr-itil:review-problems — deferred Priority/Effort carried; the fix is low-risk gate scope-conformance
- [x] Investigate root cause — confirmed: gate had no per-evaluator surface-scope filter; voice-tone fired on a policy-excluded surface
- [x] Create reproduction test — voice-tone bats: silent-pass on `git-commit-message` across PUBLIC/PRIVATE/INTERNAL/indeterminate-gh + surface-scoping guard; risk-scorer bats: empty-skip-list divergence guard (still denies on PUBLIC)

## Fix Released

**Status**: Verification Pending (committed, not yet released).

- **Commit**: per-evaluator `EXTERNAL_COMMS_SKIP_SURFACES` knob; voice-tone silent-passes the `git-commit-message` surface (P360).
- **Files**: `packages/shared/hooks/external-comms-gate.sh` (canonical) + synced `packages/{risk-scorer,voice-tone}/hooks/external-comms-gate.sh`; both `external-comms-evaluator.conf` files; behavioural bats in both consumers; ADR-028 amendment + compendium README entry; changeset (`@windyroad/voice-tone` + `@windyroad/risk-scorer` patch).
- **Tests**: `external-comms-gate.bats` green in both packages (voice-tone 29, risk-scorer 33); `scripts/sync-external-comms-gate.sh --check` green (byte-identity).
- **Verify after release**: in a PUBLIC adopter repo with voice-tone installed, `git commit -m "..."` no longer surfaces a `wr-voice-tone:external-comms` BLOCKED directive; the risk-scorer gate (if installed) still gates the commit message; the gh-issue/PR/npm/changeset surfaces still trigger the voice-tone gate.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P082 (verifying — added the commit-message gate this ticket evidences against), P338 (P082 Phase 2 cognitive evaluator), P257 (voice-tone hook prompt-derivation pattern), P276 (external-comms marker over-fire), P166 (double-invocation hash helper), P353 (hash-marker brittleness umbrella)

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)

- Hang-off pre-filter (capture Step 2b): 47 candidates shared ≥1 signal (voice-tone / VOICE-AND-TONE.md) — above the 5-candidate dispatch cap, so the hang-off-check subagent was skipped per the candidate-cap short-circuit; re-evaluate absorption at next `/wr-itil:review-problems`. Strongest absorb candidate: P082 (verifying) — but per run-retro Step 4a "exercised with regression" contract, regression evidence against a verifying ticket routes to a NEW ticket, leaving the `.verifying.md` alone.
- This ticket is the Step 4a regression flag for P082's verification: the gate mechanism works (blocks, unlocks on PASS marker), but the voice-tone half of the fix's intent cannot be met while the policy doc excludes the surface.
