---
"@windyroad/itil": patch
---

P248: effort-tally gains `--render` and `--write` modes that turn per-ticket AFK actuals into a `## Effort Tally` section on the ticket body (ADR-067 item 2 data layer).

`effort-tally.sh` already attributed `.afk-run-state/iter*.json` cost/time/token actuals back to their source ticket and printed a per-ticket summary line. It now also renders those actuals as a `## Effort Tally` markdown section and idempotently writes it into the ticket file:

- `--render <ticket-file>` prints the section to stdout; `--write` injects or replaces it in place (lazy-empty: a ticket with no iters gets no section), mirroring the existing `update-problem-references-section.sh` replace-section idiom.
- Cost is the authoritative actual, wall-clock time is reliable, and raw token counts carry the `~` best-effort marker per the P089 Gap 2 authority hierarchy.
- Phase is bucketed RCA vs RFC from the ticket's current `**Status**` (Open is RCA, otherwise RFC); the single-phase limitation is noted in the generated marker.
- A `--source afk-backfill|live-iter` flag records each section's provenance so historical backfill and go-forward captures stay distinguishable.

The legacy no-argument list mode is unchanged. Seven behavioural tests cover render, phase bucketing, the source flag, idempotent writes, and lazy-empty removal. The estimate fields, the retrospective RMS calibration step, and the skill wiring remain follow-on slices.
