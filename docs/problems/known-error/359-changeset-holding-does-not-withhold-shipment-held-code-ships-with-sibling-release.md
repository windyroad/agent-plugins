# Problem 359: Changeset holding does not withhold shipment — held code ships with any sibling release

**Status**: Known Error
**Reported**: 2026-06-11
**Root cause identified**: 2026-06-17 (P359 RCA, this iter — see Root Cause Analysis)
**Going-forward decision**: ADR-082 (born-proposed, `human-oversight: unconfirmed`) — resolution deferred to user ratification
**Priority**: 15 (High) — Impact: 3 × Likelihood: 5 = 15. Rated at review 2026-07-02: all ~27 held changesets leaking; holds fail their purpose.
**Origin**: internal
**Effort**: L. WSJF = (15 × 1.0) / 4 = 1.875.
**JTBD**: JTBD-002
**Persona**: developer

## Description

ADR-042 Rule 7 holding (`git mv .changeset/<name>.md docs/changesets-holding/`) is described across the framework as keeping a changeset "out of the active release queue" as an R1 risk remediation (drop above-appetite residual until evidence lands). But holding only withholds version attribution + CHANGELOG entry — npm publishes main's package directory contents, so any sibling-changeset-driven release ships ALL committed code, held or not.

Evidence (2026-06-11 P220 AFK iter): P220's Step 0d fix changeset was held 2026-06-08 (scored 8/25 above 4/Low appetite on R009), yet `npm pack @windyroad/itil@0.49.3` contains every fix file (Step 0d SKILL prose ×9, `lib/check-outbound-responses-staleness.sh`, scripts wrapper, bin shim, bats) because 0.48.0/0.49.x released sibling changesets hours after the fix commit (0f58210c) landed on main.

Class-wide: all ~27 currently-held changesets whose code is committed on main are already shipping to adopters; the risk-mitigation intent of the hold (don't ship above-appetite changes) is not achieved.

Secondary symptom: ticket lifecycle keys "release" to changeset graduation, so K→V deferrals ("until next release") read as pending when the fix is de-facto released — P220 sat misclassified for 3 days.

Fix directions to investigate: (a) document the hold as attribution-only governance in ADR-042 and stop describing it as a shipment control in risk-scorer remediation prose; (b) actual shipment control would require holding the CODE off main (branch/revert) or gating publish; (c) reconcile K→V "release" semantics with de-facto shipment.

## Symptoms

- Held changesets (`git mv .changeset/<name>.md docs/changesets-holding/`) whose code is committed on main ship to adopters anyway whenever any *sibling* changeset drives a release. The hold removes only the version-bump entry + CHANGELOG line for that change, not the code.
- Known-Error → Verifying deferrals keyed to "next release" read as pending when the fix is de-facto already shipped (secondary symptom; P228 sibling).

## Workaround

Treat changeset holding as **attribution-only** — a CHANGELOG/version-attribution deferral, NOT a shipment guarantee. Do not rely on a hold to keep above-appetite *code* off adopters' installs once that code is committed to main. The actual interim above-appetite mitigation is the release-often + within-appetite-drain discipline (ADR-018 / ADR-042 Rule 1): keep residual risk within appetite per commit-set rather than committing above-appetite code and "holding" it. Already-shipped held changes are not unwound (user direction 2026-06-11).

## Impact Assessment

- **Who is affected**: adopters of any `@windyroad/*` package that has a sibling release fire while an above-appetite change sits held on main; the AFK orchestrator (relies on holding as a within-appetite remediation that does not work).
- **Frequency**: every release where a held changeset's code is already on main. Class-wide across all currently-held changesets.
- **Severity**: governance-integrity gap — the never-release-above-appetite invariant (ADR-042 Rule 1) has been silently unenforced for held-but-committed code. Bounded by the user having ratified the current state + interim discipline.
- **Analytics**: P220 witnessing case — `npm pack @windyroad/itil@0.49.3` contained every file of a changeset held 2026-06-08 (8/25, above appetite), because 0.48.0 / 0.49.x released sibling changesets hours after the fix commit (`0f58210c`) landed.

## Root Cause Analysis

**Root cause (identified 2026-06-17):** ADR-042 Rule 7's holding mechanic is `git mv .changeset/<name>.md docs/changesets-holding/` — it moves the **changeset file**, which controls only the next version bump + CHANGELOG entry. It does **not** move, revert, or branch the **code**. `npm publish` packages the package directory contents on main verbatim, so any sibling changeset that triggers a release ships all committed code on main, held or not.

The defect traces to a wording-vs-implementation gap in ADR-042: the user's direction (2026-04-22) was *"it can move the changes or feature-flag them or roll them back"* — **move the changes** (the code). The implementation interpreted this as **move the changeset** (the attribution). The two are equivalent only when no sibling release fires before the held change's blocking evidence lands; in a release-often regime that assumption rarely holds.

The framework then compounds the gap by *describing* the hold as a shipment control ("out of the active release queue") in ADR-042 Rule 7, the risk-scorer remediation prose, and the holding-area README — so agents auto-apply holding as an above-appetite remediation expecting it to withhold code.

**Going-forward resolution: deferred to ADR-082** (born-proposed, `human-oversight: unconfirmed`). Three options recorded for user ratification: (a) accept attribution-only + correct the misleading prose; (b) build a real shipment control (hold the CODE off main, or gate publish); (c) reconcile the K→V "release" lifecycle semantics (secondary symptom). Per ADR-074 no dependent work (the ADR-042 amendment, prose correction, or new mechanism) is built until an option is ratified.

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Investigate root cause — done 2026-06-17; changeset-move ≠ code-move (see above)
- [ ] Create reproduction test — deferred to the chosen-option's fix RFC (test shape depends on whether holding becomes a real shipment control)
- [ ] Ratify ADR-082 option (a)/(b)/(c) at `/wr-architect:review-decisions`, then propose the fix via the ADR-060 RFC-first path

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: (none)

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)

- **ADR-082** (`docs/decisions/082-changeset-holding-semantics-attribution-only-vs-shipment-control.proposed.md`) — born-proposed going-forward decision; options (a)/(b)/(c) deferred to user ratification.
- ADR-042 (auto-apply scorer remediations; Rule 7 holding convention), R009 (SKILL-prose floor standing risk), P220 (witnessing case — de-facto-released held changeset), P162 (graduation criteria — verifying), P228 (K→V enumerator keys on deleted-from-tree changesets — same blind spot).
- Hang-off pre-filter (capture Step 2b): 25 candidates shared ≥1 signal (ADR-042 / changesets-holding) — above the 5-candidate dispatch cap, so the hang-off-check subagent was skipped per the candidate-cap short-circuit; re-evaluate absorption at next `/wr-itil:review-problems`. Title-grep matches (list-only): P162, P177 (holding-dir 2-commit pattern), P330 (release-vehicle helper), P141, P073 (closed), P202 (closed), P206 (closed).

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-025 | proposed | Real shipment control via build-time feature toggles |
