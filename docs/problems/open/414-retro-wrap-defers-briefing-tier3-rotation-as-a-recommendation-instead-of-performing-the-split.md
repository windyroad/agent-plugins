# Problem 414: retro/wrap defers over-threshold briefing Tier-3 rotation as a "run interactive run-retro" recommendation instead of performing the split

**Status**: Open
**Reported**: 2026-07-03
**Priority**: 8 (Medium) — Impact: 2 (Minor — briefing rotation stalls; user carries a mechanical task) × Likelihood: 4 (Likely — default behaviour on every over-threshold retro wrap) — re-rated 2026-07-15 /wr-itil:review-problems
**Origin**: internal
**Effort**: S — run-retro SKILL contract change: perform the split instead of recommending it
**WSJF**: 8.0 — (8 × 1.0) / 1
**JTBD**: JTBD-006
**Persona**: developer

## Description

A retro/wrap summary ended with (verbatim from the user's screenshot):

> Briefing tree is over the 5120-byte Tier-3 budget on 7 topic files (none at
> the 2× hard-split mark). Recommend a dedicated interactive
> /wr-retrospective:run-retro to run the split-by-date rotation — I deferred it
> here rather than hand-rolling a risky 7-file automated split during a wrap.

The wrap detected 7 briefing topic files over the 5120-byte Tier-3 budget and
**deferred the rotation** as a recommendation ("run an interactive run-retro"),
explicitly declining to perform the split-by-date rotation itself. The
split-by-date rotation is a **mechanical, safe-default operation** (session
memory `feedback_tier3_rotation_prefer_split` — split-by-date is the SKILL safe
default; it archives a sibling and preserves detail, losing nothing). It should
**just happen** when a file crosses threshold, not be handed back to the user.

**User correction (verbatim, 2026-07-03):** *"Just fucking rotate it if it's
over the 5K thresholds FFS."* (Second instance of this feedback — see the earlier
2026-07-03 "split. lazy question" correction on the afk-subprocess briefing
rotation.)

## Symptoms

- 7 (currently 9, incl. archives) briefing topic files over 5120 bytes left un-rotated after a wrap.
- Wrap emits "recommend running interactive run-retro to rotate" instead of rotating.

## Workaround

Manually run `/wr-retrospective:run-retro` (or hand-roll the split). This is the
friction the ticket objects to.

## Impact Assessment

- **Who is affected**: maintainer — briefing tree exceeds its context budget, degrading the SessionStart briefing surface (ADR-040 Tier-3 envelope).
- **Frequency**: every wrap where briefing files have grown past threshold.
- **Severity**: (deferred to investigation)
- **Analytics**: 9 files over 5120 as of 2026-07-03 (3 live topic files + 6 archives).

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Make the Tier-3 rotation self-fire: when a briefing topic file crosses 5120 bytes, the retro/wrap performs the split-by-date rotation automatically (safe default, no deferral, no user-recommendation)
- [ ] Decide the self-firing trigger locus (run-retro Tier-3 step / a SessionStart or commit-time budget-check hook that rotates) — must terminate in a self-firing cadence per P375, not a "run this when you remember" recommendation
- [ ] Confirm archives are handled (archive files over threshold → date-range sub-split, or exempt archives from the live budget)

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P413 (same meta-class — wrap defers a mechanical action to the user instead of doing it); P375 (no self-firing cadence — "run run-retro when you want it" is a named re-entry nothing self-fires); P378 (the earlier briefing-rotation deferral instance)

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)

- **Meta-class**: AFK/wrap surfaces mechanical actions as deferred user-recommendations instead of performing them (session memory `feedback_system_holds_the_memory_not_the_user`, `feedback_tier3_rotation_prefer_split`).
- ADR-040 — SessionStart briefing surface + Tier-3 5120-byte envelope.
- `/wr-retrospective:run-retro` Tier-3 rotation step — the owner of the split-by-date logic that should self-fire.
- P378 — earlier instance of deferred briefing rotation (2026-07-03 "split. lazy question").
