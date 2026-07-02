# Context Analysis — 2026-07-03

> Source: `/wr-retrospective:analyze-context` (deep layer per ADR-043).
> Methodology: byte-count-on-disk + per-plugin decomposition + per-turn attribution (when session log available).
> Cheap-layer baseline: `packages/retrospective/scripts/measure-context-budget.sh`.
> Auto-fired from run-retro Step 2c during the P384 AFK iter — calendar-elapse trigger (prior report 2026-06-17, >14 days) AND briefing delta-breach (+26.1%, >20%).

## Bucket Totals

Total measured: **10,300,114 bytes** (prior 9,560,977 on 2026-06-17; Δ **+739,137 / +7.7%**).

| Bucket | Bytes | % of measured | Δ vs prior |
|--------|-------|---------------|------------|
| problems | 5,573,804 | 54.1% | +378,368 (+7.3%) |
| decisions | 2,097,092 | 20.4% | +137,195 (+7.0%) |
| skills | 1,317,740 | 12.8% | +80,953 (+6.5%) |
| hooks | 568,517 | 5.5% | +27,243 (+5.0%) |
| memory | 529,079 | 5.1% | +82,321 (+18.4%) |
| briefing | 150,069 | 1.5% | +31,088 (**+26.1%** — delta breach) |
| jtbd | 57,916 | 0.6% | +1,969 (+3.5%) |
| project-claude-md | 5,897 | 0.06% | 0 (0%) |
| framework-injected | not measured | — | reason=framework-injected-no-on-disk-source |

## Per-Plugin Decomposition

### Hooks (aggregate from cheap layer: 568,517 bytes)

| Plugin | Bytes | % of hooks |
|--------|-------|------------|
| itil | 172,716 | 30.4% |
| risk-scorer | 112,682 | 19.8% |
| architect | 68,821 | 12.1% |
| voice-tone | 60,087 | 10.6% |
| jtbd | 39,893 | 7.0% |
| shared | 38,268 | 6.7% |
| tdd | 27,871 | 4.9% |
| style-guide | 24,305 | 4.3% |
| retrospective | 21,818 | 3.8% |
| connect | 2,056 | 0.4% |

(Sum = 568,517 — matches the cheap-layer `hooks` aggregate.)

### Skills (aggregate from cheap layer: 1,317,740 bytes)

| Plugin | Bytes | % of skills |
|--------|-------|-------------|
| itil | 984,650 | 74.7% |
| retrospective | 118,136 | 9.0% |
| risk-scorer | 73,716 | 5.6% |
| architect | 65,063 | 4.9% |
| jtbd | 21,702 | 1.6% |
| wardley | 11,926 | 0.9% |
| connect | 11,434 | 0.9% |
| voice-tone | 10,119 | 0.8% |
| style-guide | 3,895 | 0.3% |
| tdd | 3,369 | 0.3% |
| c4 | 660 | 0.05% |

(Sum = 1,304,570 vs cheap-layer aggregate 1,317,740 — the ~13KB residual is the newly-added `risk-scorer/agents/eval/` this iter, which lives under `agents/`, not `skills/`, and is counted in the skills bucket by the cheap-layer measure but not by the per-`skills/`-dir plugin walk. Sanity-checked, not a defect.)

## Top-N Offenders

| Surface | Bytes | Bucket | Comparable prior |
|---------|-------|--------|------------------|
| `docs/problems/` corpus | 5,573,804 | problems | P282 (V→Closed inline-validation) reclaimed README read-cost via per-state subdir migration (ADR-031); no full-corpus archival prior |
| `docs/decisions/` corpus | 2,097,092 | decisions | not estimated — no prior data (ADR compendium is append-only governance history) |
| `packages/itil/skills/work-problems/SKILL.md` | 236,536 | skills | P097 (SKILL.md >50KB budget cluster) — evolving budget anchor, no reclamation prior |
| `packages/itil/skills/manage-problem/SKILL.md` | 145,718 | skills | P097 |
| `packages/retrospective/skills/run-retro/SKILL.md` | 93,824 | skills | P097 |

## Per-Turn Attribution

per-turn attribution: not measured — no session log accessible (`.afk-run-state/*.jsonl` holds only `outstanding-questions.jsonl` + `risk-register-queue.jsonl`, neither carries per-turn `usage` fields).

## Suggestions

1. **problems (54.1% of measured, +378KB since 2026-06-17)** — the `docs/problems/` corpus is the single largest and fastest-growing bucket. Closed tickets under `docs/problems/closed/` are read only on explicit audit; an archival-tier (git-tracked but excluded from the SessionStart/reconcile read paths) would cut the routine read cost. Comparable prior: P282 moved verifying/closed into per-state subdirs (ADR-031) to bound README read-cost. Estimated byte saving: not estimated — no full-corpus-archival prior exists; a scoped measurement (bytes under `closed/`) would ground it.
2. **decisions (20.4%, +137KB)** — the ADR corpus is append-only governance history; growth is expected and not trim-worthy per se. No action beyond continued compendium discipline (ADR-077/078). Estimated byte saving: not estimated — no prior data.
3. **memory (5.1%, +18.4% — second-fastest grower)** — the auto-memory MEMORY.md index + per-fact files grew notably. Comparable prior: the signal-vs-noise decay model (P105) trims briefing; no equivalent decay pass exists for memory files. A periodic memory-relevance sweep (dedupe superseded feedback_* notes) is a candidate. Estimated byte saving: not estimated — no prior data.
4. **briefing (delta-breach +26.1%)** — three topic files are over the Tier-3 5,120-byte ceiling (see Policy Breaches). The run-retro Step 3 Tier-3 rotation pass is the standing remediation surface (split-by-date / split-by-subtopic). Comparable prior: P100 split the monolithic BRIEFING.md into per-topic files.

## Policy Breaches

| Budget | Offender | Bytes | Citation |
|--------|----------|-------|----------|
| ADR-040 Tier 3 (≤5,120 B/topic) | `docs/briefing/changeset-holding-graduation.md` | 7,743 | `check-briefing-budgets.sh` OVER |
| ADR-040 Tier 3 | `docs/briefing/governance-workflow.md` | 6,422 | `check-briefing-budgets.sh` OVER |
| ADR-040 Tier 3 | `docs/briefing/agent-interaction-patterns.md` | 6,092 | `check-briefing-budgets.sh` OVER |
| ADR-038 SKILL.md >50KB (P097) | `packages/itil/skills/work-problems/SKILL.md` | 236,536 | P097 evolving budget anchor |
| ADR-038 SKILL.md >50KB (P097) | `packages/itil/skills/manage-problem/SKILL.md` | 145,718 | P097 |
| ADR-038 SKILL.md >50KB (P097) | `packages/retrospective/skills/run-retro/SKILL.md` | 93,824 | P097 |
| ADR-038 SKILL.md >50KB (P097) | `packages/itil/skills/review-problems/SKILL.md` | 76,735 | P097 |

None of the breaches are new-this-iter; all are tracked (P097 SKILL.md cluster; ADR-040 Tier-3 briefing rotation is the run-retro Step 3 standing surface). The three briefing OVER files are routed to Step 3 Tier-3 rotation this retro.

<!--
context-snapshot:
  total-bytes: 10300114
  hooks: 568517
  skills: 1317740
  memory: 529079
  briefing: 150069
  decisions: 2097092
  problems: 5573804
  jtbd: 57916
  project-claude-md: 5897
  framework-injected: not measured
  measurement-method: byte-count-on-disk
  measured-at: 2026-07-03
-->
