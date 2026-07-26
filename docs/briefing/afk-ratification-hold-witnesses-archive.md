# AFK Ratification Hold Witnesses — Archive

Older witness entries rotated out of
[`afk-ratification-hold-witnesses.md`](./afk-ratification-hold-witnesses.md) on 2026-07-26 per the
P099 Tier 3 budget rotation (split-by-date). Kept for the audit trail; the live file carries the
witnesses whose lessons are still load-bearing.

## 2026-07-15

- **P376 Gap 2, 2026-07-15 — first witness.** The fix-vehicle RFC already existed carrying `stories: []`. Took 3 architect reviews to converge on the hold shape. P456 tracks the friction fix. Superseded in substance by the later witnesses, which generalise the hold beyond the pre-existing-empty-`stories:` case. <!-- signal-score: 1 | last-classified: 2026-07-26 | first-written: 2026-07-15 -->

## 2026-07-26 (early cohort)

Rotated 2026-07-26: the second and third witnesses. Their generalisation ("the hold applies to ANY fix-implementation iter, not just a pre-existing empty-`stories:` RFC") is now carried by the later witnesses and by the Critical Points roll-up; kept here for the cost accounting.

- **P430, 2026-07-26 — second witness, and it generalises.** The ticket had no fix vehicle at all, so the hold is not specific to a pre-existing `stories: []` RFC: ANY fix-implementation iter now walks map → RFC → story → ratify and stops at ratify. The fix was a 3-line env-var guard plus one SKILL export line — effort S, approach covered by four existing ADR precedents — and it still could not land. Budget went to 3 architect + 2 style-guide + 2 voice-tone + 1 accessibility review, and three new artefacts. This iter also produced the refutation of the tempting shortcut: accepting the story mechanically (I7+I8+I10 pass without a ratification check) is the ADR-096 bypass class, not a loophole — ADR-095 line 45 and ADR-096 lines 19/25/44 put ADR-090 ratification AT the accepted gate. That the code permits it anyway is P465. <!-- signal-score: 2 | last-classified: 2026-07-26 | first-written: 2026-07-26 -->
- **P431, 2026-07-26 — third witness; the shape is now the default.** The fix was a single `jq` branch in one lib helper. Reaching the hold cost 9 reviewer spawns (3 architect + 2 jtbd + 1 style-guide + 1 voice-tone + 1 accessibility + 1 risk-scorer) and four new artefacts. Two useful notes: the architect rounds are not waste — each of the three surfaced a genuinely new blocking condition the prior round missed (a narrow symmetry marker, six existing bats fixtures the fix would turn RED, a fabricated cadence trigger) — and the write gates for a new RFC file stack **three deep and are discovered one BLOCK at a time**, so front-load architect + jtbd before the first Write rather than paying a block per gate. <!-- signal-score: 2 | last-classified: 2026-07-26 | first-written: 2026-07-26 -->
