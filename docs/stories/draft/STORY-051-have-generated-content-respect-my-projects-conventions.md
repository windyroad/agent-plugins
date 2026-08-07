---
status: draft
story-id: have-generated-content-respect-my-projects-conventions
reported: 2026-07-26
decision-makers: [Tom Howard]
problems: [P424]
jtbd: [JTBD-303, JTBD-101]
rfcs: [RFC-054]
story-maps: [STORY-MAP-008]
estimated-effort: M
---

# STORY-051: Have generated content respect my project's conventions

**Reported**: 2026-07-26
**Problems**: P424
**JTBD**: JTBD-303 (secondary: JTBD-101)
**RFCs**: RFC-054
**Story Maps**: STORY-MAP-008
**Estimated effort**: M

## User value (required, INVEST Valuable)

In order to keep the content policy my project enforces — so that my own hooks stop firing on
text I did not write and cannot reach — as an adopter of the plugin suite, I want the content
these plugins generate into my repository to arrive in the most portable form available, and to
keep arriving that way on every regeneration.

The title names the witnessed character, the U+2014 em-dash, because that is what five inbound
reports raised. The criteria below cover the behaviour rather than the glyph: a generated
artefact should not carry a character class a stricter project than ours forbids, whatever that
class turns out to be next.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] Every generated-output surface named in RFC-054 produces artefacts free of U+2014 when
  exercised end to end: the captured ADR skeleton, the compendium entry the on-edit hook writes,
  the compendium the backstop generator writes, the rendered verification-queue evidence cell,
  and the outbound-responses audit-log entry. Asserted by exercising the emitter and reading the
  bytes it wrote, not by grepping the template that produced them (ADR-052).
- [ ] The guarantee holds over **interpolated and agent-authored content**, not only over the
  string constants the templates own. A generated artefact whose title, chosen-option summary,
  or evidence prose came from an ADR body or an agent's own writing is covered by the same
  assertion.
- [ ] Conformance survives regeneration. Running the emitter a second time over output it
  already produced does not reintroduce the character, and the assertion above is run against
  the second pass as well as the first.
- [ ] A regression signal exists on the plugin side, so a newly introduced U+2014 on a
  generated-output surface fails a check before release rather than surfacing in an adopter's
  session. This criterion is JTBD-303's fifth desired outcome and is the one most likely to be
  dropped as "the substitution is already done" — it is what makes the fix durable rather than a
  point repair of five known sites.
- [ ] The four test and eval surfaces that assert the retired wire format move in the same
  change and pass: `review-problems-likely-verified-cell-shape.bats`,
  `review-problems-contract.bats`, `review-problems/eval/promptfooconfig.yaml` (the ADR-075
  behavioural surface, which carries the behavioural assertion), and
  `run-retro-step-4a-prior-session-evidence-drain.bats`.
- [ ] The fix reaches installed caches: a changeset covering `@windyroad/architect`,
  `@windyroad/itil` and `@windyroad/retrospective` rides the implementing change, so an adopter
  receives it on `npm install` rather than needing a local scrub (P423, JTBD-303 outcome 3).

**The criteria are deliberately neutral on how the guarantee is achieved.** Whether it comes
from substituting the template literals, from a deterministic transliteration pass at the
emission boundary, or from those plus a one-time migration of already-generated artefacts is an
open decision recorded in RFC-054 and settled in an ADR before implementation. Writing any of
those mechanisms into a criterion here would ratify the choice by accident, which is the
build-on-then-rejected failure ADR-074 exists to prevent. AC2 is worded as an outcome the
mechanism must deliver, not as the mechanism.

## Driving problem trace (required — I7 invariant)

- **P424** (Known Error) — governance tooling emits U+2014 into generated artefacts, and adopter
  projects that hard-block the em-dash via an Edit/Write hook have that hook fire on content
  shipped from the cached plugin (ADR-036), which the adopter cannot edit. Arrived as five
  inbound reports: #185, #186, #219, #223, #319. Root cause confirmed by corpus read to exact
  file and line across four emitting surfaces, plus a seventh render site in a third package
  that the original ticket did not name, and a fifth emitting surface deferred out of scope.
  The defining property is recurrence: every regeneration reintroduces the character, so a
  manual scrub is a treadmill rather than a workaround.

## JTBD trace (accepted-gate — I8 invariant)

Serves **JTBD-303** (have plugin-generated content respect my project's own conventions), with
each criterion mapped to a named desired outcome:

- Outcome 1 (generated content defaults to the most portable form) → AC1.
- Outcome 2 (conformance holds at every regeneration, not just first write) → AC3, and AC2 for
  the pass-through half that a first-write-only fix misses.
- Outcome 3 (no adopter-side remedy expected; the fix ships upstream) → AC6.
- Outcome 4 (when plugin output and an adopter policy hook conflict, the plugin side yields) →
  AC1 and AC2 together. Note the residual RFC-054 records: under ADR-078's migration-by-edit-
  cadence model an adopter's existing compendium entries are never revisited, so this outcome is
  only fully served if the migration leg is in the settled option.
- Outcome 5 (a plugin-side regression signal exists) → AC4.

The job is authored in the same commit as this story and is born
`human-oversight: unconfirmed`; its ratification and this story's are the same drain event.

**JTBD-101** (extend the suite) is the secondary anchor: packaging the fix so an adopter's next
`npm install` receives it is plugin-developer work, which is AC6.

## Implementation notes

**This story cannot be implemented while `draft`** (ADR-096), and its `accepted` transition
carries the ADR-090 ratification that has no AFK path. RFC-054's `stories:` array stays empty
until then, because ADR-090 forbids an RFC referencing an unratified story. Ratify these
acceptance criteria together with JTBD-303's five desired outcomes — the criteria encode those
outcomes, so confirming the job alone would leave the criteria unconfirmed while looking
confirmed.

**Ratify the open option first.** Per ADR-073's third Confirmation criterion the approach choice
needs its own ratified ADR before implementation, and AC2 is the criterion that choice decides:
template-literal substitution alone cannot satisfy it. Accepting this story before that ADR
exists would leave the acceptance gate open on a criterion nothing yet knows how to meet.

**AC4 is the criterion most likely to be lost.** Once the five known sites are substituted the
fix looks finished, and a regression signal is easy to defer as polish. It is not polish: the
ticket's own history has a precedent in P210, where a single em-dash on one surface was fixed in
isolation and the class it belonged to went unnamed until five more reports arrived.

## Related

- RFC-054 (the fix vehicle), STORY-MAP-008 (the map, rib "Portable generated output"), P424
  (the driving problem), JTBD-303 (the grounding job), inbound #185, #186, #219, #223, #319.
- **P210** — the narrow, already-fixed precedent: one em-dash in the work-problems AFK fallback
  marker, repaired without naming the class. The reason AC4 exists.
- **P423** — the master class: a fix that should govern adopters must land as a shipped surface,
  never as a local scrub or project-local memory. AC6 is that rule made testable.
- **ADR-078** — the compendium's migration-by-edit-cadence model, which is why AC3 (regeneration)
  does not by itself reach entries an adopter never touches.


## Story Maps

| ID | Title | Status |
|----|-------|--------|
| STORY-MAP-008 | STORY-MAP-008: Have a plugin behave like a guest in my repository | draft |
