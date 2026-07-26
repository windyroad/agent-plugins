# Problem 471: run-retro Step 2d ask-hygiene trail path collides across same-day iterations, clobbering prior entries

**Status**: Open
**Reported**: 2026-07-26
**Priority**: 8 (Medium) — Impact: 2 × Likelihood: 4 — derived at capture from the description per Step 4a
**Origin**: internal
**Effort**: S — derived at capture per Step 4a
**JTBD**: JTBD-006
**Persona**: developer

## Description

`/wr-retrospective:run-retro` Step 2d instructs: *"Persist trail entry at
`docs/retros/<YYYY-MM-DD>-ask-hygiene.md` (one file per retro; date in filename for natural
sort-by-date)."* One file per **date** is not one file per **retro**. An AFK
`/wr-itil:work-problems` loop runs run-retro once per iteration, and several iterations land on
the same day, so the second iteration's write silently destroys the first's entry.

The collision-free convention already exists on disk — `docs/retros/` holds
`2026-07-26-p417-iter-ask-hygiene.md`, `…-p424-iter-…`, `…-p430-iter-…`, `…-p431-iter-…`,
`…-p438-iter-…` alongside the bare `2026-07-26-ask-hygiene.md`, and the same split appears on
2026-07-05 — but the SKILL never states it. An agent following Step 2d literally writes the bare
dated path and clobbers whatever was there.

Witnessed this iteration: the P433 retro wrote the bare `2026-07-26-ask-hygiene.md` per the SKILL
text and destroyed the P429 iteration's entry (recovered via `git checkout --` only because the
agent happened to diff the file afterwards). An agent that did not check would have lost it, and
the loss is invisible — the file still exists and still parses, it just describes a different
iteration.

The damage is quiet and compounding: `packages/retrospective/scripts/check-ask-hygiene.sh`
consumes these files for the ADR-044 cross-session lazy-count trend and the R6 numeric gate
(lazy count ≥2 across 3 consecutive retros). A day of AFK iterations collapses to one datapoint,
so the trend under-samples exactly the surface it is meant to watch, and the R6 gate can fail to
fire because the retros that would have tripped it were overwritten.

## Symptoms

- Two retros on the same date leave one trail file; the earlier iteration's classifications and
  citations are gone with no error and no diff signal at write time.
- `check-ask-hygiene.sh` reports fewer `RETRO` lines than retros actually ran.
- The bare `<date>-ask-hygiene.md` and the `<date>-p<NNN>-iter-ask-hygiene.md` files coexist with
  no documented rule for which surface writes which.

## Workaround

Write the trail to `docs/retros/<YYYY-MM-DD>-p<NNN>-iter-ask-hygiene.md` when the retro runs
inside an AFK iteration, reserving the bare `<YYYY-MM-DD>-ask-hygiene.md` for a standalone
interactive retro. Before writing either, check whether the target exists and read it — if it
describes a different session, pick the per-iter path instead.

## Impact Assessment

- **Who is affected**: developer running AFK backlog loops; anyone reading the ask-hygiene trend.
- **Frequency**: every day on which more than one retro runs — the normal shape of an AFK loop.
- **Severity**: Medium — no code or published artefact is harmed, but the ADR-044 regression
  metric silently under-samples and the R6 gate that consumes it can fail to fire.
- **Analytics**: `ls docs/retros/ | grep ask-hygiene` shows the two competing conventions on both
  2026-07-05 and 2026-07-26.

## Root Cause Analysis

### Investigation Tasks

- [ ] Investigate root cause — the immediate cause is that Step 2d's filename template carries no
      per-retro discriminator; confirm whether any other Step 2d consumer (the trend script's glob,
      the R6 gate) also assumes one-file-per-date.
- [ ] Check the sibling trail surfaces for the same defect — `docs/retros/<date>-context-analysis.md`
      (Step 2c) is written under the same one-per-date assumption and carries an explicit
      once-per-day guard, so it may be correct by design rather than by accident; establish which.
- [ ] Create reproduction test — behavioural, per ADR-052: run the trail-write twice against a
      fixture `docs/retros/` and assert both entries survive and the trend script sees two `RETRO`
      lines.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P135 (the decision-delegation master that owns the ask-hygiene surface and
  its R6 numeric gate — this ticket is a defect in that surface's persistence layer, not in its
  classification logic).

## Related

Captured via `/wr-itil:capture-problem` during the P433 iteration retro.

The hang-off-check subagent dispatch was **skipped**: the mechanical pre-filter on the
`docs/retros` file-path signal returned 7 candidates, above the 5-candidate latency cap, so per
the capture-problem sub-step 2b contract the candidate list is recorded here for review-time
re-evaluation by `/wr-itil:review-problems` instead. Candidates were P248, P135, P148, P164,
P193, P330, P332. Of these, P135 is the plausible parent (it owns the ask-hygiene surface) and is
recorded above as a `Composes with` edge; the rest share only the `docs/retros` path token.
