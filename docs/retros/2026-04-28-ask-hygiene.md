# Ask Hygiene — 2026-04-28 (AFK `/wr-itil:work-problems` iter, P124 Phase 3)

Per ADR-044 / P135 Phase 5. Trail file consumed by `packages/retrospective/scripts/check-ask-hygiene.sh` for cross-session lazy-count trend.

## In-session AskUserQuestion calls

(none — this iteration ran as a `claude -p` AFK subprocess; `AskUserQuestion` is unavailable per ADR-013 Rule 6 + the work-problems iteration-worker prompt's explicit forbidding clause)

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| — | — | — | — |

**Lazy count: 0**
**Direction count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## Notes

AFK iteration-worker subprocess; per ADR-013 Rule 6 + iteration-worker prompt contract, all decisions resolve non-interactively. No AskUserQuestion calls = lazy count 0 by construction. Cross-session trend: prior retro (2026-04-27) recorded `lazy=3 direction=8`; this iteration is silent on the metric (not a denominator-1 datapoint — the metric only counts retros where AskUserQuestion was actually available to fire).

---

# Ask Hygiene — 2026-04-28 (AFK `/wr-itil:work-problems` iter, P134 truncation contract)

Per ADR-044 / P135 Phase 5. Same-day continuation of the trail file (one file per date); this section covers the P134 iter that landed commit `a8b6f18`.

## In-session AskUserQuestion calls

(none — this iteration ran as a `claude -p` AFK subprocess; `AskUserQuestion` is unavailable per ADR-013 Rule 6 + the work-problems iteration-worker prompt's explicit forbidding clause)

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| — | — | — | — |

**Lazy count: 0**
**Direction count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## Notes

AFK iter; same denominator-zero shape as the earlier P124 Phase 3 entry above. The architect + JTBD subagent delegations both ran as `Agent` tool calls (not `AskUserQuestion`) and returned PASS verdicts; the risk-scorer commit gate ran as a `wr-risk-scorer:pipeline` subagent call (residuals 2/2/0, reducing-bypass). Per ADR-044, agent-delegation tool calls are NOT `AskUserQuestion`-classifiable — they're framework-resolved via the architect/JTBD/risk gate contracts. Ask-hygiene metric remains denominator-zero for both same-day iterations.

---

# Ask Hygiene — 2026-04-28 (AFK `/wr-itil:work-problems` iter, P131 Phase 2 claude-space-protection hook)

Per ADR-044 / P135 Phase 5. Same-day continuation of the trail file (one file per date); this section covers the P131 Phase 2 iter shipping the `.claude/` user-space write protection hook.

## In-session AskUserQuestion calls

(none — this iteration ran as a `claude -p` AFK subprocess; `AskUserQuestion` is unavailable per ADR-013 Rule 6 + the work-problems iteration-worker prompt's explicit forbidding clause)

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| — | — | — | — |

**Lazy count: 0**
**Direction count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## Notes

AFK iter; same denominator-zero shape as the earlier P124 Phase 3 + P134 truncation-contract entries. Architect + JTBD + style-guide + voice-tone gate delegations all ran as `Agent` tool calls (not `AskUserQuestion`) and returned PASS / PASS-WITH-NOTES / ALIGNED / advisory-PASS / out-of-scope-PASS verdicts; risk-scorer commit gate ran as a `wr-risk-scorer:pipeline` subagent call (residuals 2/2/2, all Very Low, well within Low-4 appetite). Per ADR-044, agent-delegation tool calls are NOT `AskUserQuestion`-classifiable — they're framework-resolved via the gate contracts. Ask-hygiene metric remains denominator-zero across all three same-day P124-3 / P134 / P131-Phase-2 iterations on this trail file. R6 numeric gate (lazy ≥2 across 3 consecutive retros) NOT firing — three consecutive AFK-subprocess iterations cannot move the lazy-count needle by construction.
