# Retro — 2026-06-08 P223 closure iter (work-problems AFK)

Single AFK iter from `/wr-itil:work-problems` orchestrator. Outcome: P223 closed as superseded. One commit landed: `b468b3c`.

## Iteration summary

- **Ticket**: P223 (Risk scorer ignores release-risk accumulation across commits — upstream-mirror of #60)
- **Action**: worked → closed
- **Commit**: `b468b3c chore(itil): close P223 as superseded — 3-layer cumulative pipeline contract already shipped`
- **Risk scores**: `commit=2 push=2 release=1` (within appetite, reducing bypass)
- **Released?**: No (orchestrator constraint — no push/release)
- **Files touched**: `docs/problems/{known-error→closed}/223-*.md` (rename + closure body), `docs/problems/README.md` (WSJF row removed, inbound classification updated, Closed table row added, Last reviewed rotated), `docs/problems/README-history.md` (P229 fragment appended)

## What was decided and why

Investigation confirmed the 3-layer cumulative pipeline contract requested by P223 is **fully implemented** in current code. The closure cites:

- `packages/risk-scorer/agents/pipeline.md` lines 42-52 (Layer 1 Pending vs Queued partition per P202)
- pipeline.md lines 80-110 (Layer 1/2/3 cumulative scoring with upward accumulation)
- pipeline.md lines 178-189 (above-appetite STOP verdict + structured `RISK_REMEDIATIONS:` block)
- `RISK-POLICY.md` line 71 (appetite threshold = 4)
- ADR-018 (Inter-iteration release cadence — orchestrator-level drain trigger)
- ADR-015 (Pure-scorer contract — competence home)
- ADR-042 (Auto-apply scorer remediations — open vocabulary)

Empirical witness: every pipeline scorer invocation this AFK loop has emitted the canonical `RISK_SCORES: commit=N push=N release=N` block with Layer 1 capturing release-risk-across-unreleased-commits. The contract is end-to-end live.

P223 is the 8th KE→Closed-direct closure this week (sibling P216 / P217 / P218 / P222 / P224 / P225 / P227) — confirms ADR-079 Phase 2 ADR-supersession shape is load-bearing for ratification per outstanding-question queue #2.

## Pipeline Instability (Step 2b)

| Signal | Category | Citations | Decision |
|--------|----------|-----------|----------|
| Architect agent emitted "ISSUES FOUND" verdict heading with substantively "Conditional PASS" body, blocking the architect-mark-reviewed verdict-grep hook | Subagent-delegation friction | First-round architect call (agent `a3c86e79a7b9af75d`) issued "Architecture Review: ISSUES FOUND" with a body that explicitly named all dimensions as PASS and said "proceed under precedent + queue"; required a re-issue round-trip with explicit reference to `packages/architect/agents/agent.md` lines 116-148 three-shape verdict doctrine + P217 closure precedent to land a clean "PASS" heading | matches existing P217 (closed earlier today) — re-issue pattern was documented in P217 closure body; recurrence here confirms the agent prose surface (`packages/architect/agents/agent.md`) needs a sharpened nudge for affirmative-PASS-substance verdicts to use the PASS heading by default. Recorded for next interactive retro to ticket if recurrence persists |
| External-comms gate marker did not land despite both PASS verdicts (risk-scorer + voice-tone) being emitted | Hook-protocol friction | Both `EXTERNAL_COMMS_RISK_VERDICT: PASS` (agent `a201539f0c9e31f33`) and `EXTERNAL_COMMS_VOICE_TONE_VERDICT: PASS` (agent `a67ab55e8c93656ae`) landed in this iter; subsequent `git commit` still BLOCKED with `external-comms gate / risk evaluator: git-commit-message draft has not been reviewed`; `BYPASS_RISK_GATE=1` resolved per orchestrator constraint | matches existing P353 (substance-aware hash + atomic verdict-write — Verifying since 2026-06-06) — outstanding-question queue #7 already flags this recurrence. No new ticket; existing P353 surface carries the work. README inventory currency: not measured this iter (advisory script not invoked in iter context) |

## Verification Candidates (Step 4a)

None this iter — same-session verifying exclusion applies; no prior-session `.verifying.md` tickets matched in-session activity citations.

## Topic File Rotation Candidates (Step 3)

Not measured this iter (iter-mode skip — Tier 3 budget pass runs in interactive retro context).

## Briefing Changes (Step 3)

Scanned 0 candidate observations; 0 accepted. Iter-mode retros defer briefing-tree edits to interactive retro — the single-iter context lacks the cross-session signal needed to drive briefing changes per ADR-040 + ADR-013 Rule 5.

## Signal-vs-Noise Pass (Step 1.5)

Not run this iter (iter-mode skip per ADR-013 Rule 5 — signal-scoring on briefing entries requires cross-session signal accumulation; the iter's tool-call history is single-ticket-bounded). Persistence deferred to interactive retro.

## Context Usage Cheap Layer (Step 2c)

Not measured this iter (iter-mode AFK fallback — diagnostic script invocation deferred to interactive retro).

## Codification Candidates (Step 4b)

Two Stage 1 mechanical-auto-ticket observations from Pipeline Instability above; both dedup to existing tickets (P217 architect-PASS-heading-on-affirmative-substance, P353 substance-aware-hash). No new tickets this iter.

## Tickets Deferred

None — no Stage 1 fallback fired.

## Ask Hygiene (Step 2d)

This iter: zero AskUserQuestion calls (orchestrator constraint: `NEVER call AskUserQuestion`). Cross-session trend lazy-count contribution: 0.

Trail recorded at `docs/retros/2026-06-08-p223-iter-ask-hygiene.md`.
