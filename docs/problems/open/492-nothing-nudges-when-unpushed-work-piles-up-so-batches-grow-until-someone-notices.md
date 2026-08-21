# Problem 492: Nothing nudges when unpushed work piles up, so batches grow until someone notices

**Status**: Open
**Reported**: 2026-08-09
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4. Impact 3: the work is not lost, but it goes unverified and lands as one large batch whose failures are expensive to attribute. Likelihood 4: it recurs whenever a session runs long without a release to trigger a push, which is most sessions doing governance work.
**Origin**: corrective-feedback (user, 2026-08-09)
**Effort**: M — the signal is cheap to compute; where it fires and at what threshold is the open part.
**WSJF**: 6 — (12 × 1.0) / 2 (added 2026-08-21 review)
**JTBD**: JTBD-002
**Persona**: developer

## Description

Work is pushed when there is something to release. At the keyboard that is the ratified trigger and it stays — ADR-020 fires the drain when residual risk is within appetite and a changeset exists, and does not fire on unpushed commits alone.

What is missing is the counterweight. **There is supposed to be a nudge that limits work-in-progress and keeps releases small**, and nothing fires it. A session doing governance work produces commit after commit with no changeset among them, so the release trigger never fires and nothing else says a word.

### It has already been an incident, and it has recurred

I002 (2026-05-10) was declared on exactly this: *"something is broken with the pressure to release and limit WIP. There are 32 unpushed commits."* The held cluster had grown from three entries to thirteen, and there had been no push in four days. Its ranked-3 finding names the gap directly — **no quantitative WIP-size guard fires when the batch grows past N entries**, and it records that the same gap was already the ranked-1 hypothesis of I001 and was still uncodified.

On 2026-08-09 a session accumulated **nine unpushed commits** across a renderer change, a story-map corpus regeneration and five decision documents. Nothing nudged. The push happened because the maintainer was asked whether to push, not because anything noticed. The first CI run on those nine commits found a real defect — a generated agent left out of sync with its source — which had been sitting undetected across several of them.

So the incident's finding is not merely unfixed. It is producing the same outcome three months later, and the detection it was meant to provide is being done by a human asking a question.

### Why the release trigger cannot cover it

The two are different signals and only one exists. The release trigger asks *is there something worth shipping*. The WIP nudge asks *has the amount of unverified work got large enough to be a problem in itself*. A batch of governance commits answers no to the first and yes to the second, which is exactly the state that produced both I002 and today's recurrence.

Keeping releases small is the stated goal on the maintainer's side: smaller releases carry less risk, and a large batch is harder to attribute a failure to. That argument is about batch size, not about shippability.

## Symptoms

- A long session ending with many unpushed commits and no signal that anything was unusual.
- CI seeing a branch for the first time after a large amount of work has accumulated.
- A defect that could only be found by CI sitting undetected across several commits.
- Being asked whether to push, rather than being told the batch is large.

## Workaround

Notice, and push. That is what happened today and it is the same workaround I002 recorded.

## Impact Assessment

- **Who is affected**: whoever is working, and whoever later has to attribute a CI failure across a large batch.
- **Frequency**: any session long enough to accumulate commits without a changeset — routine for governance work.
- **Severity**: unverified work accumulates and batches grow. Nothing is corrupted; the cost is late detection and expensive attribution.
- **Analytics**: none.

## Root Cause Analysis

Suspected: the pressure to release was implemented as one trigger keyed on releasable material, and the WIP-limit half was never given a firing condition of its own. Both incidents recorded it as missing; neither produced a mechanism, so the gap has outlived two declarations. This is the "no automatic cadence, so it does not happen" pattern the maintainer has named repeatedly, applied to a control that was supposed to be the cadence.

### Investigation Tasks

- [ ] Decide what the nudge counts. Unpushed commits is the obvious candidate and matches both incidents' framing, but changed-file count or elapsed time since the last push may correlate better with the risk actually being carried.
- [ ] Decide the threshold, and record it as chosen rather than derived — there is no data. Both incidents cite double-digit accumulations; today's recurrence was nine.
- [ ] Decide where it fires. A session-start nudge is the established shape in this repository and is cheap; a post-commit nudge is timelier but noisier. It must not block.
- [ ] Check it does not duplicate the risk scorer's existing WIP assessment, which scores the *content* of uncommitted work rather than the *size* of the unpushed batch. Those are different questions and the answer may be to extend it rather than add a surface.
- [ ] Close I002's ranked-3 finding when this lands, or record why it stays open.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- **I002** — the incident that named this gap on 2026-05-10 and left it uncodified. Its ranked-3 finding is this ticket's subject, and I001 had already raised it before that.
- **ADR-020** — the interactive release trigger, confirmed 2026-08-09 as changeset-only. This ticket is its counterweight, not a change to it.
- **ADR-018** — the unattended trigger, which does fire on unpushed commits. The asymmetry between the two is deliberate and recorded in ADR-020.
- **P493** — a docs-only change should be able to reach GitHub without running a full build. Same session, adjacent concern: if pushing becomes more frequent, what a push costs matters more.

(captured at the maintainer's direction while settling ADR-020's trigger: *"there is supposed to be a nudge to limit WIP and keep the releases smaller and less riskier."*)
