# Problem 359: Changeset holding does not withhold shipment — held code ships with any sibling release

**Status**: Open
**Reported**: 2026-06-11
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-002
**Persona**: developer

## Description

ADR-042 Rule 7 holding (`git mv .changeset/<name>.md docs/changesets-holding/`) is described across the framework as keeping a changeset "out of the active release queue" as an R1 risk remediation (drop above-appetite residual until evidence lands). But holding only withholds version attribution + CHANGELOG entry — npm publishes main's package directory contents, so any sibling-changeset-driven release ships ALL committed code, held or not.

Evidence (2026-06-11 P220 AFK iter): P220's Step 0d fix changeset was held 2026-06-08 (scored 8/25 above 4/Low appetite on R009), yet `npm pack @windyroad/itil@0.49.3` contains every fix file (Step 0d SKILL prose ×9, `lib/check-outbound-responses-staleness.sh`, scripts wrapper, bin shim, bats) because 0.48.0/0.49.x released sibling changesets hours after the fix commit (0f58210c) landed on main.

Class-wide: all ~27 currently-held changesets whose code is committed on main are already shipping to adopters; the risk-mitigation intent of the hold (don't ship above-appetite changes) is not achieved.

Secondary symptom: ticket lifecycle keys "release" to changeset graduation, so K→V deferrals ("until next release") read as pending when the fix is de-facto released — P220 sat misclassified for 3 days.

Fix directions to investigate: (a) document the hold as attribution-only governance in ADR-042 and stop describing it as a shipment control in risk-scorer remediation prose; (b) actual shipment control would require holding the CODE off main (branch/revert) or gating publish; (c) reconcile K→V "release" semantics with de-facto shipment.

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
- **Composes with**: (none)

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)

- ADR-042 (auto-apply scorer remediations; Rule 7 holding convention), R009 (SKILL-prose floor standing risk), P220 (witnessing case — de-facto-released held changeset), P162 (graduation criteria — verifying), P228 (K→V enumerator keys on deleted-from-tree changesets — same blind spot).
- Hang-off pre-filter (capture Step 2b): 25 candidates shared ≥1 signal (ADR-042 / changesets-holding) — above the 5-candidate dispatch cap, so the hang-off-check subagent was skipped per the candidate-cap short-circuit; re-evaluate absorption at next `/wr-itil:review-problems`. Title-grep matches (list-only): P162, P177 (holding-dir 2-commit pattern), P330 (release-vehicle helper), P141, P073 (closed), P202 (closed), P206 (closed).
