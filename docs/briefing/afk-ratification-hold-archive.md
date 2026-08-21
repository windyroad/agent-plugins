# AFK Ratification Hold — Archive

Entries rotated out of [`afk-ratification-hold.md`](./afk-ratification-hold.md) for ADR-040 Tier 3 budget (split-by-date, P099). Load alongside the live file for full history.

## Archived 2026-08-20 (split-by-date)

Superseded in substance by the ADR-103 "approval is the story MAP's" entry that now leads the live file; retained here because its witness list (P376/P430/P431/P438/P424/P417/P425) is the cost record.

- **An AFK iter cannot land a code fix (unless the carve-out above applies). Plan it to author the fix vehicle and queue the ratification, and say so in the summary.** ADR-071 makes every fix go through an RFC; ADR-089 requires ≥1 story; ADR-095 requires story-map membership at capture; ADR-096 puts approval at the story's `accepted` gate and implementation requires `accepted`; under ADR-103 that approval is the MAP's. Ratification has no AFK carve-out, so the iter walks map → RFC → story and stops at ratifying the map — for ANY fix-implementation ticket, however small the fix. Four witnesses to date, the smallest being a 3-line env-var guard and a single `jq` branch; see [`afk-ratification-hold-witnesses.md`](./afk-ratification-hold-witnesses.md) for what each cost. <!-- signal-score: +7 | last-classified: 2026-07-26 | first-written: 2026-07-15 -->

## Rotated 2026-08-21 (P099 Tier 3, split-by-date)

Post-decision operating detail moved out of [`afk-ratification-hold.md`](./afk-ratification-hold.md) when it crossed the 5 KB Tier 3 ceiling. These describe what to do once you have decided to hold and author; the decision rule itself stays in the parent file.

- **The AFK shape.** Capture the story-map born `humanOversight: unconfirmed` in its data island; the story gets **no oversight field at all** (ADR-103 — writing one is both wrong and inert). Do NOT edit the RFC's frontmatter `stories:` array (the derived `## Stories` body table via the reverse-trace helper is fine, and an RFC may not reference a story whose map is unratified anyway). Queue ratify-the-map → accept → wire → implement to `outstanding_questions`, report partial-progress. Expect the JTBD gate to demand a new grounding job when the story's acceptance criteria map to no documented desired outcome — that is a fifth artefact, and writing it re-locks the JTBD gate via policy-file drift, so sequence jtbd-policy writes last. <!-- signal-score: 3 | last-classified: 2026-07-26 | first-written: 2026-07-26 -->
- **The bright line on what an AFK iter may author** (architect, P438 iter 2026-07-26): it may author any governance artefact born `unconfirmed`. It may NOT (a) write a `confirmed` marker, (b) transition an artefact into a state that authorises implementation, or (c) build implementation on unconfirmed substance. Authoring a born-unconfirmed job or map licenses nothing, which is why it is not the ADR-096 bypass class; accepting a story mechanically is, because that flips the commit-trailer gate open. <!-- signal-score: 3 | last-classified: 2026-07-26 | first-written: 2026-07-26 -->
