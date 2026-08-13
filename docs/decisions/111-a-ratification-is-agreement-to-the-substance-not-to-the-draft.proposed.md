---
status: proposed
date: 2026-08-09
decision-makers: Tom Howard
human-oversight: confirmed
oversight-date: 2026-08-09
oversight-note: "2026-08-09 — confirmed in this decision's own shape, which is the first time it has been used. Offered: (1) the three-part ratification — summary, file, structured question; (2) binding the marker to a briefed prose exchange; (3) leaving any affirmative to ratify. Picked: option 1, matching what the document says. The summary preceded the file, the file preceded the question, and the question presented all three considered options as selectable answers. Three things were surfaced before the ask rather than left to be read out of the document: that nothing enforces this rule, that the identical rule was prose in May and went undelivered for three months, and that a description's discarded alternatives stay hidden under the two-answer shape. Scope was also put to the maintainer separately and narrowed on their direction — this document states the rule, and what it costs the five shipped surfaces is P489."
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: []
supersedes: [ADR-064 (in part — the 2026-05-31 (P339 + P340) substance-confirm amendment, only as it governs the ratification fire), ADR-066 (in part — the 2026-05-31 born-confirmed amendment only)]
jtbd: [JTBD-002, JTBD-006, JTBD-008]
persona: developer
secondary-persona: tech-lead
reassessment-date: 2026-11-09
---

# ADR-111: A ratification is agreement to the substance, not to the draft

## Context and Problem Statement

An artefact is ratified when a person agrees to it. The question is what they have to have agreed *to*.

On 2026-05-30 a decision shipped marked as ratified on the strength of a question asking whether the problem statement and the outcome captured the situation. The answer was yes. It meant *this reads correctly* — and the document recorded it as *I choose this option*. The option the document had been written against was not the one wanted. The maintainer found it the next day: **"the previous iteration of the decision, with the programmatic extraction, was not approved. How did that ADR skip ratification?"**

Nothing malfunctioned. The question was asked and answered honestly at both ends. It was a question about the *draft* being read as agreement to the *substance*.

The rule written in response — the marker writes only in response to a question presenting the options, with one picked — was delivered on one path and nowhere else. The decisions authoring flow carries it in full. Every other route kept its own shape, and none of them was the one specified. Three months on, on 2026-08-09, the maintainer: **"I've never been given that, but it's what I specified."** True of every path they have actually been asked through.

It was also recorded as an amendment inside a document ratified six days earlier, and that amendment recorded itself as ratified on the grounds that it tightened a mechanism rather than changing a decision — so the rule governing ratification was itself never ratified. The fuller statement of it on ADR-064 has the same shape and the same problem.

This decision states the rule. What it costs the surfaces that must now meet it is deliberately not settled here.

## Decision Drivers

- A yes/no question cannot tell substance-agreement from draft-agreement, because both are yes.
- Being shown the alternatives is what makes a choice a choice, where there are alternatives to show.
- A ratification must be answerable in one action, with a way to say *no, and here is what is wrong*.
- Everything downstream treats the marker as *the substance was agreed*.
- The `developer` persona's reading-context constraint — that this person reads governance artefacts away from the repository with no filesystem access, so an artefact must be readable from its own bytes and a claim on it cannot be checked against the corpus at read time.
- A rule delivered on one path out of several is a rule for that path. The gap is the routes it never reached.

## Considered Options

1. A three-part ratification — a brief prose summary, the artefact as a file, then a structured question: the considered options where the artefact records a choice, ratify-or-say-what-is-wrong where it does not.
2. Bind the marker to a briefed prose exchange: a plain-language brief naming the chosen option, the rejected alternatives and the cost, followed by an affirmative. Rejected: a yes/no answer wearing a briefing, which is the shape that failed in May, and it replaces a checkable rule with a judgement about whether a brief was good enough.
3. Leave it. Rejected: it leaves every route but one on the shape that failed.

## Decision Outcome

**Option 1.** A ratification is collected in three parts, in this order:

1. **The summary.** Short, plain language, no identifier used as the carrier of meaning. What it is, what it changes, and what it costs if it is wrong.
2. **The file.** The artefact itself, sent as a file. The reader has no repository access at the moment they are being asked; a path is not a substitute for the thing.
3. **The question.** Always structured, never prose. Where the artefact records a choice, its substantive answers are each considered option, presented as selectable — yes/no shape is forbidden at that fire. Where it records no choice, its substantive answers are two: ratify, or say what is wrong in your own words, treated as a change request, applied, and re-presented.

The enumeration governs the **substantive** answers. An answer that neither agrees nor objects — skip this sitting — may sit alongside them.

Where a shipped surface's stated question shape differs from this rule, this decision governs and that surface is non-compliant until it is brought into line. ADR-066's drain clause fixes an answer vocabulary this rule does not use, and it survives this supersession untouched; where the two differ, this decision governs. The surfaces are known non-compliant, not unconstrained.

**Every ratification records what happened.** The note on the ratified artefact states what was offered and what was picked, in enough detail to tell substance-agreement from draft-agreement afterwards.

**This binds every artefact carrying a ratification marker**, whatever kind it is. Where the artefact records a choice the question offers it; where it does not, the two answers. Stories are outside this not by exclusion but by construction: ADR-103 left them carrying no marker at all, so there is no ratification event to shape.

**On ADR-064's five requirements**, as they govern the ratification fire, one for one. Four survive in substance: the briefing in plain prose before the question, and no identifier used as an explainer, are both part one; option-shaped rather than yes/no is part three where the artefact records a choice; and substance-only at that fire is the rule that a yes to draft quality is not a ratification. The fifth is replaced — ADR-064 required that the person be able to decide without looking anything up, and met it with a self-contained prose surface. That is unachievable for a reader who cannot open the repository at all: prose can describe an artefact but cannot be one. Part two, the file, is what that requirement was reaching for and could not express. The duty on the option labels themselves is unchanged — a label that defers its meaning to a document the person must open still fails, and the file is additive to that, not a substitute.

ADR-064's amendment also binds the Needs-Direction translation ask, where the architect surfaces a decision question before any document exists. That fire is untouched and keeps self-containment, because there is no artefact to send and no marker written.

The marker writes only in response to the question, and where the artefact records a choice, only when the option picked matches what the artefact says. Where a different option is picked, the artefact is rewritten and the question re-put — the mismatch handling ADR-066's amendment specified, carried forward unchanged.

**ADR-068 is not superseded.** Its item 5 requires born-confirmation for jobs and personas without saying what the confirming event has to look like. This decision supplies that shape; item 5 stays in force as written.

**Unattended work** is governed by ADR-110 and unchanged here.

**This decision is not retrospective.** Ratifications already collected stand as given.

## Consequences

### Good

- The person is choosing rather than assenting wherever there is something to choose, and always answering something structured rather than prose.
- Every ratification arrives with the thing being ratified.
- Rejection stops being a special case: the second answer is how to say no and why, on artefacts that previously offered only agreement.
- The rule is checkable by inspection: did the question offer the artefact's options where it has them, and two answers where it does not.

### Neutral

- Slightly more to assemble per ratification. An artefact that records a choice already carries its options, so the question is built from what is written rather than invented.
- One surface already works this way — the story-map ratification briefs the substance before any identifier and then asks exactly two answers. It is the precedent this generalises, and evidence the shape is buildable.
- On the story-map writer the note field already sits outside the ratification fingerprint, so recording one cannot silently un-ratify a map. Whatever lands should keep that property.

### Bad

- **What this costs the shipped surfaces is not settled here.** Several must change and the work is not small: both drains offer a vocabulary this decision does not use, the jobs-and-personas confirm is a prose ask, two authoring surfaces send no file, and no marker writer authors the note this decision requires — two have no note handling at all, and the third preserves one if already present but never writes it, so every note in the corpus today was written by hand. That is captured as **P489**, rather than resolved by ratifying this document, so agreeing to this rule is agreeing to the rule and not to a plan for meeting it.
- **A description's alternatives stay unsurfaced.** A persona encodes discarded alternatives that the two-answer question does not show. It offers a way to object, not a way to see what was rejected.
- **Nothing enforces this.** The identical rule was written in May, enforced on one path, and nobody noticed for three months that the others were uncovered — and this document is also prose. A structural check is the obvious follow-on and is not settled here either.

## Confirmation

- A ratification is preceded by the summary and the file, and collected through a structured question.
- Where the artefact records a choice, the question's substantive answers are its considered options; a yes/no question does not produce the marker, however well briefed.
- Where it records no choice, the substantive answers are ratify and say-what-is-wrong; a prose ask does not produce the marker.
- Where the answer selects an option the artefact was not written against, no marker is written until the artefact says what was selected.
- The note on a ratified artefact records what was offered and what was picked.
- The Needs-Direction translation ask is unchanged and keeps self-containment.

## Related

- **ADR-064** — superseded in part, as it governs the ratification fire: four of its five requirements carried into the three parts, one replaced by the file. Its Needs-Direction clause stands.
- **ADR-066** — superseded in part: the 2026-05-31 born-confirmed amendment, whose mismatch handling carries forward unchanged. Its drain clause is untouched and this decision governs where they differ.
- **ADR-068** — its born-confirmed clause for jobs and personas gets its missing shape from this decision; item 5 itself is unchanged.
- **ADR-110** — refuses the marker write without evidence that a confirmation happened. This says what event produces that evidence.
- **ADR-109** — the jobs reviewer refuses work built on a job or persona nobody has ratified. The jobs-surface guard that reads this marker.
- **ADR-074** — confirm a decision's substance before building dependent work. The decisions-surface guard, and the clause that makes this marker load-bearing for an ADR.
- **ADR-090** — created the story-map marker without giving its ratifying event a shape.
- **ADR-103** — left stories carrying no marker, which is why they have no ratification event to shape.
- **`developer` persona** — the reading-context constraint the summary and the file rest on, ratified 2026-08-09.
- **P489** — what this rule costs the shipped surfaces: both drains, the jobs-and-personas confirm, the file on two authoring surfaces, the note on the marker writers, and the two design questions that block them.
- **P340** and **P339** — the tickets behind the rule; their instance is the 2026-05-30 decision ratified on a draft-quality yes.
- **P350** — brief the substance in plain language before naming anything by identifier.
- **P085** — asking in prose where a structured question is needed. This is that failure on the ratification surface.
- **P484** — the reading-context constraint being undocumented; its first two tasks closed to unblock this.
- **P483** — amendment sections are not a legitimate way to change a ratified decision. Fourth document of that sweep.

## Reassessment Criteria

Revisit if a ratification arrives with the summary or the file missing. `reassessment-date: 2026-11-09` is the self-firing trigger; the thing to check then is whether **P489** was ever worked, since a rule nothing implements is what this decision exists to correct.
