# Problem 480: An ADR's ratification is document-scoped, so riders that were never weighed inherit its authority

**Status**: Open
**Reported**: 2026-08-08
**Priority**: 12 (High) — Impact: 4 × Likelihood: 3 — derived at capture from the description per Step 4a. Impact 4: a rider can contradict an accepted-tier decision and be defended as ratified substance, which is a governance failure rather than a legibility one — ADR-103's rider permitted exactly what ADR-060 I6 hard-blocks. Likelihood 3: present in all three ADRs authored in one two-day window, including the two written specifically to fix the sibling problem. Effort informed by P465 (M — a brief-surface change plus a review-contract rule plus behavioural tests).
**Origin**: corrective-feedback
**Effort**: M — one rule (one document, one decision) applied at authoring and at architect review, plus a detector and behavioural tests — cf. P465 (M)
**WSJF**: 6 — (12 × 1.0) / 2 (added 2026-08-21 review)
**JTBD**: JTBD-008
**Persona**: developer

## Description

A human ratifies an ADR by confirming *a decision*. The marker lands on *a document*. Every claim in that document then reads as ratified, including claims that were never weighed as options and are not what the title decides.

The maintainer, on ADR-103:

> The decision is "A release row is the RFC, and the map is the approval surface" — that is what I've ratified, nothing else in that document. You can't put riders into an ADR and expect them to carry any weight.

ADR-103's `## Considered Options` weighed three: leave it; align RFCs to rows by convention; or a release row *is* the RFC with the map as the only approval surface. Option C was chosen and confirmed. But its Decision Outcome also asserts:

- *"Row status is derived, never authored — `delivered` when every story in the row is done or archived, `proposed` when a problem or an RFC names it, `unproposed` otherwise."*
- *"A row with neither is drawn but unproposed — a legitimate state, and the one speculative work sits in."*

Neither was weighed. Neither is what the title decides. Both are riders.

### The harm is authority, not correctness

The riders were not obviously wrong. The problem is what happened when one was challenged.

The maintainer said an untraced row should be a defect rather than a state. Both the agent and `wr-architect:agent` treated removing `unproposed` as amending ratified substance: the review concluded the marker must clear and the ADR be re-ratified through a P357 post-change brief. That whole process cost was incurred to retract something the maintainer had never ratified. The rider was being defended as though it were the decision.

**And the rider silently contradicted an accepted-tier ADR.** ADR-060 — `accepted`, the strongest status in this cluster — states at I6 that every story traces to at least one problem, hard-blocked at capture. A row is untraced exactly when no story in it traces a problem. So ADR-103's "legitimate state" permitted precisely what I6 forbids. ADR-060 does appear in ADR-103's `amends:` list, but for the RFC↔story edge amended elsewhere in the body — not for this clause. An unratified rider effectively amended an accepted decision, undeclared.

### It is not one document

The same shape is in both ADRs written the next day, by the same author, in the change made to fix the sibling problem:

- **ADR-104** — three bolded claims in its Decision Outcome beyond the chosen option, under a `### What this does not decide` heading.
- **ADR-105** — two bolded claims plus a `### Why committed markup is affordable now` section.

The first framing of this ticket asked for a *discriminator* between a legitimate carve-out and a rider. The maintainer rejected that outright:

> I don't want this arbitrary distinction between a rider and a carve out. One decision document contains one decision. Implementation notes don't belong in there. If you need another decision create a new decision document.

So there is no discriminator to find, and the rule is simpler than the problem looked:

- **One decision document contains one decision.** If the title names it and the options weighed it, it belongs. Nothing else does.
- **Implementation notes do not belong in a decision document.** They go where the implementation is — a code comment, a SKILL, an RFC.
- **A second decision gets a second document.** Not a section, not a bolded paragraph under the first one's Decision Outcome.

That also disposes of the "what does a confirm event cover" question. A confirm event covers the decision, because the document holds exactly one.

## Symptoms

- An ADR asserting something its `## Considered Options` never weighed.
- A claim in a ratified ADR that contradicts a higher-tier decision, with no corresponding `amends:` entry for that clause.
- Removing such a claim being treated as an amendment requiring re-ratification — process cost spent retracting what was never ratified.
- A ratification brief that names the document rather than enumerating the claims being confirmed.

## Workaround

When challenged on a clause, check whether the title names it and the `## Considered Options` weighed it. If not, it was never ratified, and correcting it needs no amendment ceremony — it is a second decision that wants its own document, or an implementation note that wants a code comment.

## Impact Assessment

- **Who is affected**: whoever ratifies a decision, and every later reader who takes a ratified document's claims as settled.
- **Frequency**: three of three ADRs authored 2026-08-07 to 2026-08-08.
- **Severity**: governance. A rider can carry more authority than the accepted-tier decision it contradicts, because it sits inside a confirmed document and the contradiction is not declared.
- **Analytics**: none.

## Root Cause Analysis

Suspected, not confirmed: ratification is document-scoped because the marker is a file-level field, and nothing constrains an ADR body to the claims its options weighed. The `/wr-architect:create-adr` Step 5 brief presents the decision; the `human-oversight: confirmed` marker then attaches to everything in the file.

Not yet established: where the rule is enforced, and where implementation notes should live once they are no longer permitted in a decision document. The rule itself is settled — one document, one decision — so what remains is mechanism, not definition.

### Investigation Tasks

- [ ] Decide where the one-decision-per-document rule is enforced: the `/wr-architect:create-adr` authoring flow, the `wr-architect:agent` review contract, or both. Review is the backstop; authoring is where it is cheap.
- [ ] Build the detector. It is more tractable than the discriminator version: a `## Decision Outcome` asserting something no `## Considered Options` entry weighed is a second decision or an implementation note, and either way it does not belong. Surfaces the existing backlog rather than only catching new cases.
- [x] **Decide where implementation notes go instead.** Settled by the maintainer, 2026-08-08: *"I think they should go in the story as well, or if there isn't a story to put them into yet the ADR may contain them but it must hedge them as saying that they are implementation notes and not something to be enforced."*

  So the rule is a preference with a named fallback, not a prohibition:

  1. **The story** is the home. An implementation note describes how something gets built, and the story is the unit that gets built.
  2. **No story yet?** The ADR may hold the note — but it must be explicitly marked as an implementation note and as **not enforceable**. An unmarked note in a decision document is indistinguishable from a decision, which is this ticket's whole failure mode.
  3. **Once the story exists**, the note moves to it.

  The fallback matters: a flat ban would leave a note with nowhere to go at the moment an ADR is written, which is exactly the pressure that put riders in ADRs in the first place. Hedging is what stops an unratified note inheriting the document's authority.

  Still to build: the hedge needs a form the review contract can check (a named section or marker), so `wr-architect:agent` can tell a hedged note from a rider. An unhedged implementation note in a `## Decision Outcome` stays a finding.

  Note the earlier candidate "the RFC that vehicles the change" is dead — under ADR-103 a release row *is* the RFC and `docs/rfcs/` is frozen, so there is no RFC document to carry a note.
- [ ] Audit the in-force corpus. ADR-104 and ADR-105 are known instances, authored 2026-08-07; each needs its extra claims split into their own decisions or demoted to implementation notes. ADR-102 was already split for this reason on 2026-08-07 and is the worked example.
- [ ] Check the audit for riders contradicting a higher-tier decision, the way ADR-103's did against ADR-060 I6. That is the class where the harm is governance rather than legibility, and it is the reason this is Impact 4.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P479.

## Related

- **P479** (`docs/problems/open/479-decisions-accrete-into-the-nearest-adr-because-amending-is-cheaper-than-deciding.md`) — sibling, and the hang-off arbiter returned PROCEED_NEW on four observables. P479's instances arrived *by amendment* after the confirm event; these were in the original ratified draft, above the amendment headings, so absorbing this would make P479's own root-cause sentence ("no rule that an **amendment** must answer the same question its parent weighed") false for half its evidence. Different fix locus too: P479 targets the moment of amending, this targets what a document may assert and what a confirm event covers. They are siblings under a parent neither ticket is — *an ADR's ratification is document-scoped, not claim-scoped*. Worth clustering at `/wr-itil:review-problems`.
- **P479 adjacency worth seeing**: its Symptoms name "a `## Consequences` list containing entries that follow from no stated option" — the same observable as this ticket, reached by the other route — and its costs name the P348 hollow-marker shape, which is the ratification-authority axis this ticket is on.
- **ADR-103** — the instance. Its `unproposed` clause is being removed as a rider rather than amended as substance.
- **ADR-060** I6 — the accepted-tier rule the rider contradicted.
- **ADR-104**, **ADR-105** — same shape, authored the following day. Both carry claims beyond their chosen option and need splitting or demoting under the one-decision rule.
- **ADR-102** — split into ADR-102/104/105 on 2026-08-07 for this exact reason, which makes it the worked example of the remedy.
- Maintainer correction, 2026-08-08, during the STORY-MAP-003 review.

(captured via /wr-itil:capture-problem; expand at next investigation)
