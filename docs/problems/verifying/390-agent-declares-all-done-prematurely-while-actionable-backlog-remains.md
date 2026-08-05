# Problem 390: agent ends the work-problems loop (emits ALL_DONE) prematurely while actionable Tier-2 backlog remains, by rationalising the remainder as out-of-scope / interactive-gated

**Status**: Verification Pending
**Reported**: 2026-06-27
**Transitioned to Known Error**: 2026-06-28 (root cause confirmed; fix implemented — Step 2.4 Gate (0) objective backlog-empty assertion; changeset held pending work-problems promptfoo eval GREEN per ADR-061 Rule 4 / ADR-042 Rule 2)
**Reopened**: 2026-07-05 (Verifying → Known Error — the shipped Gate (0) self-assessment is insufficient; user directs pursuing Claude Code's native `/goal` as the fix mechanism. See ## Reopened and the rewritten ## Fix Strategy below.)
**Priority**: 12 (High) — Impact: 3 x Likelihood: 4
**Origin**: internal
**Effort**: M
**JTBD**: JTBD-006
**Persona**: plugin-developer

## Reopened (2026-07-05)

Reopened Verifying → Known Error at user direction. The Gate (0) fix (below, shipped in `@windyroad/itil@0.55.0`) is a **self-assessment** mechanism: the same agent that is prone to inventing a subjective stop is also the one asked to re-scan the backlog and honestly forbid its own `ALL_DONE`. That is structurally the same actor deciding both "should I stop?" and "is stopping justified?" — the exact conflation named in the Root Cause. An independent evaluator is the stronger fix.

User direction (verbatim, 2026-07-05): *"can you reopen the P390. the goal skill does exist https://code.claude.com/docs/en/goal. Fucking use it"* — and the agent's prior-session assertion that `/goal` "does not exist" was wrong (searched only the local plugin cache + repo, never the product docs; recurrence of the "assert a blocker without empirical verification" class, memory `feedback_verify_infra_constraints_before_asserting_blocker`).

## Prior fix attempt — Gate (0) self-assessment (shipped 0.55.0, insufficient)

Released 2026-06-28 in `@windyroad/itil@0.55.0` (changeset `wr-itil-p390-step-2-4-gate-0-objective-backlog-empty.md`, graduated from holding once the work-problems promptfoo eval went 3× consecutive 14/14 GREEN — the ADR-061 Rule 4 reinstate criterion — then shipped via version PR #299). The work-problems Step 2.4 **Gate (0) — Objective backlog-empty assertion**: before `ALL_DONE`, the orchestrator re-scans the live open/known-error backlog (fresh glob, not cache/recollection) and classifies each ticket dispatchable/non-dispatchable by recorded marker only; ≥1 dispatchable ticket FORBIDS `ALL_DONE` and loops back to Step 3. Retained as a first-line objective check, but insufficient on its own (self-assessment; see ## Reopened).
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
- [x] **(reopened fix)** Implement the `/goal` loop-anchor per ## Fix Strategy — set a `/goal` completion condition at work-problems / work-problem loop start; likely a short ADR for the shared loop-control contract change + eval coverage — DONE 2026-07-06: ADR-094 + RFC-047 + STORY-040 + work-problems Step 0e + Gate (0) printed-evidence amendment + singular-skill note + paired promptfoo cases (see ## Fix Implemented (reopened) below).
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

## Fix Implemented (reopened) — 2026-07-06

Implemented per the Fix Strategy below, decision authority **ADR-094** (`docs/decisions/094-afk-loops-anchor-completion-with-native-goal-evaluator.proposed.md`), traced **RFC-047 → STORY-040** (placed on STORY-MAP-002):

- **work-problems Step 0e — `/goal` loop-anchor**: canonical goal condition (verbatim, coupled to the Gate (0) table shape), anchor-guaranteed headless launch one-liner (`claude -p "/goal <condition carrying the skill invocation>"`), interactive nudge-and-proceed fallback (one line, never halts, no `AskUserQuestion`), goal on the orchestrator session only (never iter subprocesses).
- **Step 2.4 Gate (0) amendment**: the dispatchable/non-dispatchable classification MUST be PRINTED as a table in turn output — the `/goal` external evaluator judges only surfaced transcript evidence (ADR-026). New "Gate (0) × Step 0e" paragraph: under an active goal, `ALL_DONE` is independently confirmed per turn; the anchor is one-directional (a cleared/absent goal never relaxes Gate (0)).
- **work-problem (singular)**: headless anchor shape documented for single-ticket runs.
- **Open questions resolved**: goal lives on the orchestrator session (iters end naturally after one ticket per ADR-032/P077/P084); the turn-bound clause ("or stop after 100 turns") does not conflict with P160/ADR-093 quota pacing (pacing stretches wall-clock within turns, not turn count); eval coverage = two paired promptfoo Tier-A/Tier-B cases (unanchored-start nudge-and-proceed; printed-evidence requirement).
- **Empirical grounding (ADR-026)**: probed 2026-07-06 on v2.1.201 — no `--goal` CLI flag; Skill tool rejects it ("goal is a UI command, not a skill... cannot be invoked via the Skill tool"); headless `claude -p "/goal"` recognized. The agent cannot set the goal mid-session; the anchor is launch-set or user-set.

Ratification of ADR-094 / RFC-047 / STORY-040 / STORY-MAP-002 drift-reopen queued to the interactive drain (ADR-066/ADR-090, `human-oversight: unconfirmed`). Changeset ships with the paired eval evidence per ADR-061 Rule 4.

## Fix Strategy — anchor the loop with Claude Code's native `/goal`

Use the built-in [`/goal`](https://code.claude.com/docs/en/goal) command (Claude Code ≥ v2.1.139) as the loop-continuation mechanism. This is the right primitive precisely because it removes the self-assessment conflation the Gate (0) fix could not:

**Verified mechanics** (from the docs):
- `/goal <condition>` sets a session-scoped completion condition and starts a turn immediately with the condition as the directive.
- `/goal` is a **wrapper around a prompt-based Stop hook**. After *every* turn, the condition + conversation-so-far are sent to the configured small fast model (Haiku by default) — a **separate evaluator, not the working agent** — which returns yes/no + a short reason. A "no" forces another turn with the reason as guidance; a "yes" clears the goal.
- The evaluator **does not run tools**; it judges only what the agent has surfaced in the transcript. So the condition must be provable from the agent's own output.
- Works non-interactively: `claude -p "/goal <condition>"` runs the loop to completion in one invocation. Requires the workspace trust dialog accepted and hooks enabled (unavailable under `disableAllHooks` / `allowManagedHooksOnly`).

**Why this fixes P390**: the stop decision moves from the working agent (which invents subjective stops — the Root Cause) to an independent per-turn evaluator. The agent can no longer rationalise `ALL_DONE`; it must surface transcript evidence that the goal condition holds, and a fresh model judges it. Gate (0) becomes the objective *self*-check the agent runs each turn; `/goal` is the *external* check that the agent actually keeps turning until Gate (0) genuinely passes.

**Design sketch** (to be worked — not yet implemented):
1. When `/wr-itil:work-problems` (and singular `/wr-itil:work-problem`) starts the loop, set a `/goal` whose condition is provable from a backlog re-scan the agent surfaces each turn — e.g. *"a fresh `docs/problems/{open,known-error}/` WSJF re-scan printed in the transcript shows zero dispatchable tickets (each remaining ticket is verifying / upstream-blocked / recorded-blocked / durably-skipped / held), OR stop after N turns."* Include the turn-bound clause the docs recommend.
2. The agent's per-turn output must include the Gate (0) re-scan table so the evaluator has evidence to judge against — tie the condition to that surfaced artefact.
3. Decide storage/ownership: `/goal` is session-scoped native state (restored on `--resume`/`--continue`), so no new `.afk-run-state/` marker is needed for the goal itself; the SKILL just issues the `/goal` set at loop start and `/goal clear` is implicit on completion.
4. Generalisation candidates once proven here: the run-retro loop (P332) and any other AFK drain loop in the same failure-class (P148, P175).

**Open questions**: interaction with the existing `claude -p` per-iter subprocess dispatch (does the goal live on the orchestrator session, the iter subprocess, or both?); whether the turn-bound clause conflicts with quota-pacing (P160); eval coverage for the `/goal` path. Resolve during fix work; likely wants a short ADR for "AFK loops set a `/goal` completion condition" since it changes the loop-control contract shared across skills.
## Story Maps

| ID | Title | Status |
|----|-------|--------|
| STORY-MAP-002 | STORY-MAP-002: Decompose a fix into coordinated changes | draft |

## Fix Released

Released in `@windyroad/itil@0.57.2` (2026-07-06, PR #337). The work-problem / work-problems `/goal` external-evaluator loop-anchor (ADR-094 / RFC-047): a fresh per-turn evaluator — not the working agent — judges completion via the printed Step 2.4 Gate(0) re-scan evidence, breaking the same-actor "agent grades its own homework" conflation that let ALL_DONE fire early. One-directional (forces continuation, never authorises a stop). The arbitrary turn-bound was removed entirely (trust the goal) per the 2026-07-05 user direction. 3/3 promptfoo behavioural cases GREEN.

**Awaiting live verification**: a real AFK `/wr-itil:work-problems` run under the `/goal` anchor does not emit ALL_DONE while dispatchable Tier-2 backlog remains. ADR-094 / RFC-047 are born `human-oversight: unconfirmed` — ratification pending at `/wr-architect:review-decisions` + `/wr-itil:manage-rfc`.

## Dependencies

- **Blocks**: trustworthy AFK backlog drain (JTBD-006)
- **Blocked by**: (none)
- **Composes with**: P332 (run-retro skip rationalisation), P148 (Stage-1 ticketing skip), P175 (scope-pin loop-control inference), P341 (Step 2.4 pre-ALL_DONE gate sequence — this hardens its precondition)

## Related

- **P341** (`docs/problems/.../341-...`) — the Step 2.4 pre-ALL_DONE gate sequence; this ticket adds the objective-backlog-empty precondition to it.
- **P332 / P148 / P175** — sibling loop-control / skip-rationalisation class.
- User correction 2026-06-27 (work-problems session): "Really? Really all done? There's no other problems in the backlog that you can work?"

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-047 | proposed | AFK loop `/goal` anchor — external evaluator judges the stop |

## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-040 | STORY-040: AFK loop anchored with the native `/goal` external evaluator | draft |

