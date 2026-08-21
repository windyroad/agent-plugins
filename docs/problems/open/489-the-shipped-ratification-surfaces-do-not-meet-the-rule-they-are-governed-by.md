# Problem 489: The shipped ratification surfaces do not meet the rule they are governed by

**Status**: Open
**Reported**: 2026-08-09
**Priority**: 12 (High) — Impact: 4 × Likelihood: 3 — derived at capture. Impact 4: a ratification marker is what four separate guards read to decide whether work may proceed; where the surface collecting it cannot ask the right question or send the artefact, the marker records something weaker than it claims. Likelihood 3: it bites whenever a ratification is collected through one of the non-compliant surfaces, which is most of them, but the harm is a weak record rather than a wrong one.
**Origin**: internal
**Effort**: L — five surfaces, two marker-writing scripts, at least one behavioural fixture and one eval, plus two open design questions that need answering before any of it is built.
**WSJF**: 3 — (12 × 1.0) / 4 (added 2026-08-21 review)
**JTBD**: JTBD-002
**Persona**: developer

## Description

ADR-111 states what a ratification is: a brief prose summary, the artefact itself sent as a file, and a structured question — the considered options where the artefact records a choice, ratify-or-say-what-is-wrong where it does not. It states the rule and deliberately stops there. This ticket is what that costs the surfaces that must now meet it.

The scope was split on maintainer direction on 2026-08-09, after the decision grew through seven review rounds from "replace one superseded amendment" into a redefinition touching five surfaces, both drains' ratified answer vocabulary, a whole artefact class and two scripts. Each round's findings were right and each fix widened it further. Splitting keeps the rule ratifiable on its own and lets each surface be weighed separately rather than riding one document's approval.

### What does not comply, and how

- **Both oversight drains** — the decisions drain and the jobs-and-personas drain — present *Confirm / Amend / Reject / Defer*. That is neither shape ADR-111 defines. It is also the vocabulary their own parent decisions fixed in ratified text, so changing it is not simply an implementation edit.
- **The jobs-and-personas authoring surface** asks *are these the right personas?* in prose: no briefing discipline, no attachment, no structured answer.
- **The decisions authoring flow** carries the briefing and the option-shaped question in full — it is the one path where the rule was ever delivered — but it has never attached the artefact, so it gains a step too.
- **The story-map surface** already briefs the substance before any identifier and already asks exactly two answers, ratify or a free-text change request that is applied and re-presented. It is the working precedent for the shape. It sends the map's path rather than the map, so it gains the file only.
- **The marker writers.** ADR-111 requires the note on a ratified artefact to record what was offered and what was picked. No writer authors a note. Two have no note handling at all; the story-map writer preserves one if already present but never writes it. Every note in the corpus today was hand-written into frontmatter.

### The two open design questions

Neither is settled, and both block parts of the work rather than merely informing it.

- **Where do amend, reject and defer live alongside an option list?** Per-option selection offers neither rejection nor deferral, and the drains work in batches, so a sitting has to be leaveable partway. Amendment is the awkward one: it is substantive, it is the highest-volume drain answer, and it is not one of the considered options.
- **What does "sent as a file" mean?** An attachment and the artefact's bytes inlined in the turn have sharply different costs. A story map is HTML; inlined as text it is unreadable, which is exactly why the current surface sends a path.

### Why the record is weaker than it looks meanwhile

Where a surface cannot ask the compliant question, the marker it writes still reads as a full ratification to everything downstream. The build-upon guards, the drains' own detectors and the session-start nudges cannot tell a marker earned through an option-shaped question from one earned through a prose yes. That is the gap ADR-111 names and this ticket closes.

## Symptoms

- A ratification collected without the artefact being sent, so the person agreed to a description of it.
- A drain offering answers that are neither the artefact's options nor ratify-or-object.
- A ratified artefact whose note does not say what was offered, leaving no way to tell substance-agreement from draft-agreement afterwards.
- A persona confirmed by a prose yes.

## Workaround

Collect ratifications by hand in the compliant shape — summary, file, structured question — and hand-write the note into frontmatter. This is what the P483 sweep is doing, and it is why the gap is visible.

## Impact Assessment

- **Who is affected**: whoever ratifies, and every guard that later reads the marker as evidence they did.
- **Frequency**: every ratification collected through a non-compliant surface, which today is most of them.
- **Severity**: the record is weaker than it claims. Nothing produced is wrong; what is wrong is the confidence attached to it.
- **Analytics**: none.

## Root Cause Analysis

Suspected: the rule was written in May as an amendment inside an already-ratified decision, was implemented on the one surface the ticket that drove it happened to touch, and nothing checked the others. Three months passed before anyone noticed, and it was noticed by the maintainer being asked in the wrong shape rather than by any detector.

### Investigation Tasks

- [ ] Answer the amend/reject/defer question first. It shapes both drains and is the reason the drain work cannot start.
- [ ] Answer what "sent as a file" means, in a way that works for an HTML story map as well as a markdown decision.
- [ ] Decide how the drains' parent decisions are amended. Both fixed their answer vocabulary in ratified text, so this needs a superseding decision, not an edit.
- [ ] Bring the jobs-and-personas authoring surface to the summary + file + two-answer shape.
- [ ] Add the file to the decisions authoring flow, and rewrite the fixture that pins the requirement ADR-111 replaced along with the SKILL prose it pins. Leave the eval's option-label rubric intact — that duty survives.
- [ ] Add the file to the story-map surface, keeping its existing briefing and two-answer question.
- [ ] Give the marker writers a note field. On the story-map writer the field already sits outside the fingerprint basis, so writing one cannot silently un-ratify a map — worth preserving in whatever lands.
- [ ] Decide whether anything structural enforces the shape, or whether the note stays the only after-the-fact check. ADR-111 names this as unsettled and it is the reason the same rule went undelivered for three months.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- **ADR-111** — states the rule this ticket implements. It deliberately does not settle the cost, which is what this ticket carries.
- **ADR-064** and **ADR-066** — the two decisions whose amendments stated the rule before ADR-111, both superseded in part by it.
- **ADR-110** — refuses a marker write without evidence a confirmation happened. It composes with ADR-111: that one makes the write impossible without evidence, this one says what makes the evidence real.
- **P483** — amendment sections are not a legitimate way to change a ratified decision. ADR-111 is the fourth document of that sweep, and this ticket is its overflow.
- **P484** — the reading-context constraint that the summary and the file exist to answer. Its first two tasks were closed to unblock ADR-111.
- **P375** — a deferral that names a re-entry point is not a cadence. This ticket exists so ADR-111's reassessment has something real to check.

(captured via /wr-itil:capture-problem during the ADR-111 review, on the architecture reviewer's finding that the decision asserted a ticket which did not exist.)
