# Problem 511: The ask-hygiene trail is one file per day, so a second retro's counts are invisible to the R6 gate

**Status**: Known Error
**Reported**: 2026-08-21
**Priority**: 8 (Medium) — Impact: 2 × Likelihood: 4 — derived at capture. Impact 2: repo-local governance metric; nothing published, nothing breaks. But the metric it silently under-reports is the one gating whether an enforcement hook gets built, so a suppressed count defers a control indefinitely. Likelihood 4: fires whenever a day carries more than one retro, which happened three times today alone.
**Origin**: internal
**Effort**: S — derived at capture. A filename disambiguator plus a parser that reads every block in a file, or one file per retro rather than per day.
**WSJF**: 16 — (8 × 2.0) / 1 (2026-08-21 review: auto-transitioned Open → Known Error — root cause confirmed + workaround documented; Known Error multiplier 2.0)
**JTBD**: JTBD-001
**Persona**: developer

## Description

`run-retro` Step 2d persists its ask-hygiene table to `docs/retros/<YYYY-MM-DD>-ask-hygiene.md` — "one file per retro; date in filename for natural sort-by-date". The two clauses conflict the moment a day carries two retros, and the filename wins.

`check-ask-hygiene.sh` then reads one `RETRO` block per file — `head -1` at lines 117 and 143-146 — so a file's second and later blocks are dropped.

**Live witness at capture (2026-08-21).** `docs/retros/2026-08-20-ask-hygiene.md` carries two blocks: the morning retro and the evening one. The parser reads the morning block only, so the evening retro's `Direction count: 1` and `Correction-followup count: 1` never reach the trend. That file is the standing reproduction.

**One half is already discharged, and how it was discharged matters.** A third block, dated 2026-08-21, was initially appended to that same file on the mistaken assumption that a filename collision forced it — none existed. Its `Lazy count: 2` was the first non-zero in the entire trail and was invisible by construction. Moving it to its own `docs/retros/2026-08-21-ask-hygiene.md` made it readable:

```
RETRO 2026-08-20 lazy=0 direction=0 override=0 silent=0 taste=0 correction=0
RETRO 2026-08-21 lazy=2 direction=1 override=0 silent=0 taste=0 correction=0
TREND lazy_first=0 lazy_last=2 delta=+2
```

That fixed the **instance**, not the **class**. Root-cause half 2 below — the parser reads one block per file — is untouched and still live, which the 2026-08-20 two-block file demonstrates. Do not read the trend output above as evidence this ticket is closed.

## Symptoms

- A day's second and later retros contribute nothing to the trend, whatever they measured.
- `TREND` can report `delta=+0` across a window containing a genuine regression — observed 2026-08-21 before the split, when the trail's first non-zero lazy count sat in an unread second block.
- The under-count is silent: the script exits 0 and its output looks well-formed.

## Workaround

Read the trail file directly rather than trusting the script's summary. Nothing signals when that is necessary.

## Impact Assessment

- **Who is affected**: the maintainer, via a regression metric that reads clean while regressing.
- **Frequency**: every day with more than one retro. Three today.
- **Severity**: the R6 numeric gate (lazy ≥2 across 3 consecutive retros) decides whether the P135 Phase 4 enforcement hook is warranted. Counts the script cannot see cannot fire it, so the gate is biased toward never firing — and biased hardest on the busiest days, which are the ones most likely to produce lazy asks.
- **Analytics**: this ticket is the first measurement.

## Root Cause Analysis

Two independent halves, either of which alone would be enough:

1. **The filename cannot represent more than one retro per day.** A second retro either overwrites its predecessor or appends into the same file; both lose the one-file-per-retro contract the SKILL states.
2. **The parser reads one block per file.** Even with appended sections present on disk, only the first is counted — so the append strategy, which at least preserves the data, still does not reach the metric.

Same self-silencing shape as a stale `human-oversight: confirmed` marker: the detector keys on something that suppresses the very signal it is meant to raise. Here, more retro activity produces less measured signal.

### Investigation Tasks

- [ ] Decide the fix shape: disambiguate the filename (a sequence suffix or a session id), or keep one file per day and make the parser read every `RETRO` block in it
- [ ] Whichever is chosen, make `TREND` count retros rather than files — the R6 condition is worded per-retro
- [x] Backfill or annotate the file so the lazy=2 block is countable — **discharged 2026-08-21** by splitting the 2026-08-21 block into its own file; the first real data point is preserved and `TREND` now reports `delta=+2`. This closed the instance only; half 2 of the root cause remains open.
- [ ] Write a behavioural test: two retros on one date both reach the trend output

## Dependencies

- **Blocks**: the R6 gate's correctness, and therefore P135's Phase 4 decision
- **Blocked by**: (none)
- **Composes with**: P135

## Related

Captured via `/wr-itil:capture-problem`. Hang-off dispatch skipped per the SKILL's empty-candidates short-circuit — the extractable signals (`check-ask-hygiene.sh`, `docs/retros/<date>-ask-hygiene.md`) appear in no open or verifying ticket body.

- **P135** — the decision-delegation contract ticket whose Phase 4 enforcement hook is gated on the R6 numeric condition this metric feeds. The under-count defers that decision rather than resolving it.
- `packages/retrospective/scripts/check-ask-hygiene.sh` — the parser.
- `packages/retrospective/skills/run-retro/SKILL.md` Step 2d item 5 — the "one file per retro; date in filename" contract whose two halves conflict.
