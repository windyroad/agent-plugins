# Problem 488: The agent batches artefacts it was told to produce one at a time, then asks permission for the batch

**Status**: Open
**Reported**: 2026-08-09
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4 — derived at capture per Step 4a. Impact 3: no artefact is corrupted, but the maintainer's review cadence is destroyed — a batch of 22 cannot be reviewed in the window they actually read in, and any batch built on a still-moving format is wholesale rework. Impact stops short of 4 because the work is recoverable by re-doing it one at a time. Likelihood 4: it recurred twice inside a single session after explicit correction, and nothing checks for it — cf. P085, whose ask-half needed a hook before it stopped.
**Origin**: corrective-feedback (user, 2026-08-09)
**Effort**: M — a contract in two capture SKILLs plus a counted signal in the existing ask-hygiene pass; no new machinery.
**WSJF**: 6 — (12 × 1.0) / 2 (added 2026-08-21 review)
**JTBD**: JTBD-002
**Persona**: developer

## Description

The agent bundles work the maintainer has explicitly told it to do one item at a time, and then puts a consent gate on top of the bundle.

Told twice inside one interactive session — *"no, go back and update the process so 002 is generated right, then ask me to ratify. We work incrementally not in batches"*, and later *"How many times do I need to tell you one map at a time and if we need to go through the stories then we do the stories one at a time"* — the agent still proposed *"I can commit this and start capturing the 22 stories for map 012. Want me to?"* as a single unit of work.

### Two defects, and they compound

**The batch.** Bundling N artefacts defers every ratification to the end, so nothing is reviewable until everything is done. If the format producing them is still moving — and on this work it was, three separate times — the whole batch is rework rather than one artefact's worth.

**The ask on top.** Proposing the bundle as a question re-opens a decision the maintainer had already made. Under AFK it is worse than redundant: it is unanswerable, so the loop stalls on a consent gate for work that was already authorised.

They compound because the batch is what creates something big enough to feel like it needs permission. A single story would simply have been written and shown.

### Why it keeps coming back

Nothing holds the instruction. It lives in a session memory (`feedback_work_incrementally_not_in_batches`) and in CLAUDE.md prose, and neither is checked against behaviour — so it decays with session context and has to be re-issued. The fact that the same correction was already recorded in memory *before* this session, and still did not survive it, is the evidence that a written reminder is not the mechanism.

### The reading context is load-bearing

The maintainer reads on a phone, with no repository access and no way to open a path. One artefact per message is reviewable in that window. Twenty-two is not reviewable in it at all — not slowly, not at all. This is the same constraint P484 records as missing from the persona file, and it is why the one-at-a-time rule is a correctness property of the review process rather than a stylistic preference.

## Symptoms

- A message proposing several artefacts as one unit of work, ending in a request to proceed.
- Ratifications arriving in a block at the end of a work session rather than one at a time through it.
- The same instruction being given more than once in a session.
- Under AFK: a loop halted on a permission question whose answer was already given.

## Workaround

Re-issue the instruction. It holds for the next few turns.

## Impact Assessment

- **Who is affected**: the maintainer, who has to re-issue a standing instruction and cannot review what is produced; and the AFK loop, which stalls on the gate.
- **Frequency**: twice in one session after explicit correction, and previously often enough to have earned a session memory.
- **Severity**: review cadence and throughput. Nothing produced is wrong, but it arrives in a shape that cannot be checked, and work built on an unratified format is rework.
- **Analytics**: none.

## Root Cause Analysis

Suspected: the one-at-a-time cadence is stated only in places that describe intent — session memory and CLAUDE.md prose — and never in a place that constrains behaviour. The capture SKILLs say how to produce a good artefact; none of them says how many to produce before stopping. With no contract, the agent falls back on the efficient-looking default of doing all the work and presenting it together, which is exactly wrong when the bottleneck is the maintainer's ability to review rather than the agent's ability to produce.

The ask-half has a known shape. P085 established that prose consent-gates need a detector before they stop; P132 established the inverse trap, where defensive over-asking accumulates from upstream corrections. This capture sits between them: the ask is not against an existing mechanical-stage declaration (P132's premise) — there is no declaration at all to ask against.

### Investigation Tasks

- [ ] Decide where the cadence contract lives. The candidates are an explicit statement in `packages/itil/skills/capture-story-map/SKILL.md` and `packages/itil/skills/capture-story/SKILL.md` that a capture session produces ONE artefact and then stops for ratification; a counted signal in `packages/retrospective/scripts/check-ask-hygiene.sh` alongside the lazy-AskUserQuestion count it already tracks; or a hook. The first two are cheap and compose; the third needs a reliable detector and probably should not lead.
- [ ] Make the cadence checkable rather than stated. The lesson from the memory that failed is that prose describing the rule is not the rule. Whatever lands should be able to fail.
- [ ] Settle what "one at a time" bounds. One artefact per message is clear for stories and maps; less clear for a fix that touches several files. Bound it to artefacts that carry a ratification, so ordinary multi-file work is unaffected.
- [ ] Cover the ask-half explicitly. "Want me to?" following a batch proposal is a live P085-class instance; whatever counts batches should also notice the gate on top, since the two arrive together.
- [ ] Check the AFK path separately. Under `--no-prompt` the failure mode is a stall rather than a wasted turn, and the safe default there is to produce one artefact, queue its ratification and continue — not to ask.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: (none)

## Related

- **P467** — the AFK loop surfaces ratifications batched at loop-end rather than continuously. Same "N accumulate before any are actionable" shape, opposite fix locus: P467 states the incremental *production* design is already correct and asks only for a better *surfacing* mechanism in the orchestrator. Here production cadence is the defect, in a foreground session with no loop.
- **P085** (closed) — prose consent-gates for already-obvious decisions. Covers the subordinate ask-half of this ticket, at the detector layer; its canonical pattern list already contains the "Want me to" phrasing observed here. No batching dimension.
- **P132** (closed) — over-asking against a stage a SKILL has already declared mechanical. Inverted premise: that ticket fixes ask-behaviour against an existing contract, and this one has to create the contract first.
- **P484** — the reading-context persona constraint is load-bearing but documented nowhere. It is why one-at-a-time is a correctness property here rather than a preference.
- **`feedback_work_incrementally_not_in_batches`** — the session memory recording the same correction from 2026-08-08. Its failure to survive one session is the evidence for this ticket.

(captured via /wr-itil:capture-problem; the title-only duplicate check surfaced nineteen matches on batch/incremental/ratifi, none of them this. The hang-off arbitration returned PROCEED_NEW against P467, P085 and P132 — the two closed tickets cannot absorb scope, and absorbing into P467 would widen an orchestrator-plumbing ticket into a foreground artefact-production contract.)
