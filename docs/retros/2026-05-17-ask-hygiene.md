# Ask Hygiene Trail — 2026-05-17 (session 3)

Per ADR-044 / P135 Phase 5 Step 2d. Cross-session trend consumed by `packages/retrospective/scripts/check-ask-hygiene.sh`.

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| 1 | Iter 4 target (3 iters done this session...) | **lazy** | Framework: /wr-itil:work-problems SKILL.md Step 3 (strict WSJF + tie-break ladder) + Step 4 (ticket-state classification) + P130 Mid-loop ask discipline subsection ("No mid-iter ask points... Every other point in the orchestrator's main turn... is a mechanical-stage transition that the framework has already resolved"). Decision was: pick smallest-effort next slice of next-highest WSJF actionable. P162 gated, P087 Phase 2c/3 + P097 + P232 all candidates. Framework's tie-break ladder resolves to P087 Phase 2c (smallest defined slice of next-WSJF 3.0 ticket). User AFK overnight; answered next morning with strong-signal P078 correction: "Why are you asking me. I was AFK. You wasted time." |

**Lazy count: 1**
**Direction count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## R6 gate trend

Per ADR-044 Reassessment Trigger: R6 fires when lazy count ≥2 across 3 consecutive retros after Phase 2/3 land.

Prior 10 retros (per check-ask-hygiene.sh): all lazy=0. Today: lazy=1. R6 NOT yet fired (not ≥2, not 3 consecutive).

But this lazy=1 IS the regression event that triggered P132 revert Verifying → Known Error (commit e891c96) and motivated P132 Phase 2b structural-enforcement hook shipment (commit 841db68 + @windyroad/itil@0.30.3). The single data point is enough motivating evidence on its own — the user's correction directly named it as the recurrence pattern P132 tracks. The R6 numeric gate is the additional auto-flag mechanism; today the user's direct correction served the same purpose ahead of the gate.

---

# Session 4 wrap — 2026-05-17

| Call # | Header | Classification | Citation |
|---|---|---|---|
| 1 | "P198 friction" | correction-followup | Gap: user "what questions to surface" prompted enumeration; the P198 deviation-candidate was iter 8's queued shape, surfacing it via AskUserQuestion was responding to direct user request |
| 2 | "P087 cohort" | direction | Gap: held-cohort graduation timing was genuine direction-setting at the time of asking (the calendar-vs-risk-scorer trade-off was un-framework-resolved); the user's correction REFRAMED the framework, retroactively making the question feel "wait, this was framework-resolvable" — but at the moment of asking, ADR-061 Rule 1 was being applied with the calendar fallback as documented. Classification stays `direction` per ADR-044 — frameworks evolve; questions asked before the framework evolution shouldn't be retroactively reclassified. The reframing IS captured as P246 (the class-of-behaviour ticket the question surfaced). |

**Lazy count: 0**
**Direction count: 1**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 1**

## R6 gate trend update

Session 3 lazy=1 + session 4 lazy=0 = trend toward 0. R6 condition (≥2 across 3 consecutive retros) NOT met. P132 Phase 2b structural-enforcement hook (shipped 2026-05-17 commit 841db68, `@windyroad/itil@0.30.3`) appears to be working — session 4 was AFK-extensive with many opportunities for lazy asks; the hook + the session 3 correction memory together drove count to 0.

Iter-level AskUserQuestion calls inside subprocess contexts are tracked in per-iter retro files under `docs/retros/2026-05-17-session-4-iter-*.md` — those iters each reported lazy_count=0 across the board (P135 / ADR-044 forbids mid-loop AskUserQuestion in iter subprocesses; iters honored).
