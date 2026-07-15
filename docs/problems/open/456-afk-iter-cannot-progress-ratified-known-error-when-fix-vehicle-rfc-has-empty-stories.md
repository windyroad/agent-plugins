# Problem 456: AFK iter cannot progress a ratified Known Error when the fix-vehicle RFC has empty stories

**Status**: Open
**Reported**: 2026-07-15
**Priority**: 6 (Medium) — Impact: 2 (Minor — iter degrades to capture-and-hold; work preserved but implementation throughput lost) × Likelihood: 3 (Possible — fires on every AFK iter whose selected ticket's fix vehicle carries `stories: []`; 7 under-scoped skeleton RFCs + legacy empty-stories RFCs currently on disk) — derived at capture from the description per Step 4a
**Origin**: internal
**Effort**: M — design decision + bounded SKILL edits (work-problems selection classifier and/or drain-skill pre-ratification path) — cf. P409 (M)
**JTBD**: JTBD-006
**Persona**: developer

## Description

AFK work-problems iteration cannot progress a substance-ratified Known Error whose fix-vehicle RFC carries stories: [] — the ADR-089 story back-fill requires ADR-090 ratification and the ADR-096 accepted gate, both interactive-only, so the iter degrades to capture-story-infrastructure-and-hold. Witnessed 2026-07-15 P376 Gap 2 iteration: direction ratified 2026-07-04, ADR-074 gate satisfied, yet the SKILL rework could not land; the iter spent its budget on STORY-MAP-004 + STORY-045 captures plus three architect reviews and queued the implementation for the next interactive drain. Every future AFK iter selecting a ticket whose vehicle has empty stories hits the same wall. Candidate fix directions: work-problems Step 3 selection could down-rank or classify-skip tickets whose fix vehicle needs story ratification; or the interactive drain could pre-ratify story scaffolds; or ADR-090/096 could gain a bounded AFK carve-out for stories that decompose already-ratified substance (framework-mediated per ADR-060 I13).

## Symptoms

- 2026-07-15 P376 Gap 2 iter: three architect reviews (ISSUES FOUND ×2 → PASS on the held plan), STORY-MAP-004 + STORY-045 captured born-unconfirmed, implementation queued to `outstanding_questions`; the targeted SKILL rework did not land despite the ADR-074 substance gate being satisfied.

## Workaround

The iter captures the story infrastructure (map + story, born `human-oversight: unconfirmed` per ADR-090), queues ratify → accept → wire → implement for the next interactive drain, and reports partial-progress. Work is preserved, not lost — but the fix always costs one extra interactive round-trip.

## Impact Assessment

- **Who is affected**: the developer running `/wr-itil:work-problems` AFK loops (JTBD-006)
- **Frequency**: every AFK iter whose selected ticket's fix vehicle RFC carries `stories: []` (7 under-scoped skeleton RFCs on disk as of 2026-07-15, plus legacy empty-stories RFCs per P409)
- **Severity**: Medium — throughput loss + queued-decision accumulation, no data loss
- **Analytics**: `wr-retrospective-check-autocreate-rfc-scope` TOTAL line (proposed_skeletons=8 under_scoped=7 on 2026-07-15)

## Root Cause Analysis

ADR-089 (every RFC has ≥1 story) + ADR-095 (story-map membership at capture) + ADR-090 (RFC may reference only ratified stories) + ADR-096 (no implement while draft; accepted gate is where ratification fires) compose into an interactive-only path from "ratified fix direction" to "implementable story". None carries an AFK carve-out, so the ADR-060 I13 framework-mediated story decomposition of already-ratified substance still cannot reach `accepted` inside an AFK iter.

### Investigation Tasks

- [ ] Investigate root cause
- [ ] Create reproduction test
- [ ] Decide the fix direction (selection-time classifier vs drain-time pre-ratification vs bounded ADR-090/096 AFK carve-out) — category-1 direction-setting, needs the user

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P409 (back-fill legacy RFCs still carrying empty `stories: []` — shrinks the trigger population), P399 (ADR-073 auto-create emits skeleton RFCs — grows the trigger population), P376 (the witnessing iteration)

## Related

(captured via /wr-itil:capture-problem during the 2026-07-15 P376 AFK iteration retro; expand at next investigation)

- Hang-off pre-filter short-circuited at capture: 130 candidate tickets shared ≥1 signal (ADR-060/074/089/090/096 citations are ubiquitous) — over the 5-candidate cap, so the `wr-itil:hang-off-check` dispatch was skipped per the capture-problem Step 2b cap rule. Strongest absorb candidates for review-time re-evaluation: P409 (back-fill legacy empty-stories RFCs — adjacent data-hygiene concern, but this ticket is about the AFK capability boundary, not the legacy corpus), P399 (skeleton-RFC authoring).
- STORY-MAP-004 / STORY-045 (`docs/story-maps/draft/`, `docs/stories/draft/`) — the capture-and-hold artefacts from the witnessing iteration.
