---
status: "proposed"
date: 2026-09-19
human-oversight: unconfirmed
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: []
reassessment-date: 2026-12-19
supersedes: ["ADR-079 (in part — the Phase 2 `ADR-shipped-confirmed` and `named-skill-or-feature-exists` mechanical checks, and the Phase 2 chosen-option shape list that carries them; everything else in ADR-079 stands)"]
jtbd: [JTBD-006, JTBD-201]
persona: developer
---

# Only shipped-and-released evidence closes a ticket

> Captured via /wr-architect:capture-adr (foreground-lightweight aside-invocation per ADR-032, derived-substance amendment 2026-07-06 / RFC-045). Section content was derived by the capturing agent from the in-session decision context; human-oversight: unconfirmed until ratified at the /wr-architect:review-decisions drain.

## Context and Problem Statement

The relevance-close evaluator decides, without a human in the loop, whether a backlog ticket has stopped being relevant and can be closed. Two of its five evidence shapes ask only whether a thing the ticket **names** exists: a decision record that carries a ratification marker, or a skill or hook file on disk. Naming is not shipping. A ticket that reports a ratified decision nobody built cites that decision by construction, so the shape fires hardest on exactly the tickets that most need to stay open.

The measurement is on the record. Over the 135 open and known-error tickets scanned on 2026-08-21 the evaluator returned 102 `CLOSE-CANDIDATE-WITH-CAVEAT`, 7 clean `CLOSE-CANDIDATE`, 6 `KEEP-WITH-NOTE`, 1 `KEEP` and 19 `SKIP` — an 81% close rate against a documented expectation of about 4.2%, up from 76% on 2026-07-26. All 7 clean verdicts were checked by hand and every one was a live ticket. A clean verdict closes silently in an unattended pass, so those 7 were seven silent losses of live backlog, not seven wasted dispatch decisions.

The sharpest case is a ticket reporting that a story's `accepted` gate does not enforce a ratified decision. The evaluator closed it citing the very decisions the ticket exists because nothing implements. The shape read "this decision is ratified" as "this decision is implemented".

Driver: P463.

## Decision Drivers

- **A close must rest on something that happened, not on something that was agreed.** An identifier in a ticket is an audit-trail annotation; it is never the thing that carries the meaning. The ratified `developer` persona says so directly, and these two shapes make an identifier carry the claim "a fix shipped".
- **Absence of evidence is not evidence.** JTBD-006 states that the agent never closes on inference, and that a fix nobody exercised stays open however old it is. Reading a `## Related` citation as a shipped fix is closing on inference.
- **The failure is worst where the ticket is most valuable.** A ticket whose whole content is "this ratified decision is unenforced" cites that decision by construction. The two shapes fire hardest on live enforcement gaps.
- **The unattended path is where the harm lands.** A caveated verdict costs a wasted dispatch decision. A clean verdict in an unattended pass costs a live ticket, silently.
- **A missed close is cheap; a wrong close is data loss.** Under the persona constraint that the agent is not trusted to make judgment calls, the asymmetry runs one way: a ticket that should have closed queues for a human and gets closed next pass.
- **Maintainer direction, 2026-09-19**, pinning the chosen option after the option set below was queued from the 2026-08-21 review.

## Considered Options

1. **Only shipped-and-released evidence (chosen)** — switch both shapes off outright and admit only evidence that a fix landed: released and resolution section content, and completed task checkboxes.
2. **Scope the two shapes to a fix-evidence region** — keep both signals but make them positional, so a citation counts only inside a released or resolution section or on a ticked task line, and stops counting in background, dependencies or related work.
3. **Drop the decision-record signal only** — retain the narrowed skill-path signal, on the argument that agreeing a decision says nothing about whether anyone built it.
4. **Require corroboration** — let neither signal close a ticket alone; each counts only alongside an independent one such as a file genuinely gone, a self-marker, or a closed driver.
5. **Never let these two signals close silently** — leave the searches as they are but force both to emit with a caveat, so a human always sees them.
6. **Do nothing** — handle the 81% rate by suspending the unattended close pass instead.

## Decision Outcome

Chosen option: **"Only shipped-and-released evidence"**.

**The one mechanic, stated once.** A decision-record citation and a skill-or-feature-path citation never count as evidence that a ticket's fix has shipped — not in `## Related`, not in `## Dependencies`, and not inside a released or resolution section either. Both shapes are switched off outright, rather than made positional. The fix-evidence set that remains is:

- the content of a `## Fix Released` or `## Resolution` section, which ADR-079's `self-marker-in-body` shape already reads by its line-anchored heading literal; and
- completed task checkboxes, under the bound recorded below.

ADR-079's `file-no-longer-exists`, `self-marker-in-body` and `driver-child-ticket-closed` shapes keep the substance ADR-079 recorded for them. Its cumulative multi-shape verdict model is untouched.

**The completed-checkbox arm is new substance recorded here, not an edit to ADR-079.** ADR-079's `self-marker-in-body` check is a closed list of line-anchored literals and contains no `- [x]` literal; today the evaluator reads checkboxes only in the opposite direction, as the input to its `multi-phase-mixed-progress` caveat. So this arm is an addition, and it composes with ADR-079's shape 4 rather than rewriting it. It carries its own bound, because the same defect this decision closes has an obvious second axis: a ticked **investigation** task records that investigating finished, not that a fix shipped. The bound is that the arm counts only when the ticket has **no unticked checkbox left anywhere in its body**, and the existing `multi-phase-mixed-progress` caveat is retained and becomes load-bearing for it — any outstanding task sends the verdict to a human instead of closing it.

**Verdicts name where the evidence was found.** A verdict cites the section or line that carried the evidence, so it is checkable without re-reading the ticket. With the released-section arm near-inert on the scanned population, most surviving verdicts will cite a checkbox, and which checkbox is the whole of the verdict's meaning.

**Implementation is not authorised by this record.** `packages/itil/scripts/evaluate-relevance.sh` and its behavioural suite change only after this decision is ratified. The record is born `human-oversight: unconfirmed` because it was written in an unattended run where no confirmation event was possible; the maintainer's 2026-09-19 direction pins the substance above but is not ratification of this body.

### What this displaces in ADR-079, named

ADR-079 is **not** renamed to `.superseded.md` — partial supersession leaves a decision in force, and everything not named here still governs.

- Its Phase 2 mechanical check for `ADR-shipped-with-human-oversight: confirmed` — displaced, the shape is off.
- Its Phase 2 mechanical check for `named-skill-or-feature-exists` — displaced, the shape is off.
- Its Phase 2 chosen option, recorded as extending the script with shapes 2 through 5 — displaced only as to the shape list. The in-force set is now shapes 1, 4 and 5 plus the completed-checkbox arm above.
- Its labeled 14-fixture set, which ADR-079 designates as the regression suite under ADR-052 — the shape-2 and shape-3 labels lapse. Fixtures labelled shape-2 or shape-3 only no longer classify as close candidates and must be re-labelled under the surviving shapes or retired. The surviving fixtures keep their labels.

The empirical grounding ADR-079 recorded for shapes 2 and 3 — that they covered 8 and 6 of those 14 historical closes — stands as history. It was drawn from closes a human was performing by hand, and does not carry over to an unattended pass.

### What this displaces downstream

STORY-064, on release row RFC-070 of STORY-MAP-011, decomposes this change and encodes the positional reading: two of its acceptance criteria state that a ticket naming the same ratified decision where it records the fix landing still comes back as a close candidate, so the signal is narrowed rather than switched off. That is option 2, which was not chosen. Those criteria are superseded by this decision and the story must be re-drawn to the switched-off reading before any implementation commit. The story is `draft`, so nothing is implementable against it today (ADR-096).

## Consequences

### Good

- A close rests on evidence a fix shipped. The class of failure that produced seven silent losses of live backlog on one pass cannot recur through these two shapes.
- The tickets the evaluator failed hardest on — a ratified decision nobody built — are precisely the ones it now leaves alone.
- The remaining signals are all observable events: a file gone, a release marker written, a task list finished, a driver closed.
- The unattended pass becomes trustworthy enough to leave on, which is what JTBD-006 asks of it.

### Neutral

- Genuine close candidates that only ever carried a citation now stay open until a human or a surviving shape reaches them. The queue is longer and honest rather than shorter and wrong.
- ADR-079 remains in force and in the compendium with its original title, which still advertises both retired shapes. Naming the displacement here is the available mitigation; the compendium generator renders no back-link on a partially superseded entry.

### Bad

- The released-and-resolution arm is near-inert on the population actually scanned. `## Fix Released` is machine-written only at the Known Error to Verification Pending transition, and the evaluator scans open and known-error tickets. Four of 119 open and known-error tickets carry such a heading today; 30 of 119 carry at least one ticked task. The completed-checkbox arm therefore carries roughly seven times the weight of the released-section arm, and it is the arm with no ADR-079 provenance. Its bound and its behavioural coverage are load-bearing, not incidental.
- The documented close rate of about 4.2% now has no basis in either the old shape set or a measured one. It has to be re-derived against the new set rather than asserted.
- The regression suite shrinks. Most of its labelled fixtures were shape-2 or shape-3 cases.

## Confirmation

Behavioural coverage in `packages/itil/scripts/test/evaluate-relevance.bats`, per ADR-052:

- A ticket that cites a ratified decision only under `## Related` does **not** return `CLOSE-CANDIDATE`, and does not return `CLOSE-CANDIDATE-WITH-CAVEAT` on that citation alone.
- A ticket that cites a ratified decision inside its `## Fix Released` section does **not** return a close candidate on the citation itself — the switched-off reading, distinguishing this decision from the positional option.
- A ticket that names an existing skill or hook path, anywhere in its body, does **not** return a close candidate on that path.
- A ticket whose every checkbox is ticked returns a close candidate, and its verdict names the lines that carried the evidence.
- A ticket with at least one unticked checkbox returns `CLOSE-CANDIDATE-WITH-CAVEAT` with the `multi-phase-mixed-progress` tag, never a clean verdict.
- The `file-no-longer-exists`, `self-marker-in-body` and `driver-child-ticket-closed` verdicts are unchanged against their surviving fixtures.

Two further checks confirm the decision is holding once implemented:

- Re-run the evaluator across the whole open and known-error population and record the measured close rate. The documented expectation is replaced by that number, not by an assertion.
- Every verdict emitted carries a locating cite naming the section or line.

## Pros and Cons of the Options

### Only shipped-and-released evidence (chosen)

- Good, because no citation can be read as a shipped fix, so the defect cannot re-enter through a region the scoping missed.
- Good, because it is the simplest rule to hold in your head and to test: these two signals are gone.
- Bad, because it discards the real closes those shapes used to catch, and the arm that replaces them is weaker on the scanned population than it looks.

### Scope the two shapes to a fix-evidence region

- Good, because it preserves both signals and fixes the wrong-region defect at source.
- Bad, because a citation inside a released section still proves only that the decision exists, so the inversion survives in the narrower region.
- Bad, because the released section is near-inert on the scanned population, so most of the preserved signal would never fire anyway.

### Drop the decision-record signal only

- Good, because it targets the shape with the clearest inversion and the worked failure.
- Bad, because the skill-path shape has the same inversion on a different axis: a ticket naming the skill whose behaviour is defective matches on that skill existing.

### Require corroboration

- Good, because it keeps both signals available while making either one insufficient alone.
- Bad, because two inverted signals can corroborate each other — a governance ticket typically cites both a decision and a skill path.

### Never let these two signals close silently

- Good, because it targets the measured harm exactly: the damage came from clean verdicts closing unattended.
- Bad, because it leaves 81% of the backlog emitting close candidates, which drowns genuine ones and poisons the pre-dispatch relevance gate that consumes the same evaluator.

### Do nothing

- Good, because it costs nothing and the workaround already in place — treat every verdict as advisory — is known to work.
- Bad, because it leaves a shipped evaluator in adopter trees that closes live tickets silently, and suspending the pass forfeits the outflow path the backlog was given.

## Reassessment Criteria

Reassess if any of these hold:

- The measured close rate after implementation is below about 1%, which would mean the surviving evidence set is too thin to be an outflow path at all and the corroboration option deserves another look.
- A wrong close is observed through the completed-checkbox arm — a ticket closed on a fully ticked task list whose fix had not shipped. That is this decision's own defect class on the new axis and would force the arm to be bounded further or retired.
- `## Fix Released` or `## Resolution` becomes machine-written on open and known-error tickets rather than only at the Verification Pending transition, which would make the released-section arm live and shift the weight off the checkbox arm.
- A new evidence shape reaches mechanical confidence comparable to `file-no-longer-exists`, which would restore outflow without re-admitting citations.

## Related

- **P463** (`docs/problems/known-error/463-relevance-close-evaluator-over-fires-citation-read-as-fix-shipped.md`) — driver. Carries the 2026-07-26 and 2026-08-21 measurements, the worked false-positive cases, and the maintainer direction of 2026-09-19 that pins this substance.
- **ADR-079** — the decision this supersedes in part. Scope named above; not renamed, still in force for everything else.
- **ADR-116** — ratified decisions change only by supersession. The mechanism this record uses; ADR-079's body is not edited, no amendment section is added, no `amends:` claim is made.
- **ADR-103** — implementation is refused while a proposal needs a decision that is not yet ratified. This is why the evaluator does not change in the same commit.
- **ADR-110** — a ratification marker can only be written when someone actually ratified. Why this record is born `unconfirmed`.
- **ADR-026** — agent output grounding. The locating cite requirement above is the cite leg; the retained caveat is the uncertainty leg.
- **ADR-022** — the Open or Known Error to Closed-with-reason bypass that ADR-079 added is untouched; only the evidence admitted to it narrows.
- **ADR-052** — behavioural tests default. The Confirmation section is the contract.
- **ADR-119** — a fix proposal draws a release row, never a document. The fix vehicle is release row RFC-070 on STORY-MAP-011, carrying STORY-064.
- **ADR-096** — a draft story is never implementable, which is why STORY-064's superseded acceptance criteria block nothing today.
- **JTBD-006** (`docs/jtbd/developer/JTBD-006-work-backlog-afk.proposed.md`) — "the agent never closes on inference" is the outcome this serves.
- **JTBD-201** — the audit-trail outcome the locating cite serves.
- **P347**, **P346**, **P385**, **P386**, **P461** — the evaluator's sibling tickets; P385 and P386 consume the same evaluator through the pre-dispatch relevance gate and inherit this narrowing.
