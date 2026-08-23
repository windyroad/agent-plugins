# Problem 516: `story-map-edit add-card` omits the `ref` back-link, so a card renders with no Traces line

**Status**: Open
**Reported**: 2026-08-21
**Priority**: 8 (Medium) — Impact: 2 × Likelihood: 4 — derived at capture from the description per Step 4a. Impact 2: internal tooling, no shipped-package harm; the card still anchors to its story file and the row header still links the driving problem, so independent trace paths survive. Likelihood 4: `--ref` is optional in the CLI but universal in practice, so any invocation that omits it silently produces the degraded card.
**Origin**: internal
**Effort**: S — derived at capture. One script: either default the field or warn when it is absent.
**WSJF**: 8 — (8 × 1.0) / 1 (added 2026-08-24 review — line was absent at capture)
**JTBD**: JTBD-008
**Persona**: developer

## Description

`wr-itil-story-map-edit add-card` accepts `--ref R` as an optional flag. When it is omitted the card is written into the ADR-102 data island with no `ref` key, and `render-story-map` consequently omits that card's `<div class="t-ref">Traces: …</div>` line. Nothing warns, at either the edit or the render step.

The field is optional in the CLI and universal in the corpus. On STORY-MAP-011 all eight pre-existing cards carried a `ref` (`"STORY-059, P487"`, `"STORY-050, P439"`, and so on); a ninth card added on 2026-08-21 without the flag was the only card on the map with no Traces line. A field that every real instance carries is de-facto mandatory, and treating it as optional means the degraded state is what you get by default rather than what you opt into.

The detection path is the concerning part: the omission was caught by the `wr-risk-scorer:pipeline` commit-gate agent reading the diff, not by the tooling that wrote it. A risk scorer noticing a missing trace line is luck, not a control — it happened to be looking, and on a different iteration it would not have been.

## Symptoms

- `wr-itil-story-map-edit <map> --json -` with an `add-card` op and no `ref` key exits 0 and reports `story-map-edit: added STORY-NNN at <activity> × <release>` with no advisory.
- The rendered card carries a title anchor but no `Traces:` line, so the card alone does not name its story file or driving problem.
- Observed 2026-08-21 on `docs/story-maps/draft/STORY-MAP-011-trust-the-afk-loops-autonomous-conduct.html` while drawing release row RFC-070 for P463; the ninth card was the only one of nine missing the line.

## Workaround

Pass `--ref "STORY-<NNN>, P<NNN>"` on every `add-card` invocation. To repair a card already written without it, `remove-card` then `add-card` with the flag — verified to work and to leave the map's oversight fingerprint intact (cards sit outside the ADR-103 substance basis, so the repair does not re-open ratification).

## Impact Assessment

- **Who is affected**: the developer reading a story map to find what a card traces back to; any later reviewer auditing map-to-ticket coverage.
- **Frequency**: every `add-card` invocation that omits the optional flag.
- **Severity**: Medium (8) — degrades the audit trail on the approval surface; independent trace paths (row header, story frontmatter, story body) survive, so no trace is irrecoverable.
- **Analytics**: 1 of 9 cards on STORY-MAP-011 affected as of 2026-08-21, introduced the same day and repaired the same day.

## Root Cause Analysis

### Investigation Tasks

- [ ] Confirm whether `ref` should be derivable rather than passed — the story id and its `problems:` frontmatter are both readable from the story file the card names, so the renderer may be able to derive the Traces line without a stored field at all. ADR-104 already derives status, value and problems at render time from the story files; `ref` looks like it belongs in that same derived set rather than in the island.
- [ ] If it stays an authored field, decide between defaulting it and warning on absence, and apply whichever to `add-card`.
- [ ] Audit the rest of the story-map corpus for other cards missing `ref`.
- [ ] Behavioural coverage: an `add-card` with no ref either renders a Traces line anyway (derived) or emits an advisory (authored).

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P496 (story-map corpus carries three incompatible encodings), P481 (two ratified decisions describe a story-map format that no longer exists) — both touch the same island schema surface, neither carries this root cause.

## Related

- Captured via `/wr-itil:capture-problem` during a `/wr-itil:work-problems` iteration on P463 (relevance-close evaluator over-fires), after the commit-gate risk scorer flagged the missing back-link.
- Hang-off pre-filter returned more than five candidates sharing the `docs/story-maps/` signal, so the `wr-itil:hang-off-check` subagent dispatch was skipped per the capture-problem sub-step 2b candidate-cap short-circuit. Candidates surfaced for review-time re-evaluation: P509, P496, P481, P473, P457, P443, P412. None carries this root cause on a read of their descriptions — P473/P509 are about map *content* being a work breakdown rather than a journey, P496/P481 about *encoding* drift across the corpus, P457 about ratify-before-author ordering, P443 about a broken lineage, P412 about adopter invisibility. This is a field-level defect in the card writer.
- ADR-104 — status, value and problems are derived from story files at render time and are not settable via `story-map-edit`; the first investigation task asks whether `ref` belongs in that same derived set.
