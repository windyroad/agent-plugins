# Context Analysis — 2026-05-25

> Source: `/wr-retrospective:analyze-context` (deep layer per ADR-043).
> Methodology: byte-count-on-disk + per-plugin decomposition + per-turn attribution (when session log available).
> Cheap-layer baseline: `packages/retrospective/scripts/measure-context-budget.sh`.
> Prior snapshot: `docs/retros/2026-05-15-context-analysis.md` (10 days / multiple sessions ago; deltas below span that window, not this session alone).

## Bucket Totals

Total measured: **3,813,430 bytes** (~3.81 MB). Prior (2026-05-15): ~3,197,530 bytes → **+615,900 (+19.3%)** over the window.

| Bucket | Bytes | % of measured | Δ vs prior (2026-05-15) |
|--------|-------|---------------|--------------------------|
| decisions | 1,505,637 | 39.5% | +158,800 (+11.8%) |
| skills | 922,491 | 24.2% | +98,654 (+12.0%) |
| problems | 496,096 | 13.0% | **+189,356 (+61.7%)** |
| hooks | 412,043 | 10.8% | **+73,848 (+21.8%)** |
| memory | 285,444 | 7.5% | +68,175 (+31.4%) |
| briefing | 143,213 | 3.8% | +24,110 (+20.2%) |
| jtbd | 44,229 | 1.2% | +2,680 (+6.4%) |
| project-claude-md | 4,277 | 0.1% | not estimated — absent from prior table |
| framework-injected | not measured | — | reason=framework-injected-no-on-disk-source |

Buckets exceeding the +20% deep-analysis trigger: **problems (+61.7%), memory (+31.4%), hooks (+21.8%), briefing (+20.2%)**.

## Per-Plugin Decomposition

### Hooks (aggregate: 412,043 bytes)

| Plugin | Bytes | % of hooks |
|--------|-------|------------|
| itil | 138,060 | 33.5% |
| risk-scorer | 83,822 | 20.3% |
| voice-tone | 46,744 | 11.3% |
| shared | 29,595 | 7.2% |
| tdd | 26,937 | 6.5% |
| architect | 25,346 | 6.2% |
| jtbd | 23,402 | 5.7% |
| style-guide | 19,635 | 4.8% |
| retrospective | 16,446 | 4.0% |
| connect | 2,056 | 0.5% |

### Skills (aggregate: 922,491 bytes)

| Plugin | Bytes | % of skills |
|--------|-------|-------------|
| itil | 663,475 | 71.9% |
| retrospective | 88,890 | 9.6% |
| risk-scorer | 60,987 | 6.6% |
| architect | 40,524 | 4.4% |
| jtbd | 17,054 | 1.8% |
| wardley | 11,926 | 1.3% |
| connect | 11,434 | 1.2% |
| voice-tone | 10,119 | 1.1% |
| style-guide | 3,895 | 0.4% |
| tdd | 3,369 | 0.4% |
| c4 | 660 | 0.1% |

**itil dominates** both axes: 33.5% of hooks + 71.9% of skills. The skills concentration is the dominant loaded-per-invocation surface.

## Top-N Offenders

| Surface | Bytes | Bucket | Comparable prior |
|---------|-------|--------|------------------|
| `packages/itil/skills/work-problems/SKILL.md` | 124,247 | skills/itil | not estimated — no prior data (P097/ADR-054 extraction not yet run; P296 just un-deferred it) |
| `packages/itil/skills/manage-problem/SKILL.md` | 100,309 | skills/itil | not estimated — no prior data |
| `packages/retrospective/skills/run-retro/SKILL.md` | 74,464 | skills/retrospective | not estimated — no prior data |
| `docs/decisions/060-problem-rfc-story-framework-...md` | ~92,688 (per prior snapshot) | decisions | not estimated — no prior data |
| itil hooks (aggregate) | 138,060 | hooks/itil | P095 reclaimed ~120 KB on UserPromptSubmit prose via once-per-session gating (ADR-038); per-tool-call hooks already silent-on-pass per ADR-045 |

## Per-Turn Attribution

per-turn attribution: not measured — no session log accessible (this is an interactive parent session; `.afk-run-state/*.jsonl` holds prior AFK iteration logs, not this session's turn-level usage).

## Suggestions

1. **skills/itil — the 3 P097-breaching SKILL.md files (work-problems 124 KB, manage-problem 100 KB, run-retro 74 KB; ~299 KB combined loaded-per-invocation)** — prioritise the retroactive REFERENCE.md extraction. Comparable prior: P100 split `BRIEFING.md` into per-topic files (reclaimed the single-file budget); ADR-054 codified the SKILL.md runtime budget + content-classification taxonomy. Estimated saving: `not estimated — no prior data` (the extraction has not run; **P296** un-deferred it this session per the user's "deferred work never happens" principle, and **P241/P243** are the cohort umbrellas). This is the single highest-leverage trim target — itil skills are 71.9% of the skills bucket and these three are the bulk.

2. **problems (+61.7%, fastest-growing bucket)** — growth is expected backlog accumulation (this session added P287–P302, 16 tickets). The loaded surface is `docs/problems/README.md`, not the individual ticket bodies; no trim warranted. Comparable prior: not applicable — backlog growth is the work record, not bloat.

3. **briefing (+20.2%, 16 files OVER the 5 KB Tier-3 budget)** — **P195** owns this (archive targets saturated; the per-file rotation mechanism has hit its limit — a systemic-signal recognised in the 2026-05-25 session-start commit). Comparable prior: P145 multi-pass archive rotations reclaimed budget until the archives themselves saturated. Estimated saving: not estimated — the rotation lever is exhausted; P195 must choose a new approach.

4. **memory (+31.4%)** — grew via this session's new notes (project-name, cadence principle) + updates. Memory is loaded at session start (MEMORY.md index is small; individual notes are recall-only). No trim warranted; the index line discipline is holding.

5. **decisions (39.5%, largest bucket, +11.8%)** — the ADR corpus. Not loaded wholesale per session (read on demand). The natural lever is ADR lifecycle archival (superseded ADRs); ADR-060 (~93 KB) is the largest single file. `not estimated — no prior data` for a decisions-specific reclamation prior.

## Policy Breaches

| Budget | Offender | Bytes | Citation |
|--------|----------|-------|----------|
| ADR-038/P097 SKILL.md >50 KB | `packages/itil/skills/work-problems/SKILL.md` | 124,247 | P097 (SKILL.md mixes runtime + rationale); ADR-054 budget; P296 un-deferred extraction |
| ADR-038/P097 SKILL.md >50 KB | `packages/itil/skills/manage-problem/SKILL.md` | 100,309 | P097 / ADR-054 / P241 cohort |
| ADR-038/P097 SKILL.md >50 KB | `packages/retrospective/skills/run-retro/SKILL.md` | 74,464 | P097 / ADR-054 / P241 cohort |
| ADR-040 Tier 3 briefing (≤5 KB/topic) | 16 topic files OVER (none MUST_SPLIT) | — | P195 (systemic saturation; archive targets exhausted) |

<!--
context-snapshot:
  total-bytes: 3813430
  hooks: 412043
  skills: 922491
  memory: 285444
  briefing: 143213
  decisions: 1505637
  problems: 496096
  jtbd: 44229
  project-claude-md: 4277
  framework-injected: not measured
  measurement-method: byte-count-on-disk
  measured-at: 2026-05-25
-->
