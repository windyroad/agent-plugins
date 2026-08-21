# Problem 479: Decisions accrete into the nearest ADR because amending is cheaper than deciding

**Status**: Open
**Reported**: 2026-08-07
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4 — derived at capture from the description per Step 4a. Impact 3: an ADR that carries six decisions cannot be reviewed, reversed or ratified per-decision, and its Considered Options stop describing what was actually weighed — the record survives but stops being usable. Likelihood 4: it happened twice in one session on one document, and the mechanism (amending needs no options, no ratification event, no new file) rewards it every time.
**Origin**: corrective-feedback
**Effort**: M — a rule the architect agent can apply at review time, plus a detector for ADRs whose amendment count outruns their options — cf. P465 (M)
**WSJF**: 6 — (12 × 1.0) / 2 (added 2026-08-21 review)
**JTBD**: JTBD-008
**Persona**: developer

## Description

ADR-102 weighed exactly one question. Its `## Considered Options` section lists two: **A** two files per map (a `.json` source plus a generated `.html`), and **B** one self-contained `.html` carrying its data in an embedded island. That is the decision the maintainer ratified on 2026-08-05.

Five further decisions were then amended into the same document, none of them ever weighed as an option:

1. A story map is a two-dimensional grid rather than a stacked list (amends ADR-060).
2. The ratification fingerprint is scoped to the data island rather than the whole file (amends ADR-090).
3. The renderer resolves through `bin/` on `PATH` (amends ADR-049).
4. Story status, card values, row status and map problems are derived from the story corpus rather than authored on the map.
5. The grid is built at view time by a shared script — added 2026-08-06, then reversed 2026-08-07 when it turned out a map opened on a phone showed a fallback message instead of the map.

Item 5 was amended in and reversed **within the same session**, without anyone asking whether a render-locus decision belonged in a document about file count.

The maintainer's correction: *"don't try to shoehorn 50 decisions into one document. This decision is about if it should be one file or two. That's it. If you need to record additional decisions do that with their own files."*

### Why the pull is toward amending

Amending is structurally cheaper than deciding, at every step:

- An amendment needs no `## Considered Options`. A new ADR does, and writing options means finding a real alternative and arguing against it.
- An amendment inherits the parent's ratification. A new ADR is born `human-oversight: unconfirmed` and has to reach a human.
- An amendment needs no ID allocation, no compendium entry, no `amends:` back-reference chain.
- The architect agent, asked "amendment or supersession?", answers on the amendment-versus-supersession axis — which is the wrong axis. It correctly advised amendment over supersession for the 2026-08-07 reversal, citing ADR-066's tighten-the-mechanism test, and neither of us asked the prior question: does this content belong in this document at all? Both available answers kept the content in ADR-102.

The result is that the cost of a bad decision falls, because a decision buried in an amendment never has to justify itself against an alternative. Item 5 is the evidence: it shipped with its own failure mode written into the body — *"the grid is unreachable without script"* — accepted in a sentence, because no option had to be argued against it.

### What it costs

- **Reversal is expensive.** Reversing item 5 required marking three passages in place, splitting an amendment heading whose two halves had opposite fates, and re-scoping a set of corpus measurements to the past. A standalone ADR would have been superseded by one file.
- **Ratification becomes all-or-nothing.** ADR-102's marker covers the 2026-08-05 confirm event and enumerates three amendments. The 08-06 pair was never separately ratified, so a materially changed body carried an approval that predated it — the P348 hollow-marker shape, arrived at through accretion rather than through a hand-written marker.
- **The Considered Options section stops describing the decision.** A reader matching outcome to options finds two options and six outcomes.

## Symptoms

- An ADR whose amendment count exceeds its option count.
- An amendment introducing a mechanism that was never named in `## Considered Options`.
- An amendment reversed in the same session it was added.
- A `## Consequences` list containing entries that follow from no stated option.

## Workaround

Before amending an ADR, ask whether the change answers the question that ADR's `## Considered Options` weighed. If it answers a different question, it needs its own record — even when amendment is technically the right vehicle for the parent.

## Impact Assessment

- **Who is affected**: anyone reading a decision record to find out what was decided and why, and anyone trying to reverse one.
- **Frequency**: six decisions in one ADR; two of them added in a single session.
- **Severity**: governance rather than runtime. The decisions were all individually sound — the record of them is what degraded.
- **Analytics**: none.

## Root Cause Analysis

Suspected, not confirmed: there is no rule anywhere that an amendment must answer the same question its parent weighed, and no check that would notice when one does not. The architect agent has a well-developed amendment-versus-supersession test (ADR-066) and no belongs-here-at-all test, so the question it is asked is answerable without the question it is not asked ever surfacing.

Not yet established: whether this recurs outside ADR-102, and whether the same pull explains any of the amendment chains on ADR-060 or ADR-090.

### Investigation Tasks

- [ ] Check whether this is ADR-102-specific or general — count amendments against `## Considered Options` entries across the corpus, and look at ADR-060 and ADR-090 first, since both carry long amendment chains.
- [ ] Decide where the rule belongs: `wr-architect:agent`'s review contract, `/wr-architect:create-adr`, or both. It has to fire when someone is *about to amend*, which is the moment the cost asymmetry bites.
- [ ] Consider a detector: an ADR whose amendment count exceeds its option count is a candidate for splitting. Cheap to compute, and it surfaces the backlog rather than only catching new cases.
- [ ] Decide whether an amendment introducing a genuinely new mechanism should clear the parent's oversight marker. ADR-066 line 99 already says a Decision-Outcome-changing amendment SHOULD clear it; the 08-06 amendment did not, so either the rule is unenforced or its trigger is too narrow.
- [ ] Reckon with the counter-pressure: splitting has costs too, and "not everything needs to be a decision" (maintainer, 2026-08-07). The rule must distinguish a decision from a mechanism, or it will generate ADRs for defect fixes and for applications of existing decisions.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: (none)

## Related

- **ADR-102** — the document this was found in. Being stripped back to its one-file-versus-two decision, with the render-locus and derived-not-authored decisions extracted to their own ADRs. The grid encoding, the `bin/` shim and the island-scoped fingerprint stay: the first is context, the second applies ADR-049 rather than deciding anything, and the third is a consequence of choosing one file.
- **ADR-066** — supplies the amendment-versus-supersession test the architect correctly applied, and lacks the belongs-here-at-all test that would have caught this.
- **P478** — sibling in shape: a check that exists but is under-specified, versus a check that does not exist at all.
- Maintainer correction, 2026-08-07, during the ADR-102 ratification review.

(captured via /wr-itil:capture-problem; expand at next investigation)
