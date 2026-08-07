# Problem 478: I10 checks that a story's `## User value` section is non-empty, but never that it is value-first

**Status**: Open
**Reported**: 2026-08-07
**Priority**: 9 (Medium) — Impact: 3 × Likelihood: 3 — derived at capture from the description per Step 4a. Impact 3: a malformed value statement is not a broken build, but it defeats the story tier's whole point — the value is what a human ratifies, and 24% of the corpus was stating a feature instead. Likelihood 3: it has already happened 12 times across 50 stories and nothing prevents the 13th. Effort informed by P465 (M — SKILL prose + a check at one locus + behavioural bats), which is the same shape of change at the same gate.
**Origin**: internal
**Effort**: M — one predicate, wired into the existing I10 check, plus behavioural bats for both the accept and reject directions — cf. P465 (M)
**JTBD**: JTBD-008
**Persona**: developer

## Description

The `draft → accepted` gate runs I10, the INVEST shape check, in `packages/itil/skills/manage-story/SKILL.md`. I10 asserts that `## User value` is **non-empty**. It never asserts anything about its **form**.

The project convention is value-first: *"In order to `<value>`, as a `<persona>`, I want `<capability>`."* The value leads, because the value is the thing a human is being asked to approve. The alternative shape — *"As a `<persona>`, I want `<capability>`, so that `<value>`"* — states a feature and appends a justification, which is the shape the maintainer has corrected before (2026-07-02).

Nothing enforces it, and the corpus drifted: **12 of 50 stories** were persona-first with a trailing "so that". Seven were already `done`.

The drift surfaced only by accident. Under ADR-102/ADR-103 a story map renders card values by parsing the three clauses and giving each its own line — a paragraph at card width is unreadable, and the shape that makes it scannable is the shape it was written in. A statement that does not parse falls through to a single-block fallback and renders as a wall of text. So the detection path is: a human opens a map, sees an unreadable card, and asks why. That is not a control.

### The second finding, and why it constrains the fix

The same investigation found the renderer's own parser was **too strict**, and this matters more than it sounds.

The first pattern required a comma before `as a`. Many correctly-written statements close their value clause with an em-dash instead, because the clause carries a parenthetical:

> In order to deliver the value of each story in turn — every one an INVEST-valuable increment that moves the problem toward fixed — as a developer implementing a decomposed fix, I want to work the RFC's stories one at a time.

That is well-formed. The parser rejected it. Across the corpus the strict pattern rejected **15 correctly-written statements**, which read as a story defect when it was a parser defect — the wall-of-text symptom is identical either way.

Loosening it to accept `In order that` as well as `In order to`, `as the` as well as `as a`, and a dash or a comma as either clause boundary took the parse rate from 17/50 to 38/50 without touching a single story. Only then were the 12 genuine offenders visible.

**The constraint this places on any I10 check**: be strict about the clause SHAPE — value, then who, then want, in that order — and permissive about the punctuation between them. A check that encodes one punctuation style will reject valid stories, and rejecting valid work at a hard gate is worse than the drift it is trying to prevent.

Whether the leniency belongs in the I10 predicate, in the renderer, or in one shared definition both consume, is an open question for investigation — a second copy of the parse rule is the duplication class this area has already removed five times.

## Symptoms

- A story authored persona-first passes `manage-story <NNN> accepted` with no warning.
- Its card on a story map renders as an unreadable paragraph rather than three lines.
- No detector, lint or test reports it. The only signal is a human reading a map and asking what is wrong with that card.
- Symmetrically, before 2026-08-07, a correctly-written statement whose value clause closed on an em-dash produced the identical symptom, so the symptom did not distinguish a bad story from a bad parser.

## Workaround

Read the value statement when reviewing a story map for ratification. A card rendering as one block rather than three lines is either a malformed statement or a parser gap; check the story file to tell which.

## Impact Assessment

- **Who is affected**: the developer capturing stories, and whoever ratifies the map they land on.
- **Frequency**: 12 of 50 stories in the corpus (24%). No mechanism prevents recurrence.
- **Severity**: a story whose value statement is really a feature description defeats the purpose of ratifying values rather than features. Not a build break; a governance one.
- **Analytics**: none.

## Root Cause Analysis

Confirmed root cause of the enforcement gap: I10's INVEST check has a non-emptiness assertion where it needs a shape assertion. INVEST's "Valuable" axis is being read as "a value section exists", not "the section states a value".

The detection-path gap is a consequence: with no check at the gate, the only place the shape becomes visible is the map renderer, and only to a human looking at it.

### Investigation Tasks

- [ ] Decide where the parse rule lives: in the I10 predicate, in the ADR-102 renderer, or in one shared definition both consume. A second copy is the duplication class this area has removed five times (card status, card titles, RFC story lists, row status, card values).
- [ ] Write the predicate strict about clause order and permissive about punctuation. Prove it against the whole 50-story corpus: 50 accept, and a persona-first fixture rejects.
- [ ] Wire it into I10 at the `draft → accepted` gate.
- [ ] Behavioural bats for BOTH directions — a persona-first story is rejected, and each punctuation variant already in the corpus is accepted. The accept direction is the one that matters: a check that rejects valid stories at a hard gate is worse than the drift.
- [ ] Decide whether `done` stories are in scope. Seven of the twelve were already delivered; they were rewritten on 2026-08-07, but a gate at `accepted` cannot reach a story that is already past it.
- [ ] Consider whether `capture-story` should offer the shape as a template at authoring time, so the gate is a backstop rather than the first feedback.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P465 (same gate, different invariant — that one is the missing ratification check, this one is the under-specified INVEST check).

## Related

- **P465** (`docs/problems/open/465-story-accepted-gate-does-not-enforce-adr-090-ratification.md`) — same fix file (`manage-story` accepted gate) but a distinct invariant: P465 is a check that is *absent*, this is a check that is *under-specified*. The hang-off arbiter returned PROCEED_NEW, noting P465's Investigation Tasks are already complete and awaiting release, so absorbing here would reopen a committed fix.
- **P466** (`docs/problems/open/466-story-map-html-template-ships-sub-3-1-borders-no-focus-ring-no-viewport.md`) — shares the story-map rendering surface, but is presentational CSS and WCAG conformance. The unreadable card here is a detection symptom, not a rendering defect.
- **P477** (`docs/problems/open/477-story-map-corpus-carries-three-incompatible-encodings-needing-migration.md`) — shares ADR-102 but is retrospective map-encoding migration; this is prospective enforcement on story files.
- **ADR-102** / **ADR-103** — the map rendering that made the drift visible.
- Discovered 2026-08-07 while the maintainer reviewed STORY-MAP-002 for ratification and asked why one card was unreadable.

(captured via /wr-itil:capture-problem; expand at next investigation)
