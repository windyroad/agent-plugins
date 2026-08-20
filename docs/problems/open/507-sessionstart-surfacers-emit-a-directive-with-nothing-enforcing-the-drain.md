# Problem 507: SessionStart surfacers emit a directive with nothing enforcing the drain — surfacing is not draining

**Status**: Open
**Reported**: 2026-08-20
**Priority**: 15 (High) — Impact: 3 × Likelihood: 5 — derived at capture. Impact 3: the queue holds decision-ratifications, and while they sit there the governance artefacts they concern keep stating things that are no longer true — ADR-090's Decision Outcome has read "Any change … invalidates" since 2026-07-03 despite the shipped behaviour being substance-only. These artefacts are what agents route on, so the drift is runtime-active for every session in the repo. Likelihood 5: all three band triggers hold — known gap, no control in place, and observed twice on 2026-08-20 alone.
**Origin**: internal
**Effort**: M — derived at capture. The enforcement mechanism is a bounded choice among a few known shapes (a Stop-hook check, a first-turn gate, a re-fire on Nth turn), but it needs deciding rather than just writing, and it should be settled once for all three Class B surfacers rather than three times. Sized below P506's L because no ratified design premise is being reversed.
**JTBD**: JTBD-001
**Persona**: developer

## Description

The SessionStart pending-questions hook works. It fires, it reads `.afk-run-state/outstanding-questions.jsonl`, and it emits an explicit directive:

> Surface them via AskUserQuestion batched <=4 per call … on the user's first interactive turn.

Nothing makes that happen. The directive is prose injected once, at session start. It competes with every other SessionStart injection for attention, it decays with session context, and no gate, marker, Stop-hook, or later re-fire checks whether the drain occurred. When the agent doesn't act on it in the first turn or two, the queue silently persists to the next session, where the same thing happens again.

**Observed 2026-08-20, twice in one day.** In the evening session the hook surfaced one queued entry — P474, asking whether ADR-090's oversight-invalidation trigger stands as substance-only or reverts to the literal "any change" its Decision Outcome still states. The session then ran roughly ten user turns: a push, a stale-plugin diagnosis, a problem capture, a global plugin install, a story-map format question, and this retrospective. The entry was never surfaced. `.afk-run-state/outstanding-questions.jsonl` still held it, unchanged, at retro time. The morning session recorded a structurally identical defect in its own ask-hygiene trail: a genuine direction question put to the user in prose rather than through `AskUserQuestion`.

Both are the same failure in the same place — the ask surface, not the ask count. Neither scores as `lazy` in the ADR-044 taxonomy; they are its inverse.

## Symptoms

- `outstanding-questions.jsonl` entries persist across many sessions with no drain and no escalation. The P474 entry has been queued since 2026-07-29.
- The SessionStart output looks like the system is working — the queue is printed in a formatted table with a count — which makes the absence of a drain hard to notice.
- Governance artefacts named in queued entries stay in their contradictory state indefinitely.

## Workaround

Read the SessionStart output and act on it before anything else. That is precisely the "system holds the memory, not the user" failure recorded in `feedback_system_holds_the_memory_not_the_user` — a surfacer that needs a human to remember to act on it is a missing automation, not a working control.

## Impact Assessment

- **Who is affected**: the maintainer, every session. Adopters inherit the same shape once they accumulate queue entries.
- **Frequency**: every session that starts with a non-empty queue and does not happen to drain it. Two for two on 2026-08-20.
- **Severity**: silent governance drift. The decisions that most need human ratification are exactly the ones parked in this queue.
- **Analytics**: none. Nothing counts queue age, drain rate, or entries-surfaced-but-not-drained.

## Root Cause Analysis

A SessionStart hook can only inject text. It has no way to observe whether the agent acted on that text, and no later event re-checks. The three Class B surfacers all share this shape — they convert on-disk state into prose exactly once per session and then have no further leverage.

### The finding that generalises this beyond one queue

P375's 2026-06-23 self-firing-cadence audit classifies these three surfacers as **Class B — "THE FIX TEMPLATE THAT ALREADY WORKS"** (`docs/problems/known-error/375-…md` line 84), and builds its Option A rung on that premise. This ticket falsifies it. All three — `jtbd-oversight-nudge.sh`, `architect-oversight-nudge.sh`, `itil-pending-questions-surface.sh` — surface without draining. Corroborating evidence is already visible in this session's own SessionStart output: the jtbd nudge reported 2 unconfirmed jobs/personas, the architect nudge 1 unconfirmed decision, and the itil nudge 54 unratified RFCs. None drained. The jtbd nudge is cited inside P375 as "the model" for the pattern.

So the premise that Class B is the working template — and therefore the right target to convert Class C surfaces toward — needs re-examination before more surfaces are built to that template.

### Investigation Tasks

- [ ] Decide the enforcement shape, once, for all three Class B surfacers: a Stop-hook that refuses to end a session with an undrained queue, a PreToolUse gate on the first substantive tool call, a re-fire on turn N, or something else
- [ ] Settle what "drained" means and how it is observed — an entry removed from the queue file is checkable; an `AskUserQuestion` having been asked is not
- [ ] Decide the AFK behaviour: an unattended session cannot drain a direction question, so the enforcement must distinguish "cannot ask" from "did not ask"
- [ ] Amend P375's Class B claim at line 84 and re-check whether its Option A rung still stands on the corrected inventory
- [ ] Drain the P474 entry that prompted this capture
- [ ] Write a behavioural test that fails when a session ends with a non-empty queue and an available ask surface

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P375, P467

## Related

Captured via `/wr-itil:capture-problem`. Hang-off arbitration returned `PROCEED_NEW` over five candidates:

- **P375** (`docs/problems/known-error/375-…md`) — the structural sibling, and the ticket this one contradicts. P375's rot test is transitive reachability to a self-firing trigger; this capture **passes** that test and fails anyway, which is why it is not an extension of P375. Its Class B inventory claim at line 84 needs the amendment noted above. Cluster candidate with P467 under "surfacing is not draining" at the next `/wr-itil:review-problems` pass.
- **P157** (`docs/problems/closed/157-…md`) — built this hook; closed and verified 2026-07-25. Its scope was emitting the directive, which demonstrably works. Post-close discovery on a distinct fix locus; a closed ticket is not an absorb target.
- **P271** (`docs/problems/closed/271-…md`) — the inverse root cause: a skill with no automatic trigger, fixed by adding one. Here the trigger fires and the failure is downstream of it.
- **P467** (`docs/problems/open/467-…md`) — batching latency *inside* an AFK loop run. Its fix (mid-loop non-blocking emit) would not make this interactive-session drain happen.
- **P452** (`docs/problems/open/452-…md`) — shares only the queue file. Its concern is the content fidelity of a surfaced entry; this one's is that no entry gets surfaced at all.
- `feedback_system_holds_the_memory_not_the_user` and `feedback_automatic_cadence_or_it_doesnt_happen` — the two memories this defect instantiates.
