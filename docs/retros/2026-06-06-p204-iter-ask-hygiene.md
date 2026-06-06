# Ask Hygiene Trail — 2026-06-06 P204 iter

Per ADR-044 / Step 2d — `AskUserQuestion` call classifications for this iteration.

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|

**Lazy count: 0**
**Direction count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

Notes: zero `AskUserQuestion` calls fired this iteration. AFK orchestrator constraint explicitly forbids `AskUserQuestion` in iteration scope; direction-setting / unconfirmed-ADR points were queued to `outstanding_questions` (P204 new-jtbd-flag — JTBD-007-amend vs JTBD-009-add). The single non-mechanical decision in this iteration (which JTBD to amend or create) was correctly deferred to outstanding_questions per the iteration contract rather than fired as an ask. No prose-asks emitted in the iteration body (verified — every step that needed a decision either applied a framework heuristic, queued to outstanding_questions, or invoked a subagent per the gate contract).
