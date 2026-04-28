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

---

# Ask Hygiene — 2026-04-28 (AFK `/wr-itil:work-problems` iter 9, P132 declarative CLAUDE.md rule)

Per ADR-044 / P135 Phase 5. Same-day continuation of the trail file; this section covers iter 9 shipping the P132 Phase 2c CLAUDE.md MANDATORY rule entry.

## In-session AskUserQuestion calls

(none — `claude -p` AFK subprocess; `AskUserQuestion` unavailable per ADR-013 Rule 6 + work-problems iteration-worker prompt forbidding clause)

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

AFK iter; denominator-zero across architect + JTBD gate delegations (both PASS via `Agent` tool calls, NOT `AskUserQuestion`). Per ADR-044, agent-delegation tool calls are framework-resolved via the gate contracts and are NOT `AskUserQuestion`-classifiable. R6 numeric gate (lazy ≥2 across 3 consecutive retros) NOT firing — four same-day denominator-zero AFK-subprocess iterations cannot fire R6 by construction. Notable composition: P132 Phase 2a found already-shipped via P135 Phase 2 (commit fae42aa); the framework's R6 declarative-first discipline is operating as designed — Phase 2c declarative ships first, Phase 2b hook deferred until R6 fires on real foreground evidence.

---

# Ask Hygiene — 2026-04-28 (AFK `/wr-itil:work-problems` iter, P133 Phase 1 zsh-portability)

Per ADR-044 / P135 Phase 5. Same-day continuation of the trail file; this section covers the P133 Phase 1 iter shipping the `/install-updates` SKILL.md L167 array-form fix + `reconcile-readme.sh` defensive `status` → `ticket_status` rename.

## In-session AskUserQuestion calls

(none — `claude -p` AFK subprocess; `AskUserQuestion` unavailable per ADR-013 Rule 6 + work-problems iteration-worker prompt forbidding clause)

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

AFK iter; denominator-zero across architect + JTBD + style-guide + voice-tone gate delegations (all PASS / advisory-PASS via `Agent` tool calls, NOT `AskUserQuestion`); risk-scorer commit gate `wr-risk-scorer:pipeline` returned commit=3 push=2 release=2 (all Very Low, within Low-4 appetite, RISK_BYPASS=reducing). Per ADR-044, agent-delegation tool calls are framework-resolved via the gate contracts and are NOT `AskUserQuestion`-classifiable. R6 numeric gate NOT firing — five same-day denominator-zero AFK-subprocess iterations cannot move the lazy-count needle by construction; the metric only counts retros where AskUserQuestion was actually available to fire.

Notable signal — **dispatch-state staleness**: orchestrator dispatched this iter with `Status: Open` + `File: ...open.md` but the actual repo state at iter-start (commit `a22d792` already landed) was `Status: Verification Pending` + `File: ...verifying.md`. The transition file rename + Status edit + Fix Released field were already in HEAD; only the underlying code work (install-updates / reconcile-readme / bats / changeset) and the README index update remained for this iter to land. Pre-existing staged drift (P033 reopen + README reconcile + `.claude/settings.json` modifications) was unstaged to keep this commit single-purpose per ADR-014 ONE-commit-batching. See Pipeline Instability section in iter retro summary for the routing decision (defer to next interactive session per AFK fallback).

---

# Ask Hygiene — 2026-04-28 (AFK `/wr-itil:work-problems` iter, P033 Phase 1a ADR-047 design)

Per ADR-044 / P135 Phase 5. Same-day continuation of the trail file; this section covers the P033 Phase 1a iter shipping ADR-047 (install-updates governance-artefact scaffolding design) + P033 ticket re-rate + WSJF refresh.

## In-session AskUserQuestion calls

(none — `claude -p` AFK subprocess; `AskUserQuestion` unavailable per ADR-013 Rule 6 + work-problems iteration-worker prompt forbidding clause)

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

AFK iter; denominator-zero across architect + JTBD gate delegations (both PASS via `Agent` tool calls, NOT `AskUserQuestion`); risk-scorer commit gate `wr-risk-scorer:pipeline` returned 1/1/1 (all Very Low, well within Low-4 appetite). Per ADR-044, agent-delegation tool calls are framework-resolved via the gate contracts and are NOT `AskUserQuestion`-classifiable. R6 numeric gate NOT firing — six same-day denominator-zero AFK-subprocess iterations cannot move the lazy-count needle by construction.

Notable signal — **`.claude/` write-protection blocks Phase 1b implementation in AFK iters**: the iter dispatcher's "do NOT write under `.claude/`" direction (P131 Phase 2 enforcement) blocks the Phase 1b implementation site (`.claude/skills/install-updates/SKILL.md` + templates + bats test) from this AFK iter. The P131 hook itself ALLOW-LISTS `.claude/skills/*` (per `claude-space-gate.sh::is_protected_claude_path`), so the block is dispatcher-direction-level, not hook-level. The conservative response was to split P033 Phase 1 into Phase 1a (design ADR, this iter) + Phase 1b (SKILL.md + templates + bats, next foreground iter). This is a reusable pattern: when AFK iter cannot reach the implementation site due to dispatcher constraints, ship the declarative slice and defer implementation. Mirrors P131/P132 phasing precedent. Surfaced in Pipeline Instability section of the Step 5 retro summary.

