# Problem 396: Verification-queue drain has no self-firing cadence — the verifying queue bloats unbounded (188) until a human asks

**Status**: Open
**Reported**: 2026-06-28
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-001
**Persona**: plugin-developer

## Description

The verification-queue drain (Verification Pending → Closed) has no self-firing cadence. It runs ONLY when a human invokes `/wr-retrospective:run-retro`, `/wr-itil:review-problems`, or `/wr-itil:manage-problem review`, OR when the AFK `/wr-itil:work-problems` orchestrator Step 0c pre-flight promotes it — but only under a narrow AND gate (deferred-placeholder count ≥ 3 AND `docs/problems/README.md` cadence age > 7 days). There is no session-start nudge and no scheduled trigger that surfaces the verifying queue on its own.

Consequence: in a normal session nothing drains the queue, so it accumulates without bound until a human remembers to ask, then closes in one large batch. This is the same class the `feedback_automatic_cadence_or_it_doesnt_happen` memory names — a governance action with no automatic cadence never happens; the human ends up holding the memory — and the same shape as P375 (a deferral that names a re-entry point is NOT a self-firing cadence).

## Symptoms

- The `docs/problems/verifying/` queue is currently **188 tickets** in this repo — fixes released, sitting un-closed because no surface drains them automatically.
- Witnessed batch drains close 30+ tickets at once (a separate session reported 47 → 17, closing 30), because the queue had been allowed to grow between manual invocations.
- A user has to explicitly ask to "examine the queue of problems in the verifying state" — the system never surfaces it proactively.

## Workaround

Manually invoke `/wr-itil:review-problems` or `/wr-retrospective:run-retro` periodically. Relies entirely on the human remembering — which is the defect.

## Impact Assessment

- **Who is affected**: plugin-developer / maintainer running the backlog; secondarily reporters whose fixed tickets stay open-in-tracker because the close (and the linked `gh issue close`) never fires until a drain runs.
- **Frequency**: continuous — every session that doesn't manually drain lets the queue grow.
- **Severity**: backlog truthfulness erodes (188 stale "verifying" entries); batch-drains become large and lossy-feeling; couples to P396's sibling defect where the eventual drain closes external reporters' issues automatically (see Related).
- **Analytics**: `ls docs/problems/verifying/ | wc -l` trend over time; gap between fix-release commits and the corresponding Verifying→Closed transition.

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Investigate root cause — confirm there is no SessionStart hook / scheduled trigger that surfaces the verifying queue; map the three on-demand entry points + the work-problems Step 0c AND-gate
- [ ] Decide the cadence surface — e.g. a SessionStart nudge that reports verifying-queue size + age (mirroring the architect/jtbd oversight nudges), or a tiered auto-drain trigger, per the P375 cadence-rollup design
- [ ] Create reproduction test (queue size grows across N sessions with no drain unless manually invoked)

## Dependencies

- **Blocks**: backlog truthfulness (verifying tickets reflect real un-verified state, not drain-cadence lag)
- **Blocked by**: (none)
- **Composes with**: P375 (named-re-entry vs self-firing cadence — rollup parent), P295 (ADR-043 deep-context-analysis needs automatic cadence not on-demand-only — closest cadence sibling)

## Related

Captured via /wr-itil:capture-problem. Hang-off-check skipped — candidate-cap short-circuit (sub-step 2b): the mechanical pre-filter on shared skill-refs (`/wr-retrospective:run-retro`, `/wr-itil:review-problems`, "verification queue") matched 158 open/verifying candidates (> 5 cap), so subagent dispatch was skipped per the SKILL contract; re-evaluate absorption at next /wr-itil:review-problems.

- **P375** (`docs/problems/open/375-repo-conflates-named-re-entry-point-with-self-firing-cadence.md`) — the cadence-rollup parent. This is a textbook instance of its "capability exists but nothing self-fires it" class; tracked as a rollup child, not absorbed (consistent with how P375's other instances are handled).
- **P295** (`docs/problems/verifying/295-adr-043-deep-context-analysis-needs-automatic-cadence-not-on-demand-only.md`) — closest sibling: the same on-demand-only-rot defect on the context-analysis surface. The verifying-queue drain is the same defect on the verification-close surface.
- **P253** — no house-cleaning cadence for cruft/deprecation removal — same cadence-gap family.
- **Sibling defect (capture pending this session)**: the silent evidence-based close auto-closes external reporters' GitHub issues against the "we'll close after your confirmation or 14-day quiet period" promise — the *close* side of the same broken cadence (the *trigger* side is this ticket).
- **Witness**: `docs/problems/verifying/` = 188 tickets on 2026-06-28; surfaced when the user asked why issues were being auto-closed and why they had to ask to examine the verifying queue.
