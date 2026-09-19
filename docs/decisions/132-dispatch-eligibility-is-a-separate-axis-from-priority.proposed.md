---
status: "proposed"
date: 2026-09-19
human-oversight: unconfirmed
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent, wr-risk-scorer:pipeline]
informed: []
reassessment-date: 2026-12-19
---

# Dispatch eligibility is a separate axis from priority

> Captured via /wr-architect:capture-adr (foreground-lightweight aside-invocation per ADR-032, derived-substance amendment 2026-07-06 / RFC-045). Section content was derived by the capturing agent from the in-session decision context; human-oversight: unconfirmed until ratified at the /wr-architect:review-decisions drain.

## Context and Problem Statement

The AFK orchestrator ranks the backlog by tier and WSJF and hands the top ticket
straight to dispatch. The only question it ever asks is *which ticket is most
valuable*. It never asks *can anything be done with this ticket right now*.

So a ticket that structurally cannot move — one held on a maintainer question,
one whose fix needs a skill only a present human can run, one blocked upstream,
one whose fix is committed but not yet pushed — still wins a dispatch slot, pays
a full iteration to be read and classified unworkable, and is selected again on
the next pass because the skip left no mark anything consults before dispatch.

Worse, the ranking rewards a ticket for being stuck. Transitioning a held ticket
to Known Error raises its score on the Known-Error status multiplier, so it
re-selects *higher* while still unable to progress. Two cases in one session:
one ticket was held on two maintainer questions queued two months earlier and
re-selected at the top of the queue every pass, able only to re-confirm the
block; another was investigated, transitioned to Known Error, and had its score
raised while held on a direction question. Downstream reporting measured 5 of 6
iterations classified upstream-blocked on read.

Two narrow gates already ask a version of the second question — a ratification
predicate and an already-shipped relevance gate — but each covers one cause, and
both sit after selection has already committed to the ticket.

## Decision Drivers

- A held ticket must stop consuming dispatch slots; the observed waste is most of
  the iterations at the frontier of the queue.
- A held ticket must not be hidden from the maintainer. It is not a low-value
  ticket — it is a ticket waiting on someone, and the maintainer needs to see
  that on return.
- A held ticket must not have its priority silently dropped. Demotion would
  corrupt what the ranking means and would bury a ticket whose hold clears
  mid-loop.
- Not every hold is owed by the maintainer. Putting an upstream wait or a pending
  push on the maintainer's return checklist asks them for something they cannot
  give.
- The maintainer reads the return surface on a phone, with no filesystem and no
  memory of the session. Whatever the loop reports has to be readable from its
  own bytes.
- The signals are already durable and already read elsewhere; inventing a new
  state to keep in sync would be its own drift surface.
- A hold kept only in agent memory cannot survive the pre-`ALL_DONE` backlog
  re-scan, which is explicitly marker-bound and forbids classification by
  recollection.

## Considered Options

1. **Separate dispatch eligibility from priority — filter dispatch, leave rank
   untouched (chosen)** — a read-only predicate answers "is this ticket held,
   and who owes the unhold" from existing signals; a pre-dispatch gate skips the
   ticket for dispatch only.
2. **Demote the held ticket's WSJF or apply a hold multiplier** — reuses the
   existing ranking machinery with no new concept, but conflates "waiting on a
   person" with "worth less", and a ticket whose hold clears mid-loop stays
   buried until something re-ranks it.
3. **Park held tickets automatically** — takes them out of the ranked set
   entirely, which does stop the dispatch waste, but drops them from the
   maintainer's WSJF view: the silent-priority-drop failure this decision exists
   to avoid. Parking stays a deliberate, reversible maintainer act.
4. **Keep extending the two existing narrow gates, one cause at a time** — the
   status quo. Each extension is cheap in isolation, but the causes keep
   arriving (four so far from three separate reports), each lands in a different
   gate with a different routing, and none of them shares a vocabulary for who
   owes the unhold.

## Decision Outcome

Chosen option: **"Separate dispatch eligibility from priority"**, because the
two questions are genuinely different and only one of them is about value.
Priority says how much a ticket is worth; eligibility says whether anything can
be done with it right now. Collapsing them is what lets the Known-Error
multiplier reward a stuck ticket. Separating them fixes the observed waste while
leaving the ranking's meaning intact, and it generalises over the four causes
already reported instead of absorbing each one into a different gate.

Both rejected mechanisms make the ranking the maintainer reads say something
untrue about value. Demotion says a ticket waiting on a person is worth less.
Auto-parking says it is not worth ranking at all. The maintainer means neither.
That is the decisive argument for filtering, and it is why the rank-invariance
below is the load-bearing clause rather than an implementation nicety.

The decision pins four things.

### (a) A hold filters dispatch only

The ticket's WSJF score, its Impact and Likelihood, its tier and its position in
the rankings are untouched. The observable property: **the held ticket still
appears at its own position in the rankings the maintainer reads, annotated as
held.** That is what separates this design from the parking option, and it is
what the maintainer actually cares about.

### (b) Four held classes, each with an owner and an unhold trigger

The owner is load-bearing: only two of the four are owed by the maintainer.

| Class | Signal | Hold owner | Unhold trigger |
|---|---|---|---|
| `unpushed-fix` | Known Error with an unpushed fix-shaped commit referencing it | loop | the commit reaches `origin` — in practice via the loop's own release-cadence drain, but any push clears it. Never the maintainer's return |
| `direction` | the ticket's `- **Blocked by**:` line names a person-gated hold | maintainer | the queued question is answered |
| `interactive-only` | the ticket's `## Fix Strategy` names an interaction-bound authoring skill | maintainer | that skill is run in an attended session |
| `upstream` | `## Reported Upstream` section, or the upstream-report-pending marker | upstream | the upstream fix lands |

**Two surfaces, two rules — they are not the same membership question.**

- *Summary membership is about what the maintainer can see.* **All four owners
  appear in the loop summary**, grouped by owner, each with its class, its
  evidence line and its unhold trigger.
- *Queue membership is about what the maintainer owes.* **Only maintainer-owed
  holds enter the shared outstanding-questions queue.** That queue is surfaced
  to the maintainer and truncated at loop end, and replayed at the next
  interactive session start; a pending push and an upstream wait are not
  judgment calls the maintainer can make, so putting them there is noise on the
  return checklist.

Conflating the two is what would make the queue rule read as suppression. A
loop-owned or upstream-owned hold leaves the queue but never leaves the summary.

### (c) A hold record is the last evaluation's result, not a session-long suppression

The record exists because the pre-`ALL_DONE` backlog-empty gate is marker-bound
and forbids classification by recollection — a hold kept only in memory would be
re-classified dispatchable, routed back to selection, and held again, which
trades a burned-iteration livelock for a non-terminating one.

But a record that outlives its own unhold trigger strands the ticket. A
`unpushed-fix` hold recorded on one pass must not survive the push two passes
later, or the loop takes a terminal stop while holding a ticket that became
workable — and that contradicts the whole reason rank is left untouched. **A
hold record is invalidated when its unhold trigger fires**; at minimum, any push
that carries the commit to `origin` clears every `unpushed-fix` record. The
trigger is stated against the signal, not against the release machinery, because
a project may ship by changesets, by a tag push, by a make target, or by nothing
at all — binding it to a release cadence would strand the hold forever in a repo
that has none. The predicate is read-only and cheap, so re-evaluating before the
terminal gate is the natural shape.

### (d) An all-held backlog is a distinct reported terminal state

A backlog where every remaining ticket is held is a legitimate stop — the gate
treats a valid hold record as a non-dispatchable condition alongside the ones it
already recognises.

It is **not** the same stop as an empty backlog, and it must not report as one.
"Nothing left" and "everything left is waiting on you, on upstream, or on a
push" are opposite states. The all-held stop emits the by-owner grouping inline,
naming each held ticket, its class and what would unstick it, in prose readable
from its own bytes — not a pointer to a file the maintainer cannot open from a
phone, and not a bare class token standing in for the explanation.

### Relationship to existing decisions

This **composes with** ADR-076 rather than amending it: the tier partition, the
WSJF ladder and the effort divisor are untouched, which is exactly what the
rank-invariance in (a) guarantees.

A *held* ticket is distinct from ADR-022's *verifying* and *parked* states. Held
means in the ranked set and visible there, but not dispatchable this pass.
Verifying and parked mean out of the ranked set entirely. The two mechanisms do
not overlap and neither substitutes for the other.

Also relates to: ADR-094 and ADR-128 (the loop's completion anchoring, which
gate (d) extends), ADR-079 (the sibling relevance evaluator whose
line-anchoring lesson the matching discipline inherits; ADR-129 is adjacent
rather than a source — holding a ticket is explicitly not closing it, so the
`unpushed-fix` class is consistent with it and takes nothing from it), ADR-049 (the predicate
resolves via a PATH shim), ADR-052 (behavioural tests), ADR-044 (the routing is
a mechanical framework-resolved stage, so no question fires at the gate), and
ADR-013 Rule 6 (the AFK fail-safe the silent-pass paths follow).

The predicate reads only what is already durable on the ticket or in git. No new
state is introduced.

## Consequences

### Good

- The wasted dispatch disappears at the frontier of the queue, which is where it
  concentrates.
- The ranking keeps meaning what it says. A held ticket at the top of the queue
  is still visibly the most valuable thing waiting — which is precisely what the
  two rejected options give up.
- The maintainer's return checklist carries only what the maintainer owes, while
  the summary still shows every hold, because the owner dimension separates the
  two surfaces.
- New hold causes extend one vocabulary rather than accreting into whichever
  gate is nearest.
- A hold that clears — most often a pending push — clears on its own within the
  same loop, without anything needing to re-rank or un-park the ticket.
- The loop can end honestly on an all-held backlog instead of cycling, and the
  ending says what it is waiting on and who owes it.

### Neutral

- A held ticket is still selected before it is filtered, so the loop pays one
  short-lived shell call per pass rather than nothing — order of tens of
  milliseconds, since it shells out to git, against a dispatch it avoids that
  costs minutes. The margin is wide enough that the placement choice does not
  turn on the exact figure. Filtering at selection
  instead would save that, at the cost of running the predicate over the whole
  backlog every pass; the per-selection shape also matches the two sibling gates
  exactly.
- The iteration-level skip stays in place unchanged. The two surfaces are not
  redundant: the iteration layer is the authoritative second source, the
  pre-dispatch gate is the shift-left cost optimisation.

### Bad

- A predicate that over-fires holds a ticket that could have been worked, which
  is the inverse of the harm this exists to prevent. Three of the four classes
  read prose, and the corpus already contains shapes that defeat a naive match —
  `(none — …)` values whose prose carries hold keywords, strikethrough-resolved
  holds, commits that merely mention a ticket, and a false-positive upstream
  marker that shares its prefix with the real one because the detection reuses
  that prefix as its already-noted substrate. The matching discipline is where
  the risk lives, and it needs corpus-derived fixtures rather than assumed
  shapes.
- One more concept sits between ranking and dispatch. A reader now has to know
  that the top of the rankings is not necessarily what the loop works next.
- The `interactive-only` class can hold a large and growing set of tickets,
  since "needs a new ratified decision" is a common state. It is given a queued
  question so it surfaces at the loop-end gate rather than only in a per-session
  record the maintainer may never read.
- Adopting (d) sharpens the "clear summary" outcome of the AFK-backlog job: an
  all-held stop arguably already satisfies it, but the distinct-terminal-state
  obligation is stronger than the job's current wording. It requires a
  re-ratification of that job at the next `/wr-jtbd:confirm-jobs-and-personas`
  drain rather than a separate amendment of its own.

## Confirmation

Mechanism checks:

- The predicate exits 0 with the right class and owner for a fixture ticket in
  each of the four held classes, and exits 1 for each corpus-derived
  false-positive shape: a `(none — …)` value carrying a hold keyword, a
  strikethrough-resolved hold, a mention-only unpushed commit, and the
  misfire-marked upstream recovery line. Behavioural tests, proven red before
  green.
- A ticket carrying two `- **Blocked by**:` lines — one `(none — …)`, one a real
  hold — reads held in either order.
- The predicate and the backlog-empty gate agree on every ticket. In particular
  a ticket whose external-root-cause detection misfired — recorded via the
  documented recovery path, which reuses the upstream marker's own prefix —
  reads not-held at the predicate AND dispatchable at the gate. Two surfaces
  disagreeing is the divergence this decision exists to remove, so agreement is
  asserted rather than assumed.

Outcomes the maintainer can observe on return:

- The held ticket still appears at its own position in the rankings, annotated
  as held. Its score, tier and rankings row are byte-identical before and after
  a loop that filtered it.
- After a loop in which all four classes fired, the outstanding-questions queue
  contains the `direction` and `interactive-only` entries and **zero**
  `unpushed-fix` or `upstream` entries — while all four still appear in the loop
  summary, grouped by owner.
- Every surfaced hold names what would unstick it, in the text the maintainer
  reads, without needing to open the repository.
- The all-held stop is textually distinguishable from an empty-backlog stop, and
  names each held ticket with its class and unhold trigger inline.
- A ticket whose only hold was a pending push becomes dispatchable again once
  the commit reaches `origin`, within the same loop and with no maintainer
  action — in a repo with no release cadence at all as well as one with.

## Pros and Cons of the Options

### Separate dispatch eligibility from priority

- Good, because it answers the two questions separately instead of letting one
  stand in for the other.
- Good, because it preserves both halves of the constraint — the ticket stays
  visible and keeps its priority, and it stops consuming dispatch slots.
- Good, because the signals already exist, so there is nothing new to keep in
  sync and no migration.
- Bad, because the prose-reading classes carry real false-positive risk.
- Bad, because it adds a concept between ranking and dispatch that a reader has
  to know about.

### Demote WSJF or apply a hold multiplier

- Good, because it reuses the ranking machinery with no new concept.
- Bad, because it says a ticket waiting on a person is worth less, which is not
  what the maintainer means.
- Bad, because a hold that clears mid-loop leaves the ticket buried until
  something re-ranks it.

### Park held tickets automatically

- Good, because it removes them from the ranked set completely, with no
  per-selection cost.
- Bad, because it drops them from the maintainer's WSJF view — the exact
  silent-priority-drop this decision rejects.
- Bad, because it makes a reversible maintainer judgement into an automatic act.

### Keep extending the existing narrow gates

- Good, because each extension is small and lands in machinery that already
  works.
- Bad, because the causes keep arriving and each lands in a different gate with
  different routing.
- Bad, because there is no shared vocabulary for who owes the unhold, so the
  maintainer's return surface cannot be grouped by owner.

## Reassessment Criteria

- A held ticket is observed being filtered when it was in fact workable. One
  confirmed false positive should reopen the matching discipline; a second
  should reopen whether prose is a sound substrate at all, versus requiring an
  explicit machine-written hold field.
- A fifth held class arrives that does not fit the class-plus-owner-plus-trigger
  shape — evidence the model is too narrow.
- The per-selection filter shows measurable cost on a large backlog, favouring a
  move to filtering at selection instead.
- The `interactive-only` class grows to hold a large fraction of the backlog,
  which would make the real problem the size of the ratification queue rather
  than the dispatch filter.
- All-held stops become the common loop ending rather than the rare one, which
  would mean the backlog is gated on people far more than on work and the
  bottleneck is elsewhere.
