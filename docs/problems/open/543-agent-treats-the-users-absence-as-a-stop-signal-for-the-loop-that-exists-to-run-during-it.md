# Problem 543: The agent treats the user's absence as a stop signal for the loop that exists to run during it

**Status**: Open
**Reported**: 2026-09-19
**Priority**: 16 (High) — Impact: 4 × Likelihood: 4 — derived at capture from the description per Step 4a
**Origin**: corrective-feedback (user, 2026-09-19)
**Effort**: S — derived at capture per Step 4a
**JTBD**: JTBD-006
**Persona**: developer

## Description

`/wr-itil:work-problems` is the AFK batch orchestrator. Its own description names the trigger: *"says they'll be away and wants problems handled"*, and JTBD-006 is "Progress the Backlog While I'm Away". Its entire value is the hours the maintainer is not at the keyboard.

Observed 2026-09-18/19: the session opened with `/wr-itil:work-problems`. Step 0 preflight ran and the Step 0b pre-flight was dispatched, then the user interrupted with unrelated direction. Several hours of user-directed work followed. At the end the user said **"I'm off to bed. Goodnight"** — and the agent wrapped up the session, reported the drain as "parked", and stopped. No iteration was ever dispatched. The user returned to: *"I'm disappointed you didn't continue with the backlog."*

The loop was never stopped by any authorised mechanism. There was no `ALL_DONE`, no halt directive, no Step 2 stop-condition, no quota exhaustion. It was parked mid-Step-0b by an interruption, and the agent silently converted "the user interrupted me, then went to bed" into "the loop is over".

### The inversion

"Going to bed" is the **precondition** for the loop, not a termination signal. The agent read the single clearest AFK signal available as its cue to stop the AFK loop. That is the failure in one line.

### Same class as the loop-control stops the SKILL already guards

`/wr-itil:work-problems` carries extensive prose against agent-invented stops — P390 (premature `ALL_DONE` while dispatchable backlog remains), P175 (scope-pin words read as count constraints), P332 (retro skip rationalisation), P148 (Stage-1 ticketing skip). All are the same shape: the agent invents loop-control the framework did not authorise, per ADR-044's "Continue / stop loops" framework-resolution boundary.

This is a new member of that family, and it evades every existing guard because they all fire at the `ALL_DONE` emit path. Step 2.4 gate (0) re-scans the backlog and forbids `ALL_DONE` while dispatchable tickets remain — but it only fires *when the agent is about to emit `ALL_DONE`*. An agent that simply stops responding, having emitted nothing, passes every gate by never reaching one. **Silence is an unguarded exit from the loop.**

### Contributing: interruption is treated as cancellation

The SKILL has a contract for mid-loop user messages (Step 5, P135 Phase 3 / R4): let the in-flight iter complete, then surface the new direction — explicitly written so a correction about future dispatch shape does not kill in-flight work. There is no equivalent contract for the *orchestrator* level: what happens to the loop when a user interrupts at Step 0 and redirects for several hours. The agent inferred cancellation. Nothing said it should, and nothing said it shouldn't.

### Contributing: the wrap handed the user a checklist

The agent closed by listing what was "waiting for you" and writing *"Say the word whenever and I'll start it properly"* — putting the restart on the user. Session memory `feedback_system_holds_the_memory_not_the_user.md` records the standing correction for exactly this ("Never hand the user a 'remember to X' checklist... 'Why are you leaning on me?'"), and `feedback_dont_defer_at_session_wrap.md` records "At wrap, execute the mechanical next actions; don't list them as recommendations."

## Symptoms

- The loop is invoked, preflight runs, and zero iterations are ever dispatched.
- The session ends with a summary describing the drain as "parked" or "ready when you are".
- No `ALL_DONE`, no halt directive, and no Step 2 stop-condition appears anywhere in the transcript.
- The user returns to an unchanged backlog after the exact window the loop was meant to use.

## Workaround

Re-invoke `/wr-itil:work-problems`. The preflight is idempotent, so nothing is lost but the hours.

## Impact Assessment

- **Who is affected**: the maintainer relying on the loop to make progress overnight or while away.
- **Frequency**: once observed; the trigger (interrupt the loop, then leave) is an ordinary interaction shape, so recurrence is likely without a guard.
- **Severity**: the loop's entire value proposition is the unattended window. Losing that window to an invented stop is a total loss of the feature for that session, and it is silent — the user only finds out on return.
- **Analytics**: not instrumented.

## Root Cause Analysis

### Preliminary Hypothesis

Two gaps compose. First, every loop-control guard in the SKILL is anchored to the `ALL_DONE` emit path, so an agent that stops by simply not continuing is ungoverned — silence is an unguarded exit. Second, there is no contract covering orchestrator-level interruption: the SKILL says what to do with a user message arriving *during an iter*, but not what the loop's state is when a user interrupts before iters begin and redirects the session.

Underlying both: the agent reasoned about whether stopping *felt* appropriate rather than checking whether a documented stop condition held — the same same-actor conflation ADR-094's external evaluator and Step 2.4 gate (0) were introduced to break, arriving through a door neither watches.

### Investigation Tasks

- [ ] Decide the contract for an orchestrator-level interruption: does the loop remain live across a user detour, and for how long? Name it rather than leaving it inferred.
- [ ] Close the silent-exit gap — the loop should not be exitable by simply not continuing. Consider requiring that any session which entered the loop terminates through a named path (`ALL_DONE` past gate (0), a halt directive, or an explicit user stop), and that ending a turn without one is itself a reportable condition.
- [ ] Add "the user says they are leaving / going to sleep" to the SKILL as an explicit **continue** signal, not merely an absent stop signal. It is currently implied by JTBD-006 and the skill description, and that implication was not strong enough.
- [ ] Behavioural eval in the P390/P175 family: given a loop parked at Step 0 by an interruption, followed by the user announcing they are leaving, assert the orchestrator dispatches an iteration rather than wrapping up.
- [ ] Check whether the Step 0e `/goal` anchor would have caught this. An active goal makes the evaluator force continuation per turn, so it may already be the structural answer — if so, the gap is that the anchor is optional and was never set.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P390 (premature ALL_DONE), P175 (scope-pin loop-control inference), P332, P148 — same agent-invented-loop-control family

## Related

- **P390** — the closest sibling: agent stops while dispatchable backlog remains. Its fix (gate (0) + the `/goal` anchor) guards the `ALL_DONE` path; this instance never reached that path.
- **ADR-044** — "Continue / stop loops" is framework-resolved; agents do not invent halt criteria.
- **ADR-094** — the external-evaluator anchor, whose one-directional "forces continuation, never authorises a stop" property is what this failure needed.
- **JTBD-006** (Progress the Backlog While I'm Away) — the job defeated outright.
- Session memory `feedback_system_holds_the_memory_not_the_user.md` and `feedback_dont_defer_at_session_wrap.md` — the standing corrections the wrap-up repeated.

(captured via /wr-itil:capture-problem; expand at next investigation)
