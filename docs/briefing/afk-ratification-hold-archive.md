# AFK Ratification Hold — Archive

Entries rotated out of [`afk-ratification-hold.md`](./afk-ratification-hold.md) for ADR-040 Tier 3 budget (split-by-date, P099). Load alongside the live file for full history.

## Archived 2026-08-20 (split-by-date)

Superseded in substance by the ADR-103 "approval is the story MAP's" entry that now leads the live file; retained here because its witness list (P376/P430/P431/P438/P424/P417/P425) is the cost record.

- **An AFK iter cannot land a code fix (unless the carve-out above applies). Plan it to author the fix vehicle and queue the ratification, and say so in the summary.** ADR-071 makes every fix go through an RFC; ADR-089 requires ≥1 story; ADR-095 requires story-map membership at capture; ADR-096 puts approval at the story's `accepted` gate and implementation requires `accepted`; under ADR-103 that approval is the MAP's. Ratification has no AFK carve-out, so the iter walks map → RFC → story and stops at ratifying the map — for ANY fix-implementation ticket, however small the fix. Four witnesses to date, the smallest being a 3-line env-var guard and a single `jq` branch; see [`afk-ratification-hold-witnesses.md`](./afk-ratification-hold-witnesses.md) for what each cost. <!-- signal-score: +7 | last-classified: 2026-07-26 | first-written: 2026-07-15 -->
