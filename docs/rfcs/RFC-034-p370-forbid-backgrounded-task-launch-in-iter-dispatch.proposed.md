---
status: proposed
rfc-id: p370-forbid-backgrounded-task-launch-in-iter-dispatch
reported: 2026-06-28
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P370]
adrs: []
jtbd: []
stories: []
---

# RFC-034: Forbid backgrounded-task launches inside `claude -p` AFK iter dispatch contexts

**Status**: proposed
**Reported**: 2026-06-28
**Problems**: P370
**ADRs**: (none)
**JTBD**: (none)

## Summary

An AFK `/wr-itil:work-problems` iter is dispatched via `claude -p` — a single-shot
CLI invocation with no auto-resume affordance. The iter's turn boundary IS its
process boundary: any backgrounded task (`run_in_background: true` on an Agent/Bash
tool call, or a `&`-detached shell job) whose completion is deferred to a *later*
turn never resumes, and the iter exits at turn-end with its work staged but
uncommitted. Witnessed: iter 11 of a prior loop — $8.02 / 17 min / 8 staged files /
11 GREEN bats / ZERO commits; recovery required orchestrator main-turn salvage.

Fix shape: a SKILL.md iter-prompt-body prohibition clause in
`packages/itil/skills/work-problems/SKILL.md` Step 5 Constraints list, scoped to
the cross-turn / turn-end-survivor shape (it explicitly carves out the
P146/P232-sanctioned *intra-turn* `run_in_background=true` + `BashOutput`-poll-
then-`wait $bg_pid` idiom), naming foreground-synchronous Agent/Bash (`wait $bg_pid`)
as the safe substitute and cross-referencing the sibling-class clauses (P083
ScheduleWakeup ban, P146 bats-regex-poll, P232 pgrep-poll) — same
"must-not-leak-into-turn-end" root class. Behavioural coverage is a promptfoo eval
case (not a structural bats fixture) that exercises an iter-shape and asserts the
response proposes no turn-end-survivor background-fan-out tool-call (ADR-052
behavioural-only; ADR-075 promptfoo harness), which also discharges the R009
in-source floor for the prose change.

## Driving problem trace

- **P370** — Iter subprocess ends its turn waiting on a backgrounded task and
  never resumes; `claude -p` has no auto-resume, so commit-bearing staged work
  is lost at turn-end. This RFC's prohibition clause is the prevention half of
  P370's Fix Strategy Option 3.

## Scope

(deferred — populate at /wr-itil:manage-rfc accepted transition)

Initial scoping note carried from the implementing iter (architect-flagged, P371
existing-vehicle check, ADR-073 auto-create):

- **Singular `work-problem/SKILL.md` is OUT of scope.** P370's Fix Strategy names
  `packages/itil/skills/work-problem/SKILL.md` as a sibling amendment locus, but
  the singular skill has NO iter-prompt-body — it is the per-iteration *execution
  unit* the orchestrator runs (a selection-and-delegate skill: WSJF pick then
  delegate to `/wr-itil:manage-problem`), not the `claude -p` prompt builder. The
  turn-end-mid-background hazard exists ONLY on the AFK `claude -p` dispatch path,
  which the plural orchestrator (`work-problems`) owns at Step 5. A direct
  interactive `/wr-itil:work-problem` invocation runs in a session WITH
  notification re-entry, so the hazard does not apply. **This RFC supersedes the
  P370 ticket body's over-broad locus list** (the ticket lines that name the
  singular sibling as "same amendment") — the singular is excluded on the
  no-iter-prompt-body basis per architect review. A future reader should treat
  this scoping decision, not the ticket's locus list, as the spec.
- **RFC-033 (per-iter git worktree isolation) is NOT this RFC's vehicle.** P370's
  ticket states the worktree mechanism does not close the turn-end-leak class —
  the leak is independent of working-tree isolation.

## Tasks

- [ ] Prohibition prose clause in `work-problems/SKILL.md` Step 5 iter-prompt-body
      (shipped in the P370 implementing iter — this RFC traces the work).
- [ ] Behavioural promptfoo eval case asserting an iter-shape proposes no
      turn-end-survivor background-fan-out tool-call (shipped in the same iter;
      also discharges R009 for the prose change).
- [ ] **Deferred follow-on** — codify the orchestrator main-turn salvage/recovery
      protocol (P261-style carve-out parametrised for the turn-end-mid-background
      shape, not just stream-timeout) into a `work-problems` SKILL.md sub-step so
      the salvage is mechanical rather than ad-hoc. Heavier, separable concern;
      out of scope for the prohibition slice.

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook per ADR-060 Phase 1 item 12)

## Related

(captured via /wr-itil:capture-rfc; expand at next /wr-itil:manage-rfc invocation)

- **P083** (closed) — ScheduleWakeup ban; sibling-class precedent (turn-end leak).
- **P146** (verifying) — bats-console-regex poll antipattern; sibling-class.
- **P232** (verifying) — pgrep self-referential poll deadlock; sibling-class.
- **P261** — orchestrator main-turn salvage carve-out; the recovery-protocol
  follow-on inherits this precedent.
- **P305** (Known Error) — parallel iter dispatch race; RFC-033's worktree fix
  does NOT close P370.
