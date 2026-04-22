# Problem 105: `/wr-retrospective:run-retro` needs a signal-vs-noise pass on briefing entries to drive session-start curation

**Status**: Open
**Reported**: 2026-04-22
**Priority**: 16 (High) — Impact: Major (4) x Likelihood: Likely (4)
**Effort**: M
**WSJF**: (16 × 1.0) / 2 = **8.0**

> Split from P100 slice 2 during the 2026-04-22 design session. User framing (2026-04-22): *"basically we want to ask 'what was signal and what was noise' and then adjust accordingly"*. Run-retro gains a signal-vs-noise pass over briefing entries that were in context this session: signal (fired, saved a turn) gets promoted or kept in the Critical Points roll-up; noise (didn't fire, wasted attention, misleading) gets demoted, archived, or deleted. The curation mechanism is the feedback channel the SessionStart hook's value depends on over time.

## Description

P100 slice 1 migrated `docs/BRIEFING.md` into `docs/briefing/<topic>.md` per-topic files + `docs/briefing/README.md` as an index with a curated "Critical Points (Session-Start Surface)" roll-up. Slice 2 (this session) ships the `SessionStart` hook that reads the Critical Points roll-up and injects it at session start.

The Critical Points roll-up is currently curated by human judgment during `/wr-retrospective:run-retro` — the retro author decides which entries are "highest-value rules that save the most wasted turns". Without a feedback signal, curation is unanchored: old entries can linger in the Critical Points list even when they no longer fire, and new high-value entries may sit in a topic file instead of being promoted.

The user's refined framing (2026-04-22, during slice-2 execution): *"basically we want to ask 'what was signal and what was noise' and then adjust accordingly"*. The retro asks, per briefing entry that was in context this session: was it **signal** (fired, saved a turn, genuinely useful) or **noise** (didn't fire, wasted attention, misleading, stale)? Adjust accordingly — promote / keep / demote / archive / delete. Without this feedback loop, the SessionStart hook surfaces whatever the most recent retro author chose, which drifts away from actual usefulness over time.

## Symptoms

- `docs/briefing/README.md`'s Critical Points section is curated by the last run-retro author; no consumer-side signal validates that those are indeed the most helpful entries.
- New high-value briefing entries (e.g., discovered during a session) rely on the same author's judgment to reach the Critical Points roll-up. Slow uplift for entries that aren't obviously load-bearing.
- Stale entries (e.g., a workaround that no longer applies because the underlying bug was fixed) linger in Critical Points until a future author spots them.

## Workaround

Manual curation during run-retro. Retro author reads the Critical Points roll-up and promotes / demotes / archives entries based on memory of which ones helped this session. Burden scales with briefing-tree size.

## Impact Assessment

- **Who is affected**: Every session that reads the SessionStart briefing injection. As the briefing grows, signal-to-noise in Critical Points degrades without a feedback loop.
- **Frequency**: Every retrospective and every session that reads Critical Points (per P100 slice 2).
- **Severity**: Major. Directly affects the quality of the session-start briefing surface — the headline value of P100. A decayed roll-up produces wasted attention at session start.
- **Analytics**: Baseline after P100 slice 2 ships: count Critical Points entries that fire (cited) per session vs. entries that don't. Target: high-firing entries stay / rise in roll-up; low-firing entries drop.

## Root Cause Analysis

### Preliminary Hypothesis

run-retro Step 1 (read BRIEFING) and Step 3 (write learnings) both act on the author's current memory of the session. No step asks the author to classify each briefing entry that was in context this session as **signal** or **noise** and adjust accordingly. A new Step (candidate: 1.5 "Briefing signal-vs-noise pass" between Step 1 and Step 2) would prompt the author to label each exercised entry and propose the adjustment.

### Investigation Tasks

- [ ] Decide the signal/noise classification shape: binary (signal / noise), ternary (signal / noise / neutral), or free-text category. User direction points at binary — "what was signal and what was noise" — but "neutral / didn't fire" may still be useful data.
- [ ] Decide the adjustment rules: signal → promote to Critical Points roll-up (or keep if already there); noise → demote to topic file (or archive / delete if stale); what counts as "this session's entries in context" for the pass?
- [ ] Decide who runs the classification: user (prompted during run-retro), assistant (self-reports from tool-call history about which entries were cited / paraphrased / acted on), or both.
- [ ] Decide where the signal is persisted: per-entry front-matter in the topic file, index rows in `docs/briefing/README.md`, or a sidecar ledger (e.g., `docs/briefing/.signal-ledger.jsonl`).
- [ ] Amend `/wr-retrospective:run-retro` SKILL.md with the new step and data-shape contract.
- [ ] Architect review at implementation time — may warrant amending ADR-040 (Session-start briefing surface, proposed this session) to document the signal-vs-noise feedback loop as part of the curation contract rather than a separate decision.
- [ ] Bats coverage: simulate a run-retro invocation against a briefing tree; assert classification → roll-up regeneration.

### Fix Strategy

Pending investigation. Expected shape: new run-retro step ("what was signal, what was noise?") + per-entry classification + adjustment rules (promote / keep / demote / archive / delete) + persistence format + optional ADR-040 amendment.

## Dependencies

- **Blocks**: (none directly)
- **Blocked by**: (none — slice 2 of P100 must land first so the consumer surface exists, but P100 slice 2 does not literally block P105; P105 can be designed in parallel)
- **Composes with**: P100, ADR-040

## Related

- **P100 (`wr-retrospective` does not auto-surface `docs/BRIEFING.md`)** — parent. Slice 2 of P100 ships the SessionStart hook that reads Critical Points. P105 closes the curation-feedback gap that the hook's value depends on over time.
- **ADR-040 (Session-start briefing surface — directory + indexed README + helpfulness curation)** — the ADR authored during P100 slice 2 names helpfulness curation in its title as a future concern; P105 is that concern made actionable.
- **`docs/briefing/README.md`** — the Critical Points roll-up is the consumer-facing artefact this feedback loop curates.
