# Ask Hygiene — P207 iter, 2026-06-06

Surface: `/wr-itil:work-problems` AFK iter dispatched against P207 (Known Error → Verifying fold-fix). Retro runs inside the iter subprocess per ADR-032 subprocess-boundary variant (P086).

## Calls

The iter constraint forbids `AskUserQuestion` entirely (per task prompt: "NEVER call AskUserQuestion — queue any genuine direction-setting / unconfirmed-ADR point to outstanding_questions and skip"). The iter emitted zero `AskUserQuestion` calls — all per-step decisions resolved either silently per the SKILL contract's mechanical carve-outs (manage-problem Step 2 derive-don't-ask; Step 5 silent-classification; Step 9c Fix Strategy stub silent-pick) or were not needed (no direction-setting / no genuine ≥2-option decision).

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| — | — | — | (no `AskUserQuestion` calls fired this iter) |

**Lazy count: 0**
**Direction count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## Notes

- P207 was a pure example-fidelity SKILL.md fix with no ADR signals. The mechanical SKILL contract resolved all decisions (architect gate → wr-architect:agent; JTBD gate → wr-jtbd:agent; commit gate → wr-risk-scorer:pipeline; external-comms gates → risk-scorer:external-comms + voice-tone:external-comms; Stage 1 ticketing → mechanical auto-ticket; Stage 2 fix-strategy → silent agent-pick).
- The user's correction-on-correction P207 ticket already records the workaround verbatim ("Drop the `--label` flag..."), so the implementation surface had a single obvious shape. No `AskUserQuestion`-worthy decision arose.
