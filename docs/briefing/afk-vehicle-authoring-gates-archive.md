# Authoring the Fix Vehicle — Archive

Older entries rotated out of [`afk-vehicle-authoring-gates.md`](./afk-vehicle-authoring-gates.md)
under the P099 Tier 3 budget pass. Load this file only when the parent's entries do not answer
the question.

## What You Need to Know

Rotated 2026-07-26 per the P099 Tier 3 budget pass (Branch B, split-by-date). Both entries below are still true; they moved because their headlines are carried by the Critical Points roll-up and by the witness list, while the gate-by-gate mechanics that are only findable here stayed in the parent file.

- **Front-load architect + jtbd before the first Write.** The write gates for a new RFC file stack three deep and are discovered one BLOCK at a time, so paying a block per gate is pure waste. Front-loading does not eliminate the review rounds — each architect round reliably surfaces a genuinely new blocking condition the prior round missed — but it does stop you paying for the discovery twice. <!-- signal-score: 4 | last-classified: 2026-07-26 | first-written: 2026-07-26 -->

- **Know which of the five artefact paths are actually gated — four of them are not, and the exemption map inverts the write order.** `jtbd-enforce-edit.sh` exits 0 for `docs/jtbd/*`, `docs/story-maps/*`, `docs/stories/*` and `docs/problems/*/*.md`; only `docs/rfcs/` is gated. So when the JTBD gate demands a new grounding job, write the job **first** — it is exempt, and the RFC cannot be reviewed as aligned until the job it traces exists. This is the correction to P438's "sequence jtbd-policy writes last": that advice holds when the policy write would re-lock a marker you still need, and does not when the gated write is downstream of the policy file's content. Ask the jtbd reviewer for the exemption map in round one rather than inferring it. P424 iter 2026-07-26. <!-- signal-score: 2 | last-classified: 2026-07-26 | first-written: 2026-07-26 -->
