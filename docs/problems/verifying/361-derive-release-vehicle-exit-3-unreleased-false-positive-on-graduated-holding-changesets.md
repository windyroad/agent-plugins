# Problem 361: wr-itil-derive-release-vehicle exit-3 "unreleased" false positive on ADR-061 graduated holding changesets

**Status**: Verification Pending
**Reported**: 2026-06-11
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-006
**Persona**: developer

## Description

wr-itil-derive-release-vehicle reports exit-3 "changeset still present in working tree (unreleased)" as a false positive when the referenced changeset is an ADR-061 holding-graduation reinstate whose code already de-facto shipped with a sibling release (P359 holding-does-not-withhold-shipment class). Observed 2026-06-11 AFK work-problems iter 1: P211's fix commit 796c9c86 is an ancestor of the @windyroad/itil 0.49.3 version bump 34d6a8f8 published on npm, the ticket's Fix Strategy carries the P330 seed `**Release vehicle**: .changeset/wr-itil-p211-iter-prompt-re-grounding.md` (seed lookup succeeded — no exit-2), yet `wr-itil-derive-release-vehicle 211` exits 3 because the graduated changeset entry is back in `.changeset/` awaiting next-release changelog attribution. The helper's presence-in-.changeset/ test conflates "changelog entry not yet drained" with "code not yet released"; under the ADR-061 Rule 5 graduation flow these diverge. Effect: K-to-V transitions on de-facto-released tickets get a wrong "unreleased" signal in transition-problem Step 6 routing; AFK iters must override manually. Likely fix: teach the helper a third check — when the changeset file is present, verify whether the fix commit is an ancestor of the latest published version bump (`git merge-base --is-ancestor` against the last "chore: version packages" commit touching the package) and exit 0 with a "de-facto-released (attribution pending)" note instead of exit 3. Composes with P330 (the helper + seed contract) and P359 (holding ships code).

## Symptoms

- `wr-itil-derive-release-vehicle <id>` exits 3 ("changeset still present in working tree (unreleased)") for a ticket whose code already shipped with a sibling release but whose changeset has been reinstated to `.changeset/` awaiting changelog attribution (ADR-061 graduation flow).
- K→V (Known Error → Verifying) routing in transition-problem Step 6 receives a wrong "unreleased" signal; AFK work-problems iterations must override it by manually verifying ancestry (witnessed 2026-06-11 iter 1, workaround in commit ed2937a8).

## Workaround

Manually verify that the fix commit is an ancestor of the latest published version bump (`git merge-base --is-ancestor <fix-sha> <version-packages-sha>`) and override the exit-3 signal by hand. Now obsolete — the helper performs this check internally.

## Impact Assessment

- **Who is affected**: developer running AFK work-problems / transition-problem K→V routing.
- **Frequency**: every K→V on a ticket whose changeset was held then graduated (ADR-061 Rule 5) while its code shipped with a sibling release (P359 class).
- **Severity**: low — wrong signal forces a manual override; no data loss, no incorrect release.
- **Analytics**: n/a.

## Root Cause Analysis

The exit-3 guard tested only `[ -f "$CHANGESET_PATH" ]` — presence of the changeset in the working tree. It treated presence as proof the code is unreleased. Under ADR-061 graduation + P359 (held code ships with any sibling release), a changeset can be present in `.changeset/` (reinstated, awaiting changelog attribution) while its code has already shipped. The two conditions — "changelog entry not yet drained" and "code not yet released" — diverge under the graduation flow, and the helper conflated them.

**Fix**: when the changeset is present, before exiting 3 the helper now finds the commit that originally added the changeset (`git log --diff-filter=A ... | tail -1`, robust to the hold→graduate rename) and tests whether it is an ancestor of the latest `chore: version packages` commit (`git merge-base --is-ancestor`). If so, the fix code shipped → emit a `de-facto-released (attribution pending)` citation block and exit 0. A genuinely-unreleased fresh changeset has its add-commit newer than the last bump, so the test is false and it correctly stays exit 3. Read-only (ADR-014 preserved); composes with P330 (the helper + seed contract) and P359.

### Investigation Tasks

- [x] Re-rate Priority and Effort at next /wr-itil:review-problems (deferred — re-rate stands)
- [x] Investigate root cause — presence-in-tree conflated with code-unreleased
- [x] Create reproduction test — behavioural bats: graduated-holding → exit 0; guard fresh-after-release → exit 3

## Fix Strategy

- **Release vehicle**: `.changeset/wr-itil-p361-derive-release-vehicle-defacto-released.md`
- Implemented in `packages/itil/scripts/derive-release-vehicle.sh` (de-facto-released exit-0 branch) + 2 new behavioural bats cases in `packages/itil/scripts/test/derive-release-vehicle.bats`. Full 15-test suite green. Architect + JTBD pre-edit reviews PASS.

## Fix Released

Released in `@windyroad/itil` (release vehicle `.changeset/wr-itil-p361-derive-release-vehicle-defacto-released.md`; de-facto-released exit-0 branch shipped in the published `derive-release-vehicle.sh`). Transitioned K→V 2026-06-27 by the `/wr-itil:work-problems` Step 6.5 post-release auto-transition callback (P228). The helper now performs the `git merge-base --is-ancestor` ancestry check internally; the manual override workaround (commit ed2937a8) is obsolete. 15/15 derive-release-vehicle.bats GREEN at ship.

**Awaiting user verification** — confirm a K→V transition on a ticket whose changeset was held-then-graduated no longer reports the spurious exit-3 "unreleased" signal.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P330, P359

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)

- **Hang-off-check candidate-cap short-circuit (P346 Phase 3)**: mechanical pre-filter surfaced 6 candidates sharing the ADR-061 signal (>5 cap) — subagent dispatch skipped per the capture-problem sub-step 2b latency bound; re-evaluate absorption at next /wr-itil:review-problems. Candidates: P082, P162, P211, P247, P308, P350 (ADR-061 body matches in open/+verifying/). Strongest semantic parents: P359 (open — changeset holding does not withhold shipment; this ticket is the helper-surface consequence of that insight) and P330 (verifying — the derive-release-vehicle helper + seed contract; cannot absorb new scope while verifying).

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-026 | proposed | derive-release-vehicle de-facto-released exit-0 path for graduated holding changesets |
