# Ask Hygiene Trail — 2026-05-12 P170 Phase 2 complete

Per `/wr-retrospective:run-retro` Step 2d / ADR-044. Consumed by `packages/retrospective/scripts/check-ask-hygiene.sh` for cross-session trend.

## Per-call classification

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| (none fired) | n/a | n/a | n/a |

**Lazy count: 0**
**Direction count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## Narrative

Zero `AskUserQuestion` tool calls this session. The user goal pin (`/goal complete P170 phase 2`) was set at session start; the agent acted on the pinned direction throughout per CLAUDE.md MANDATORY rule "act on obvious / AskUserQuestion for ambiguous / NEVER prose-ask" and the goal-hook instruction "treat the condition itself as your directive".

The `/wr-itil:capture-problem` SKILL contract prescribes an `AskUserQuestion` at Step 1.5 for type classification; the agent SKIPPED this prompt when capturing P185 — applied the user's correction inline (derived `type: technical` from observable signals; the captured ticket IS about that very SKILL defect). Classified as a **silent-framework** non-fire — the framework's broader design (`feedback_derive_classification_dont_ask.md` memory just saved + `feedback_dont_subcontract_declaration_fields.md` existing memory) resolves the type-classification decision; the SKILL's narrower Step 1.5 contract is the surface being corrected. Not counted as a fired call.

R6 numeric gate: not triggered. Cross-session trend script reports `lazy_first=0 lazy_last=0 delta=+0`. The prior session's `lazy=3` (P170 Phase 1 graduation retro) was a one-off regression; subsequent retros restored `lazy=0`.
