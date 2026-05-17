# Session Retrospective — 2026-05-17 (session 4, iter 7, P087 Phase 3 ADR-063 landing)

P086 retro-on-exit for AFK iter-7 session 4 subprocess. Iter shipped ADR-063 (Phase 3 presentation-layer contract for P087 plugin-maturity rollout) + 4 follow-on tickets (P237-P240).

## Briefing Changes

- **Added**: (none — no surprising or new gotchas this iter)
- **Removed**: (none)
- **Updated**: (none)
- **README index refreshed**: not required (no topic-file edits)

The Phase 3 disambiguation point (ADR-063 Phase 3 = presentation-layer rollout; ADR-057 Phase 3 = R6-gated escalation, deferred) is documented in ADR-063 itself (§Context and Problem Statement + §Decision Drivers); briefing-note would be a third surface for the same content. Skipped.

## Signal-vs-Noise Pass (P105)

Skipped per AFK iter discipline — no briefing entries were cited or paraphrased in this iter (only the SessionStart Critical Points block was loaded; no per-entry citation triggered). Per Step 1.5's classification ownership: AFK iters that don't exercise individual briefing entries can defer signal scoring to interactive retros that have more session-attention bandwidth to read each entry.

## Problems Created/Updated

- **P087** — updated. Investigation Task line 128 ticked ("Design the presentation layer detailed format"). New Iter-7 session-4 note recording Phase 3 ADR-063 landing + architect/JTBD verdicts + ecosystem grounding. Decision record section updated with "Phase 3 ADR landed 2026-05-17" entry. Effort line unchanged at L (Phase 3a/b/c/d implementation remains). No WSJF re-rate.
- **P237** — created (capture-problem skill invocation). Phase 3a population script (`wr-itil-plugin-maturity-populate`). M-effort technical. Blocks P238.
- **P238** — created (direct Write per SKILL-bounded fanout pattern). Phase 3b renderer + advisory drift detector. M-effort technical. Blocked by P237; blocks P087 closure.
- **P239** — created (direct Write). Phase 3c bats doc-lint per plugin. S-effort technical. Blocked by P237 + P238.
- **P240** — created (direct Write). Phase 3d JTBD outcome amendments (JTBD-302 / JTBD-007 / JTBD-101 / JTBD-003). S-effort user-business. JTBD trace: JTBD-302/007/101/003. Persona: plugin-user.

## Tickets Deferred

(None.)

## Verification Candidates

(None — this iter did not exercise any `.verifying.md` ticket's fix in-session. Work was ADR-authoring + ticket-scaffolding only.)

## Pipeline Instability

| Signal | Category | Citations | Decision |
|--------|----------|-----------|----------|
| JTBD agent's full review text was elided on first invocation; only the marker-write summary was returned to my context. Required a re-invocation with explicit "no marker write" instruction to surface the inline review text. | Subagent-delegation friction | First Agent call to `wr-jtbd:agent` returned `Verdict marker written. The YELLOW outcome maps to FAIL...` summary only; second call (with explicit no-marker-write instruction) returned the full 700-word review. Cost: one extra Agent invocation (~85K tokens). | recorded in retro only — single observation, not enough signal for a ticket; the workaround (explicit no-marker-write instruction on re-query) was effective. Will ticket if observed again. |

**JTBD currency advisory: clean (12 packages, 0 drift instances)** — `wr-retrospective-check-readme-jtbd-currency` reports `TOTAL packages=12 with_jtbd=12 drift_instances=0`. No README-vs-JTBD drift this session.

## Topic File Rotation Candidates

14 topic files OVER budget; 0 MUST_SPLIT (none above 2× ceiling). Same baseline state observed in 2026-05-15 context-analysis retro; no per-file delta from this iter's work (this iter touched no briefing files).

| Topic file | Bytes | Threshold | Proposed rotation | Decision |
|------------|-------|-----------|-------------------|----------|
| `docs/briefing/hooks-and-gates-archive.md` | 10009 | 5120 | leave-as-is (Branch B; 1.95× ceiling, no Step 1.5 noise scores this retro, no clear sub-topic boundary identified) | deferred |
| `docs/briefing/releases-and-ci-archive.md` | 9941 | 5120 | leave-as-is | deferred |
| `docs/briefing/agent-hook-gate-quirks.md` | 9434 | 5120 | leave-as-is | deferred |
| `docs/briefing/afk-subprocess-recovery.md` | 9397 | 5120 | leave-as-is | deferred |
| `docs/briefing/afk-subprocess-mechanics.md` | 9093 | 5120 | leave-as-is | deferred |
| `docs/briefing/plugin-distribution.md` | 8975 | 5120 | leave-as-is | deferred |
| `docs/briefing/governance-workflow-surprises.md` | 8269 | 5120 | leave-as-is | deferred |
| `docs/briefing/hooks-and-gates-archive-pre-2026-05-04.md` | 7615 | 5120 | leave-as-is | deferred |
| `docs/briefing/releases-and-ci.md` | 7208 | 5120 | leave-as-is | deferred |
| `docs/briefing/afk-subprocess.md` | 6712 | 5120 | leave-as-is | deferred |
| `docs/briefing/agent-interaction-patterns.md` | 6684 | 5120 | leave-as-is | deferred |
| `docs/briefing/governance-workflow-archive.md` | 6086 | 5120 | leave-as-is | deferred |
| `docs/briefing/governance-workflow-archive-mid.md` | 5568 | 5120 | leave-as-is | deferred |
| `docs/briefing/governance-workflow-archive-pre-2026-04-23.md` | 5529 | 5120 | leave-as-is | deferred |

Branch B (OVER but <2× ceiling) heuristic permits defer — the rotation prompt accumulates across iters until MUST_SPLIT fires (Branch A). No file is currently at MUST_SPLIT threshold. No briefing files touched this iter so the ratios are unchanged from the prior retro's measurement.

## Ask Hygiene (P135 Phase 5 / ADR-044)

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|

**Lazy count: 0**
**Direction count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

R6 numeric gate (lazy count ≥ 2 across 3 consecutive retros) does NOT fire. No deviation-candidate queued. Persisted at `docs/retros/2026-05-17-session-4-iter-7-p087-phase-3-adr-063-ask-hygiene.md`.

## Context Usage (Cheap Layer)

| Bucket | Bytes | % of total | Δ vs prior |
|--------|-------|-----------|-----------|
| decisions | 1,417,843 | 41.4% | +71,006 (+5.3%) |
| skills | 893,148 | 26.1% | +69,311 (+8.4%) |
| problems | 388,997 | 11.4% | +82,257 (+26.8%) ⚠ |
| hooks | 371,318 | 10.9% | +33,123 (+9.8%) |
| memory | 217,269 | 6.4% | +0 (0.0%) |
| briefing | 125,974 | 3.7% | +6,871 (+5.8%) |
| jtbd | 41,931 | 1.2% | +382 (+0.9%) |
| project-claude-md | 4,277 | 0.1% | +0 (0.0%) |
| framework-injected | not measured | — | reason=framework-injected-no-on-disk-source |

**Total measured: 3,460,757 bytes** (vs prior 3,279,807; +180,950 bytes / +5.5% over 3 days since 2026-05-14 snapshot per `docs/retros/2026-05-15-context-analysis.md` HTML-comment trailer).

**Top-5 offenders** (measurement-method: byte-count-on-disk per ADR-026):

1. `decisions` (1.4 MB) — ADR corpus; ADR-063 added today contributed ~32 KB.
2. `skills` (893 KB) — SKILL.md prose across 11 plugins; no edits this iter.
3. `problems` (389 KB) — problem-ticket corpus; P237/P238/P239/P240 added today contributed ~17 KB.
4. `hooks` (371 KB) — hook script bodies + lib helpers; no edits this iter.
5. `memory` (217 KB) — per-user memory entries; no edits this iter.

**Deep-analysis advisory fires** — `problems` bucket grew +26.8% since prior snapshot (over the +20% threshold). Recommend `/wr-retrospective:analyze-context` on next interactive retro to investigate per-plugin / per-turn attribution for the growth (likely concentrated in the P162 / P233 / P234 / P237-P240 cluster shipped this session).

Per-plugin breakdown available in `/wr-retrospective:analyze-context` (deep layer).

## Codification Candidates

(None — this iter's work was contract-authoring and ticket-scaffolding only; no recurring-pattern observations to codify and no targeted improvements to existing codifiables surfaced.)

## No Action Needed

- **Architect + JTBD review cycle** worked as designed — both returned YELLOW-with-adjustments with concrete grounded adjustments. All 4 architect adjustments + 5 JTBD adjustments + 4 JTBD outcome amendments folded into ADR-063 + Phase 3d follow-on ticket P240. Standard cycle, no friction beyond the JTBD-marker-write-elides-review-text Pipeline Instability observation above.
- **Ecosystem grounding cycle** worked as designed — the parallel ecosystem-research Agent invocation returned 10 cited prior-art patterns (npm deprecate, GitHub archived, semver, Apache Incubating, TC39, MDN BCD, Rust, PEP 411, Linux CONFIG_EXPERIMENTAL, shields.io, VS Code preview) that materially informed Decision Drivers + Considered Options. ADR-026 grounding satisfied without forced post-hoc fabrication.
- **Capture-problem fanout** worked but with a known design constraint: invoking the SKILL for each of 4 captures would have cost ~85K tokens per invocation (SKILL.md re-load). Pragmatic adaptation — invoked SKILL once for P237 (canonical contract); wrote P238/P239/P240 via direct Write since the create-gate marker was already set and session-scoped. Both paths produced equivalent tickets. Not friction-worthy of a ticket; design constraint of capture-problem's contract scope.
- **Risk-scorer pipeline verdict** PASS at 1/25 Very Low for all 3 layers; well within 4/Low appetite. Standard outcome for docs-only commits.
- **Two-commit grouping per ADR-014** (Commit A: ADR-063 + P087 edits; Commit B: P237-P240) preserved logical-change-per-commit grain.

## Iter Summary

**Shipped**: ADR-063 Phase 3 presentation-layer contract for P087 plugin maturity rollout + 4 sub-iter follow-on tickets (P237/P238/P239/P240).

**Verdict**: clean iter. Two commits landed (`48ffe01` ADR-063 + P087; `3953a26` P237-P240). Both gates passed (architect + JTBD reviews YELLOW-with-adjustments folded in; risk-scorer PASS at 1/25). No pipeline-instability ticket-worthy except one single observation recorded in retro only.

**Next iter**: orchestrator picks next WSJF top. P237 (Phase 3a population script) is the natural next slice if WSJF + ordering invariant lift it to top, but the orchestrator's framework prioritisation owns selection.
