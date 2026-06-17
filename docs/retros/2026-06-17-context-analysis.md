# Context Analysis — 2026-06-17

> Source: `/wr-retrospective:analyze-context` (deep layer per ADR-043).
> Methodology: byte-count-on-disk + per-plugin decomposition + per-turn attribution (when session log available).
> Cheap-layer baseline: `packages/retrospective/scripts/measure-context-budget.sh`.
> Auto-fired from run-retro Step 2c (P314 iter 3) — delta-breach trigger (`project-claude-md` +37.9% vs 2026-06-08).

## Bucket Totals

Total measured: 9,560,977 bytes (prior 8,960,652 — Δ +6.7%).

| Bucket | Bytes | % of measured | Δ vs prior |
|--------|-------|---------------|------------|
| problems | 5,195,436 | 54.3% | +8.2% |
| decisions | 1,959,897 | 20.5% | +2.6% |
| skills | 1,236,787 | 12.9% | +5.8% |
| hooks | 541,274 | 5.7% | +6.6% |
| memory | 446,758 | 4.7% | +9.0% |
| briefing | 118,981 | 1.2% | +17.0% |
| jtbd | 55,947 | 0.6% | 0.0% |
| project-claude-md | 5,897 | 0.06% | +37.9% |
| framework-injected | not measured | — | reason=framework-injected-no-on-disk-source |

Note: byte-count-on-disk measures the corpus, not the injected context. The `problems` and `decisions` buckets are dominated by audit-trail corpus (closed tickets, ADR ledger) that is NOT wholesale injected — only the README index + relevant tickets/ADRs load per session. The trigger that fired (`project-claude-md` +37.9%) is a 1,620-byte absolute increase (P357 MANDATORY block added to `CLAUDE.md`); the percentage trips the 20% rule but the absolute delta is small and the content is load-bearing per-prompt guidance, not bloat.

## Per-Plugin Decomposition

### Hooks (aggregate from cheap layer: 541,274 bytes)

Sum of per-plugin rows below = 541,274 (sanity-check OK).

| Plugin | Bytes | % of hooks |
|--------|-------|------------|
| itil | 154,970 | 28.6% |
| risk-scorer | 108,886 | 20.1% |
| architect | 68,821 | 12.7% |
| voice-tone | 59,564 | 11.0% |
| jtbd | 39,893 | 7.4% |
| shared | 37,745 | 7.0% |
| tdd | 27,871 | 5.1% |
| style-guide | 24,305 | 4.5% |
| retrospective | 17,163 | 3.2% |
| connect | 2,056 | 0.4% |

### Skills (aggregate from cheap layer: 1,236,787 bytes)

Sum of per-plugin rows below = 1,223,717; residual ~13,070 bytes is non-plugin skill content (repo-local skills under `.claude/skills/` per ADR-030, not plugin-attributed).

| Plugin | Bytes | % of skills |
|--------|-------|-------------|
| itil | 914,846 | 74.0% |
| retrospective | 113,116 | 9.1% |
| risk-scorer | 68,550 | 5.5% |
| architect | 64,100 | 5.2% |
| jtbd | 21,702 | 1.8% |
| wardley | 11,926 | 1.0% |
| connect | 11,434 | 0.9% |
| voice-tone | 10,119 | 0.8% |
| style-guide | 3,895 | 0.3% |
| tdd | 3,369 | 0.3% |
| c4 | 660 | 0.05% |

## Top-N Offenders

| Surface | Bytes | Bucket | Comparable prior |
|---------|-------|--------|------------------|
| `packages/itil/skills/work-problems/SKILL.md` | 216,843 | skills | P097 (SKILL.md size cluster); ADR-054 REFERENCE.md lazy-load |
| `packages/itil/skills/manage-problem/SKILL.md` | 141,520 | skills | P097; ADR-054 |
| `packages/retrospective/skills/run-retro/SKILL.md` | 89,022 | skills | P097; ADR-038 progressive disclosure |
| `packages/itil/skills/review-problems/SKILL.md` | 74,478 | skills | P097; ADR-054 |
| `docs/problems/` (corpus) | 5,195,436 | problems | P282 (VQ README 134KB exceeded Read-tool cap); P134 README-history rotation |

## Per-Turn Attribution

per-turn attribution: not measured — no session log accessible (`.afk-run-state/` carries only `outstanding-questions.jsonl` + `risk-register-queue.jsonl`, not per-turn `usage` jsonl).

## Suggestions

1. **skills / itil SKILL.md cluster** — Four SKILL.md files exceed the P097 50KB threshold (work-problems 216,843; manage-problem 141,520; run-retro 89,022; review-problems 74,478 bytes). These load in full when the skill is invoked. Comparable prior: ADR-054 (SKILL.md runtime-budget policy — REFERENCE.md lazy-load extraction); ADR-038 (progressive disclosure). Estimated byte saving: `not estimated — no prior data` (no prior itil-SKILL REFERENCE.md extraction to anchor a figure). The continued-growth trend (skills +5.8%) warrants a dedicated REFERENCE.md extraction pass on work-problems/manage-problem when next touched — flagged in Policy Breaches below.
2. **problems corpus** — Largest bucket (5.2MB, 54%) but mostly closed-ticket audit trail not wholesale injected. Comparable prior: P282 reclaimed the Verification-Queue README from a 134KB Read-tool-cap breach via persisted-output + paged reads; P134 rotated README "Last reviewed" into `README-history.md`. The corpus itself is retained by design; the actionable surface is README currency (kept fresh by P062/P094 refreshes). Estimated byte saving on the injected surface: `not estimated — no prior data` for the corpus; README stays bounded by existing rotation.
3. **briefing (+17.0%)** — Approaching but under the Tier 3 envelope; `check-briefing-budgets.sh` reports zero OVER files this retro. No action; the +17% is normal cross-session accretion within budget.
4. **memory (+9.0%)** — User-memory dir growth, within normal accretion. No trim suggestion — memory entries are user-owned per ADR-030.
5. **decisions (+2.6%)** — ADR ledger + compendium README; durable governance corpus. Not a trim candidate.

## Policy Breaches

| Budget | Offender | Bytes | Citation |
|--------|----------|-------|----------|
| P097 SKILL.md ≤50KB cluster | `packages/itil/skills/work-problems/SKILL.md` | 216,843 | P097 (evolving budget anchor) |
| P097 SKILL.md ≤50KB cluster | `packages/itil/skills/manage-problem/SKILL.md` | 141,520 | P097 |
| P097 SKILL.md ≤50KB cluster | `packages/retrospective/skills/run-retro/SKILL.md` | 89,022 | P097 |
| P097 SKILL.md ≤50KB cluster | `packages/itil/skills/review-problems/SKILL.md` | 74,478 | P097 |

ADR-040 Tier 1/2/3 briefing budgets: no breach (`check-briefing-budgets.sh` empty). ADR-038 hook-prose ≤150-byte reminders: not sampled this run (no hook-prose change observed).

<!--
context-snapshot:
  total-bytes: 9560977
  hooks: 541274
  skills: 1236787
  memory: 446758
  briefing: 118981
  decisions: 1959897
  problems: 5195436
  jtbd: 55947
  project-claude-md: 5897
  framework-injected: not measured
  measurement-method: byte-count-on-disk
  measured-at: 2026-06-17
-->
