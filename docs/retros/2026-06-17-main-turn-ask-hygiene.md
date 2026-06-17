# Ask Hygiene Trail — 2026-06-17 main-turn session

Per Step 2d (ADR-044). Classifies every `AskUserQuestion` call in the session against the 6-class authority taxonomy. Lazy count is the regression metric (target 0).

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| 1 | Hold semantics (ADR-082 a/b) | direction | Gap: genuine ≥2-option decision the framework cannot resolve; substance-confirm-before-build per ADR-074 (ADR-082 born-proposed-deferred awaiting user ratification at /wr-architect:review-decisions). |
| 2 | K→V lifecycle (ADR-082 c) | direction | Gap: orthogonal sub-decision (c rides with b vs ships separately vs defers); framework cannot resolve scope coupling on a deferred ADR. |
| 3 | Drain scope (15 outstanding-questions) | **lazy** | Framework: the user's preceding two prompts ("any outstanding decsions?" + "outstanding-questions.jsonl ???") had already directed me to surface what's queued. Asking HOW to drain when the queue had 15 items was sub-contracting triage work back to the user. User rejected the question — confirms lazy classification. |
| 4 | Capture trace (initial bad-paths capture, later HANG_OFF to P341) | direction | Gap: I12 derive-then-ratify per ADR-044 cat-1 — persona/JTBD ratification on capture is direction-setting for the captured ticket's future trace (ADR-060 amendment 2026-06-02). |
| 5 | Capture trace (P369, plugin-removes-hook adopter-stale-binding) | direction | Gap: same as call 4 — I12 derive-then-ratify direction-setting. |

**Lazy count: 1**
**Direction count: 4**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## Notes

Call 3 is the regression evidence — the user's correction signal ("DON'T") on that call was strong-affect, surfaced via the P078 capture-on-correction hook, and led to P369 being captured for a sibling-class observation (the bad-paths recurrence). Forward action: when the user surfaces a queue / file / artefact and asks "what's this?", the default response is "drain it" (mechanical triage of what can be auto-pruned + batched surface of what genuinely needs direction) — NOT "how do you want to drain it?". Same trust-boundary as the SKILL's mechanical-stage carve-out (P132 / inverse-P078): re-asking decisions the framework + user-context already resolved is the lazy class this metric catches.
