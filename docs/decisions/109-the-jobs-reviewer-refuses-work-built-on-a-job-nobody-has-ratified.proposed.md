---
status: proposed
date: 2026-08-09
decision-makers: Tom Howard
human-oversight: confirmed
oversight-date: 2026-08-09
oversight-note: "2026-08-09 — confirmed after a post-change brief that stated the guard in plain terms, disclosed that it had been running since 2026-05-27 inside a document ratified two days earlier, and put the one live judgement in front of the maintainer: whether to hold the guard until the unratified backlog was drained. The brief named the cost of the option taken (early fires will read as noise) and the signal that would mean it was wrong (people routing around the reviewer rather than draining the backlog). The substance had been agreed on 2026-05-27 via AskUserQuestion; what was never agreed was carrying it as an amendment to a ratified decision, which is what this document repairs."
consulted: [wr-jtbd:agent, wr-architect:agent]
informed: []
supersedes: [ADR-068 (in part — the 2026-05-27 build-upon guard only; the rest of ADR-068 stands)]
jtbd: [JTBD-002, JTBD-006]
persona: developer
secondary-persona: tech-lead
---

# ADR-109: The jobs reviewer refuses work built on a job nobody has ratified

## Context and Problem Statement

A job or a persona is a claim about who someone is and what they are trying to get done. Getting one wrong is expensive, because everything downstream inherits it — the tickets anchored to it, the stories written for it, the code shipped to serve it.

Two surfaces already protect that. A job or persona authored with a person present is recorded as ratified at the moment they confirm it. A separate pass lets someone work through the backlog of ones that were never confirmed. Between them they establish whether the substance was agreed, and they let the unagreed pile be drained.

Neither stops anyone building on the pile while it sits there. A change can cite a job by name, implement its flow, and land — with nobody having agreed that the job describes a real person wanting a real thing. By the time anyone drains the backlog, work has already been built on whatever was in it, and if the job turns out to be wrong the work goes with it.

The decisions side of this project already had the missing surface: its reviewer fails a change that builds on a decision nobody ratified. The jobs side did not, purely because it was written two days before that surface existed and so had nothing to copy.

A guard was added on 2026-05-27 to close it. It was recorded as an amendment inside a document that had been ratified two days earlier. The substance was agreed at the time — but under the rule this project now holds, a ratified decision does not get amended, so the guard has been running inside a document that never carried it.

## Decision Drivers

- Work built on an unratified job is work built on an assumption nobody checked. The cost lands later, when the assumption is corrected and everything resting on it moves.
- The two existing surfaces answer *was this agreed* and *let me agree the backlog*. Neither answers *stop, you are building on something unagreed* — which is the only one that acts before the cost is incurred.
- The reviewer already matches every change to a job in order to pass it. A guard that fires on that match would fire on everything and be switched off within a week.
- Ratification and lifecycle status are different axes. A job can be ratified and still a draft; building on it is fine.

## Considered Options

1. **Fail only on an explicit dependency.** The reviewer fails when a change cites a job or persona by name, implements its flow, or authors it — and that artefact is not ratified.
2. **Fail on any match.** Use the alignment the reviewer already computes. Rejected: it matches every change to some job, so the guard would fire on all of them and teach people to ignore it — the over-firing failure this project has hit before.
3. **Wait for the backlog to be drained first.** Hold the guard until the unratified set is empty, so its first fires aren't all against known-unratified jobs. Rejected below.
4. **Leave it to the drain pass.** No guard. Rejected: this is the state that let dependent work accumulate on unconfirmed substance in the first place.

## Decision Outcome

**Option 1.** The jobs reviewer fails a change that explicitly cites, implements, or serves a job or persona whose ratification is absent, and says which artefact to ratify.

The trigger is an explicit dependency — naming the job, referencing the persona, or authoring that artefact's own flow — and never the ambient match the reviewer computes for every change. That boundary is the whole difference between a guard people keep and one they disable.

It keys on ratification, never on lifecycle status. A ratified job that is still a draft can be built on freely; an unratified one cannot, whatever its status says.

**It does not wait for the backlog to be drained.** Option 3 is tempting because the first fires will nearly all be against jobs already known to be unratified, which reads like noise. But those are exactly the cases the guard exists for — a large unratified set is the reason to have it, not a reason to postpone it. The guard is the forcing function that makes the backlog get drained rather than tolerated.

## Consequences

### Good

- Work stops at the point where it would rest on an unagreed claim, rather than being unwound later.
- The jobs side and the decisions side now behave the same way, so there is one rule to learn.
- The unratified backlog acquires a cost, which is what gets it drained.

### Neutral

- The reviewer needs to distinguish an explicit citation from an ambient match. It already reads both, so this is a judgement it makes rather than new machinery.

### Bad

- Early on, most fires will be against jobs everyone already knows are unratified, and it will feel like an obstacle rather than a check. That is the intended pressure, but it is real, and if it turns into people routing around the reviewer rather than draining the backlog, that is the signal to revisit.

## Confirmation

- A change citing a job by name that has no ratification gets a failing verdict naming that job and how to ratify it.
- A change matched to a job only by topic — no citation, no implementation of its flow — passes.
- A change citing a job that is ratified but still a draft passes: status is not the test.
- A change citing a job that has been superseded does not fire.

## Related

- **ADR-068** — the decision this supersedes in part. Its own substance stands: the ratification marker on jobs and personas, the detector, the session-start nudge, the drain pass, and born-confirmed authoring. Only the 2026-05-27 build-upon guard moves here.
- **ADR-074** — the decisions-side equivalent this mirrors. The asymmetry existed only because ADR-068 was written before it.
- **P323** — the ticket that surfaced the missing surface.
- **P132** — over-firing when a guard is bound too loosely. The explicit-dependency boundary is the direct answer to it.
- **P483** — amendment sections are not a legitimate way to change a ratified decision. This is the second document of that sweep.

## Reassessment Criteria

Revisit if the guard starts firing on changes that merely share a topic with a job — that would mean the explicit-dependency boundary has slipped, and a guard that fires on everything is worse than none.
