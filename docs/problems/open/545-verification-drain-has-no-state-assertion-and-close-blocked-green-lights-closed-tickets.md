# Problem 545: The verification-close drain has no state assertion, and the do-not-close guard green-lights tickets that are already closed

**Status**: Open
**Reported**: 2026-09-19
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4. Impact 3: the mechanism ships in `@windyroad/retrospective` (the drain prose) and `@windyroad/itil` (the guard), so an adopter's retro can dispatch a batch of invalid closes; realised harm is bounded to wasted dispatches because the transition skill's own path-validation table rejects `.closed.md → close`, so no ticket is actually lost. Likelihood 4: the drain prose invites the mistake on every retro run against a README whose sections sit between the queue and the terminator, the gap has no control, and it was observed on first contact.
**Origin**: internal
**Effort**: M — a state assertion in the guard or the drain is small, but the two halves live in different packages (`packages/retrospective/skills/run-retro/SKILL.md` prose and `packages/itil/` guard), so it is a cross-package change with behavioural coverage on both.
**WSJF**: 6.0 — (12 × 1.0) / 2
**JTBD**: JTBD-006
**Persona**: developer

## Description

`/wr-retrospective:run-retro` Step 4a sub-step 9 — the prior-session evidence drain — produces its close candidates by reading a section of `docs/problems/README.md` by hand and filtering rows whose `Likely verified?` cell begins `yes — observed:`. Nothing between that scan and the `/wr-itil:transition-problem <NNN> close` dispatch asserts that a candidate is currently Verification Pending.

Two things compose into the defect.

**The section read is described by naming a terminator, and the README has sections in between.** Sub-step 9a says to read "the section that starts at the `## Verification Queue` heading and ends at the next `## ` heading". In this repository the README carries `## WSJF Rankings` (line 6), `## Verification Queue` (135), `## Inbound Upstream Reports` (307), `## Closed` (402) and `## Parked` (518). An agent that bounds the range on `## Parked` — the terminator the skill's own render contract names alongside the queue, in the same sentence, at every render site — silently swallows the Inbound and Closed sections.

**The guard the drain relies on does not check state.** Observed 2026-09-19 during the P463 iteration retro: the mis-scoped read produced 19 close candidates (P499, P049, P068, P069, P071, P076, P150, P186, P447, P166, P384, P391, P392, P394, P184, P228, P211, P282, P287), every one of them already a `.closed.md` file whose Closed-section row happened to carry a `yes — observed:` citation from its own original close. `wr-itil-is-close-blocked <NNN> docs/problems` was run against all 19 and returned exit 1 — not blocked — for every one. The real Verification Queue holds zero evidence-bearing rows.

So the pre-flight the drain positions immediately before a close dispatch gives a green light on tickets that are not in `verifying/` at all. The only thing that would have caught the batch is the transition skill's own path-validation table, as `invalid-transition`, after 19 dispatches had already been issued.

This is the same defect class as P252 / P264 on a different surface. Those tickets fixed `packages/itil/scripts/reconcile-readme.sh`, whose section-boundary detection knew only four headers and therefore sliced the Verification Queue range all the way through the Inbound Upstream Reports section. The script was taught `INBOUND_START` and the bug was closed in 2026-05-17. The prose that asks an agent to perform the same slice by hand was never given the same correction, so the agent reproduces the fixed bug.

## Symptoms

- 19 already-closed tickets surfaced as prior-session close candidates from a single mis-scoped section read (2026-09-19, P463 iteration retro).
- `wr-itil-is-close-blocked` returns exit 1 (not blocked) for a ticket in `docs/problems/closed/`, so it cannot distinguish "safe to close" from "already closed" or "never was verifying".
- The real Verification Queue's evidence-bearing row count was zero, so the drain had nothing to do and reported 19 candidates.

## Workaround

Before dispatching any close from the drain, confirm each candidate resolves to a file under `docs/problems/verifying/`:

```bash
find docs/problems/verifying -name "<NNN>-*" | grep -q . || echo "not verifying — drop candidate"
```

Bound the sub-step 9a section read mechanically on the next `## ` heading rather than on a named terminator.

## Impact Assessment

- **Who is affected**: whoever runs a retro over their own backlog — the `developer` persona JTBD-006 is written for. The mechanism ships, so adopters inherit it.
- **Frequency**: every run-retro that reaches Step 4a sub-step 9 against a README with sections between the queue and the named terminator.
- **Severity**: High (12) — a batch of invalid close dispatches; contained by the transition skill's path validation, so no ticket is lost.
- **Analytics**: 19 false candidates from one scan, 2026-09-19; 0 true candidates in the actual queue.

## Root Cause Analysis

### Investigation Tasks

- [ ] Add a state assertion so a candidate that does not resolve to a file under `docs/problems/verifying/` is rejected before dispatch. Decide whether it belongs in the drain or in `wr-itil-is-close-blocked` itself — the guard is the surface every close path already calls, which argues for putting it there.
- [ ] Reword sub-step 9a to bound the section read mechanically on the next `## ` heading, and say explicitly that naming `## Parked` as the terminator is wrong because `## Inbound Upstream Reports` and `## Closed` sit between.
- [ ] Behavioural coverage: a candidate set containing an already-closed ticket must be rejected before any transition dispatch is issued.
- [ ] Check whether the same hand-rolled slice appears in other SKILL prose that P252's script fix did not reach.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: (none)

## Related

- **P252** (`docs/problems/closed/252-reconcile-readme-false-positive-parses-inbound-upstream-reports-matched-local-ticket-column-as-verification-queue.md`) — the same defect on the script surface, fixed 2026-05-17 by teaching `reconcile-readme.sh` an `INBOUND_START` boundary. The prose that asks an agent to do the slice by hand did not get the correction.
- **P264** (`docs/problems/closed/264-...md`) — closed as a duplicate of P252; its Description states the boundary problem exactly ("the range it slices for VQ extraction runs from `## Verification Queue` all the way to `## Closed`, capturing the Inbound Upstream Reports section in between").
- **P282** — the ticket that defined the prior-session evidence drain this defect sits in.
- Captured via `/wr-itil:capture-problem` during the `/wr-itil:work-problem 463` iteration retro (2026-09-19), Step 4b Stage 1 mechanical ticketing of a Step 2b pipeline-instability detection.
