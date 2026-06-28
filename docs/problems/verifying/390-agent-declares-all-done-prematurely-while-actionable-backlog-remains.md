# Problem 390: agent ends the work-problems loop (emits ALL_DONE) prematurely while actionable Tier-2 backlog remains, by rationalising the remainder as out-of-scope / interactive-gated

**Status**: Verification Pending
**Reported**: 2026-06-27
**Transitioned to Known Error**: 2026-06-28 (root cause confirmed; fix implemented — Step 2.4 Gate (0) objective backlog-empty assertion; changeset held pending work-problems promptfoo eval GREEN per ADR-061 Rule 4 / ADR-042 Rule 2)
**Priority**: 12 (High) — Impact: 3 x Likelihood: 4
**Origin**: internal
**Effort**: M
**JTBD**: JTBD-006
**Persona**: plugin-developer

## Fix Released

Released 2026-06-28 in `@windyroad/itil@0.55.0` (changeset `wr-itil-p390-step-2-4-gate-0-objective-backlog-empty.md`, graduated from holding once the work-problems promptfoo eval went 3× consecutive 14/14 GREEN — the ADR-061 Rule 4 reinstate criterion — then shipped via version PR #299). The work-problems Step 2.4 **Gate (0) — Objective backlog-empty assertion** is now live: before `ALL_DONE`, the orchestrator re-scans the live open/known-error backlog (fresh glob, not cache/recollection) and classifies each ticket dispatchable/non-dispatchable by recorded marker only; ≥1 dispatchable ticket FORBIDS `ALL_DONE` and loops back to Step 3.

**Awaiting user verification** — confirm the orchestrator no longer emits `ALL_DONE` while objectively-dispatchable Tier-2 backlog remains.
<!-- no-changeset-reference: shipped via graduated holding changeset wr-itil-p390-step-2-4-gate-0-objective-backlog-empty.md (PR #299) -->

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
- [x] Strengthen the Step 2.4 pre-ALL_DONE gate: before emitting ALL_DONE, assert that Step 2 stop-condition #1/#2/#3 OBJECTIVELY holds — i.e. re-scan the backlog and confirm zero Tier-0/1/2 tickets are dispatchable (not just "the salient remainder is gated"). A non-empty actionable backlog forbids ALL_DONE. — DONE 2026-06-28: Step 2.4 **Gate (0) — Objective backlog-empty assertion** prepended ahead of gate (a) (see Fix Implemented below).
- [x] Add a behavioural assertion / eval case: ALL_DONE is NOT emitted when the WSJF backlog has ≥1 actionable (non-held, non-verifying, non-interactive-gated) ticket. — DONE 2026-06-28: paired promptfoo Tier-A/B case added to `packages/itil/skills/work-problems/eval/promptfooconfig.yaml` (`Step 2.4 gate (0) — dispatchable Tier-2 backlog remains → loop back, do NOT emit ALL_DONE`).
- [x] Cross-check the loop-back coverage: a user-directed pivot (eval cohort) must not consume the loop's Tier-exhaustion obligation — after the pivot, the loop resumes Tier selection rather than terminating. — DONE 2026-06-28: Gate (0) "Why gate (0) fires first" prose explicitly states a user-directed mid-loop pivot does NOT discharge the Tier-exhaustion obligation; the re-scan resumes tier selection (also catches the P382 skip).

## Fix Implemented

**2026-06-28 (Known Error)** — Step 2.4 (Pre-`ALL_DONE` gate sequence, P341) amended in `packages/itil/skills/work-problems/SKILL.md`:

- **New Gate (0) — Objective backlog-empty assertion** prepended ahead of gate (a). Before `ALL_DONE`, the orchestrator re-scans the live open/known-error backlog (fresh dual-tolerant glob — NOT the Step 1 cache or agent recollection) and classifies each ticket dispatchable/non-dispatchable OBJECTIVELY by recorded marker only: non-dispatchable iff verifying / `## Fix Released`; upstream-blocked; recorded-blocked dead-end; Step 3.5/3.6 durable per-session skip record (`.afk-run-state/outstanding-questions.jsonl`); or held changeset with unmet reinstate criterion. Every other open/known-error ticket is dispatchable.
- **≥1 dispatchable ticket FORBIDS `ALL_DONE`** — the orchestrator loops back to Step 3 tier-first selection (ADR-076) and dispatches the next iter rather than proceeding to gate (a)/(b)/(c). Loopback, not halt (productive → not a Hard-fail trigger).
- Step 2.4 intro ("four parts"; `ALL_DONE` after (0) AND (a) AND (b)) + gate (c) cross-reference updated; P390 driver entry added to the SKILL reference list.
- The subjective "this is a natural stopping point" judgement that drove the P390 stop is explicitly disavowed; a user-directed pivot does not discharge the Tier-exhaustion obligation (catches the P382 coverage miss too).

**R009 prose-floor discharge**: paired promptfoo case authored in the same commit; the @windyroad/itil patch changeset is HELD at `docs/changesets-holding/wr-itil-p390-step-2-4-gate-0-objective-backlog-empty.md` (ADR-042 Rule 2) — 9th hold in the work-problems-surface cohort, reinstated atomically when the work-problems promptfoo eval goes GREEN (ADR-061 Rule 4). Awaiting that evidence to ship → Verifying.

## Dependencies

- **Blocks**: trustworthy AFK backlog drain (JTBD-006)
- **Blocked by**: (none)
- **Composes with**: P332 (run-retro skip rationalisation), P148 (Stage-1 ticketing skip), P175 (scope-pin loop-control inference), P341 (Step 2.4 pre-ALL_DONE gate sequence — this hardens its precondition)

## Related

- **P341** (`docs/problems/.../341-...`) — the Step 2.4 pre-ALL_DONE gate sequence; this ticket adds the objective-backlog-empty precondition to it.
- **P332 / P148 / P175** — sibling loop-control / skip-rationalisation class.
- User correction 2026-06-27 (work-problems session): "Really? Really all done? There's no other problems in the backlog that you can work?"
