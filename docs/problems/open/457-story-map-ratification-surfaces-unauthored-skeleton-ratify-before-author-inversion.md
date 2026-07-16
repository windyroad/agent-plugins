# Problem 457: Story-map ratification surfaces an unauthored skeleton — the lifecycle asks for oversight before the authoring stage runs

**Status**: Open
**Reported**: 2026-07-16
**Priority**: 12 (High) — Impact: 3 (Moderate — the ADR-090 oversight surface presents an artefact with literally nothing to approve; a ratification given on an empty shell is the P348 hollow-marker class at the story-map surface, and the user-visible absurdity damages trust in the whole ratification pipeline — witnessed "WTF is this story map you are asking me to approve", 2026-07-16) × Likelihood: 4 (Likely — every AFK-captured story map hits it: capture-story-map deliberately emits a skeleton (purpose + backbone deferred to the manage-story-map accepted transition), and the ratification queue then surfaces that skeleton for human oversight BEFORE the accepted transition can author it) — derived at capture per Step 4a
**Origin**: internal (user correction 2026-07-16)
**Effort**: M — lifecycle reorder across capture-story-map / manage-story-map / the ratification surfaces: either author purpose + backbone at capture when the substance is derivable (the P399 principle applied to maps — the 2026-07-16 hand-population of STORY-MAP-004 from STORY-045's substance took minutes and is the proof), or gate ratification requests on the authoring stage having run
**JTBD**: JTBD-001
**Persona**: developer

## Description

`/wr-itil:capture-story-map` creates skeleton HTML by design — the purpose paragraph and backbone carry literal "populate at /wr-itil:manage-story-map accepted transition" placeholders. ADR-090 requires human ratification of story maps, and the ratification drain/queue surfaces maps that are `human-oversight: unconfirmed`. Composed, the lifecycle asks the human to ratify an artefact whose authoring stage has not run: ratify → accept → THEN author. Witnessed 2026-07-16: STORY-MAP-004 was surfaced for ratification (files sent for review) and the user opened an empty shell — title, placeholder purpose, placeholder backbone.

The substance the human should be ratifying (user value, acceptance criteria, traces) existed the whole time in the sibling story file (STORY-045, fully authored at capture per the capture-story contract). The map is the only artefact type whose capture contract defers ALL substance while its oversight contract fires immediately.

## Symptoms

- Ratification queue entries / review drains present story maps containing only placeholder text.
- Ratifying at that point is a hollow marker (P348 class); refusing to ratify wedges the AFK loop's story-gated work (P456) on an artefact nobody can meaningfully review.

## Workaround

Populate the map by hand from the sibling story's substance before re-presenting for ratification (done for STORY-MAP-004, 2026-07-16).

## Impact Assessment

- **Who is affected**: developer persona — every maintainer running the ADR-090 ratification drains against AFK-captured maps.
- **Frequency**: every AFK-captured story map (P456 direction (a) makes these routine).
- **Severity**: Moderate — oversight-integrity defect; the marker means nothing when written on a skeleton.
- **Analytics**: STORY-MAP-004 witness, 2026-07-16.

## Root Cause Analysis

### Investigation Tasks

- [ ] Decide the fix shape: (i) author purpose + backbone at capture when derivable from the traced story/problem (P399 principle — capture-story-map gains the same full-authoring contract capture-rfc --fix-time gained), vs (ii) ratification surfaces refuse/defer maps whose backbone is placeholder (authoring-stage predicate before queueing), vs both.
- [ ] Sweep existing draft maps for other placeholder-backbone shells surfaced or queued for ratification.
- [ ] Create reproduction test (behavioural: capture → ratification-queue path must not present placeholder content).

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P399 (skeleton-at-capture class — the RFC sibling, corrected to full authoring per ADR-073; this is the story-map instance), P348 (hollow oversight markers), P340 (substance-confirmation needs briefed substance), P404 (lineage gates only fire at accepted transitions), P444 (unsurfaced substance at oversight grain), P456 (the AFK story-gate direction that makes skeleton maps routine)

## Related

- User correction 2026-07-16 ("WTF is this story map you are asking me to approve") — P078 capture-on-correction; the orchestrator had sent STORY-MAP-004 (skeleton) for ratification review alongside the fully-authored STORY-045.
- STORY-MAP-004 populated by hand 2026-07-16 as the immediate remediation; accessibility review noted two template-inherited minors (slice-card border contrast 1.6:1 vs 3:1 needed; missing viewport meta + main landmark) for a future template pass on docs/story-maps/.
