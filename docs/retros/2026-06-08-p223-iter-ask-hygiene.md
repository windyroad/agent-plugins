# Ask Hygiene trail — 2026-06-08 P223 closure iter (work-problems AFK)

Per ADR-044 Step 2d — per-session classification of AskUserQuestion calls. Consumed by `packages/retrospective/scripts/check-ask-hygiene.sh` for cross-session lazy-count trend.

## Session classification

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| — | — | — | No AskUserQuestion calls this iter |

**Lazy count: 0**
**Direction count: 0**
**Deviation-approval count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## Context

This is an AFK work-problems iter (`/wr-itil:work-problems` orchestrator). Orchestrator constraint: `NEVER call AskUserQuestion. P223 has 0 ADR signals.`

All decisions in this iter were framework-mediated:

- Closure shape (KE→Closed-direct-as-superseded) — ADR-079 Phase 2 ADR-supersession evidence shape; 7-sibling precedent this week.
- Architect verdict re-issue (ISSUES FOUND → PASS) — `packages/architect/agents/agent.md` lines 116-148 three-shape verdict doctrine; P217 closure precedent.
- BYPASS_RISK_GATE=1 — orchestrator pre-authorised constraint for the P353 sibling-recurrence pattern.
- Pipeline scorer commit gate — passed within appetite + reducing bypass; no user gate fired.

Per ADR-044 mechanical-stage discipline + CLAUDE.md P132 inverse-P078: zero AskUserQuestion is the correct iter-context behaviour.
