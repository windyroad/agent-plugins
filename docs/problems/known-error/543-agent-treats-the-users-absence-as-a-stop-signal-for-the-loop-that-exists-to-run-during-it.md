# Problem 543: The agent treats the user's absence as a stop signal for the loop that exists to run during it

**Status**: Known Error
**Reported**: 2026-09-19
**Priority**: 16 (High) — Impact: 4 × Likelihood: 4 — derived at capture from the description per Step 4a
**Origin**: corrective-feedback (user, 2026-09-19)
**Effort**: S — derived at capture per Step 4a
**WSJF**: 16 — (16 × 1.0) / 1 (added 2026-09-18 review — capture wrote no WSJF line)
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

Before starting the loop, set the `/goal` anchor from Step 0e. An anchored run cannot take this exit: the external evaluator judges the printed transcript each turn and forces continuation regardless of whether the agent feels finished.

## Impact Assessment

- **Who is affected**: the maintainer relying on the loop to make progress overnight or while away.
- **Frequency**: once observed; the trigger (interrupt the loop, then leave) is an ordinary interaction shape, so recurrence is likely without a guard.
- **Severity**: the loop's entire value proposition is the unattended window. Losing that window to an invented stop is a total loss of the feature for that session, and it is silent — the user only finds out on return.
- **Analytics**: not instrumented.

## Root Cause Analysis

### Confirmed Root Cause

Two gaps compose. First, every loop-control guard in the SKILL is anchored to the `ALL_DONE` emit path, so an agent that stops by simply not continuing is ungoverned — silence is an unguarded exit. Second, there is no contract covering orchestrator-level interruption: the SKILL says what to do with a user message arriving *during an iter*, but not what the loop's state is when a user interrupts before iters begin and redirects the session.

Underlying both: the agent reasoned about whether stopping *felt* appropriate rather than checking whether a documented stop condition held — the same same-actor conflation ADR-094's external evaluator and Step 2.4 gate (0) were introduced to break, arriving through a door neither watches.

Confirmed 2026-09-19 by reading the surface. Every loop-control guard in `packages/itil/skills/work-problems/SKILL.md` is positionally anchored to the `ALL_DONE` emit path — Step 2.4 gate (0) re-scans "before the orchestrator emits the final `ALL_DONE` sentinel"; the P175 scope-pin clause forbids emitting *from a modifier*; Step 2 enumerates the conditions that *permit* an emit; Step 2.5/2.5b fire at loop end. Not one of them has a trigger that an orchestrator printing nothing would reach. The absence half is confirmed the same way: before this fix the string "going to bed", "goodnight" or any equivalent appeared nowhere in the SKILL, and the only presence-related prose was the Mid-loop ask discipline clause, which is scoped to *ask* discipline ("presence-detection is unreliable ... Treat the user as transient") and says nothing about loop control. The job and the skill description carried the whole implication, and an implication is not a contract.

### What the `/goal` anchor would have done (investigation task 5, answered)

It would have caught it. The failing run was **unanchored** — no goal was set at invocation. An external goal anchor set later in the same session did hold the loop open afterwards, which is direct evidence that the ADR-094 evaluator forces continuation through exactly this door: it judges the printed transcript per turn and does not care whether the agent felt finished. So the anchor is a structural answer, and the gap is that it is optional (Step 0e: "defense-in-depth, never a precondition").

That does not make the anchor the whole fix, for two reasons. An unanchored run must still be governed, since halting the loop for a missing anchor would itself defeat JTBD-006 and Step 0e deliberately refuses to. And whether the anchor should stop being optional is its own ≥2-option decision, not something to settle inside a defect fix. The contract landed here binds anchored and unanchored runs identically; making the anchor mandatory remains open.

### Open: how long does liveness survive a detour? (investigation task 1)

Not answered, deliberately, and the landed prose says so rather than letting a reader infer it from silence. The options:

- **A — unbounded liveness.** The loop stays live across a detour of any length and resumes at the parked step; only a named ending ends it.
- **B — bounded liveness with re-anchor.** The loop stays live, but past a stated boundary (session end, context compaction, or a wall-clock bound) the orchestrator must re-announce and re-anchor rather than resume silently.
- **C — interruption ends the loop.** Re-entry is explicit re-invocation. This is the status quo behaviour that produced P543; worth naming so its rejection is on the record rather than implied.

Architect advisory leans A: B re-introduces a time-based stop, and ADR-094 already rejected that reasoning for turn caps (P422); C is the defect. The choice is the maintainer's. Queued to `outstanding_questions` for the next interactive drain.

### Investigation Tasks

- [ ] Decide the contract for an orchestrator-level interruption: does the loop remain live across a user detour, and for how long? Name it rather than leaving it inferred.
- [x] Close the silent-exit gap — the loop should not be exitable by simply not continuing. Consider requiring that any session which entered the loop terminates through a named path (`ALL_DONE` past gate (0), a halt directive, or an explicit user stop), and that ending a turn without one is itself a reportable condition.
- [x] Add "the user says they are leaving / going to sleep" to the SKILL as an explicit **continue** signal, not merely an absent stop signal. It is currently implied by JTBD-006 and the skill description, and that implication was not strong enough.
- [x] Behavioural eval in the P390/P175 family: given a loop parked at Step 0 by an interruption, followed by the user announcing they are leaving, assert the orchestrator dispatches an iteration rather than wrapping up.
- [x] Check whether the Step 0e `/goal` anchor would have caught this. An active goal makes the evaluator force continuation per turn, so it may already be the structural answer — if so, the gap is that the anchor is optional and was never set.

## Fix Strategy

**RFC-099** — the release row "The loop leaves only through a door it names" on `docs/story-maps/draft/STORY-MAP-011-trust-the-afk-loops-autonomous-conduct.html`, carrying **STORY-098** (accepted).

Landed 2026-09-19 in `packages/itil/skills/work-problems/SKILL.md`:

- **Named-exit discipline** (in `Mid-loop ask discipline`, the section that already hosts the sibling P130 and P175 loop-control clauses). The orchestrator session leaves the loop only through an ending it names in the transcript, and the ending set is read from Step 0e's canonical goal condition rather than restated — only that block is drift-checked. One delta is added: an explicit user stop directive about the loop, which also requires the goal to be cleared or the one-directional anchor keeps firing continuation turns. A turn executing the loop ends having printed an ending or dispatched the next iteration; a "parked" / "ready when you are" / restart-instruction summary is named as the defect, not an ending. Scoped to the orchestrator session — an iteration keeps ADR-128's three printed end states.
- **Absence is a CONTINUE signal, never a stop.** The announcements are enumerated and the inversion stated. Extends the existing presence clause from ask-discipline to loop-control.
- **Loop entry** declared at Step 0e, so the rule covers an orchestrator that never reaches the ending gate — which is what happened here (the interruption landed at Step 0b).
- Back-references at Step 2 and at Step 2.4's gate-(0) rationale, each naming what that guard does not cover.
- Behavioural eval case in the P390/P175 family in `packages/itil/skills/work-problems/eval/promptfooconfig.yaml`: loop parked at Step 0 by an interruption, user says goodnight, assert the orchestrator dispatches rather than wrapping up.

Out of scope and still open: the orchestrator-level interruption liveness contract (task 1 above), which needs its own ratified decision before any prose lands on it.

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


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-098 | STORY-098: The loop I left running is still running when I get back | accepted |
