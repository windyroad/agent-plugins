# Context Analysis — 2026-07-26

> Source: `/wr-retrospective:analyze-context` (deep layer per ADR-043), auto-fired from `run-retro` Step 2c.
> Trigger: calendar-elapse — prior report is `docs/retros/2026-07-03-context-analysis.md`, 23 days old (>14-day axis).
> Methodology: byte-count-on-disk via `wr-retrospective-measure-context-budget` + per-plugin decomposition via `wr-retrospective-list-plugin-attribution`.

## Bucket Totals

Prior snapshot: the `context-snapshot:` trailer of `docs/retros/2026-07-03-context-analysis.md`.

| Bucket | Bytes | % of measured | Δ vs prior |
|--------|-------|---------------|------------|
| problems | 5,948,212 | 57.7% | +374,408 (+6.7%) |
| decisions | 2,226,557 | 21.6% | +129,465 (+6.2%) |
| skills | 1,332,734 | 12.9% | +14,994 (+1.1%) |
| hooks | 636,988 | 6.2% | +68,471 (+12.0%) |
| memory | 593,921 | 5.8% | +64,842 (+12.3%) |
| briefing | 168,576 | 1.6% | +18,507 (+12.3%) |
| jtbd | 66,501 | 0.6% | +8,585 (+14.8%) |
| project-claude-md | 5,897 | 0.06% | 0 (0.0%) |
| framework-injected | not measured — framework-injected-no-on-disk-source | — | — |

Total measured: 10,979,386 bytes (prior 10,300,114) — **+679,272 (+6.6%) over 23 days**, roughly 29.5 KB/day.

No bucket cleared the delta axis on its own terms this cycle: the largest relative moves (jtbd +14.8%, memory +12.3%, briefing +12.3%, hooks +12.0%) all sit under the 20% threshold, so the calendar axis is what fired. Growth is broad rather than concentrated — every measured bucket except `project-claude-md` grew, and the two largest buckets grew at roughly the same rate as the total.

## Per-Plugin Decomposition

### Hooks (aggregate from cheap layer: 636,988 bytes)

| Plugin | Bytes | % of hooks |
|--------|-------|------------|
| itil | 185,278 | 29.1% |
| risk-scorer | 123,064 | 19.3% |
| architect | 72,964 | 11.5% |
| voice-tone | 64,960 | 10.2% |
| jtbd | 43,666 | 6.9% |
| shared | 42,962 | 6.7% |
| tdd | 31,593 | 5.0% |
| style-guide | 27,980 | 4.4% |
| retrospective | 21,818 | 3.4% |
| cruise | 20,647 | 3.2% |
| connect | 2,056 | 0.3% |

Sum: 636,988 — matches the cheap-layer aggregate exactly.

### Skills (aggregate from cheap layer: 1,332,734 bytes)

| Plugin | Bytes | % of skills |
|--------|-------|-------------|
| itil | 994,366 | 74.6% |
| retrospective | 118,328 | 8.9% |
| risk-scorer | 74,705 | 5.6% |
| architect | 67,822 | 5.1% |
| jtbd | 21,702 | 1.6% |
| wardley | 11,926 | 0.9% |
| connect | 11,434 | 0.9% |
| voice-tone | 10,473 | 0.8% |
| style-guide | 3,895 | 0.3% |
| tdd | 3,369 | 0.3% |
| cruise | 984 | 0.07% |
| c4 | 660 | 0.05% |

Sum: 1,319,664 — 13,070 bytes short of the cheap-layer aggregate (1.0%), the difference being skill files the helper's `SKILL.md`-only walk does not count (`REFERENCE.md` siblings and skill-local `eval/` fixtures).

`@windyroad/itil` is three quarters of all skill bytes and nearly a third of all hook bytes. Any skill-surface trim conversation is an itil conversation.

## Top-N Offenders

| Surface | Bytes | Bucket | Comparable prior |
|---------|-------|--------|------------------|
| `packages/itil/skills/work-problems/SKILL.md` | 231,201 | skills/itil | P100 (split `BRIEFING.md` into per-topic files) reclaimed the equivalent monolith on the briefing tier |
| `packages/itil/skills/manage-problem/SKILL.md` | 145,507 | skills/itil | ADR-054 lazy-loaded `REFERENCE.md` split — already applied to `capture-problem` and `analyze-context` |
| `packages/retrospective/skills/run-retro/SKILL.md` | 93,950 | skills/retrospective | ADR-054 `REFERENCE.md` split |
| `packages/itil/skills/review-problems/SKILL.md` | 79,478 | skills/itil | ADR-054 `REFERENCE.md` split |
| `packages/itil/skills/capture-problem/SKILL.md` | 57,989 | skills/itil | already carries a `REFERENCE.md`; the residual is still over the P097 line |

Five `SKILL.md` files exceed the 50 KB P097 budget line (`find packages -name SKILL.md -size +50k | wc -l` = 5). `update-upstream` (50,333) is the sixth, marginally over.

## Per-Turn Attribution

per-turn attribution: not measured — no session log accessible. `.afk-run-state/` holds only
`outstanding-questions.jsonl` and `risk-register-queue.jsonl`; neither carries per-turn `usage` fields.

## Suggestions

1. **skills/itil — `work-problems/SKILL.md` (231,201 bytes)** — split to a lazy-loaded `REFERENCE.md` sibling per ADR-054, keeping the step sequence and dispatch contract in `SKILL.md` and moving the rationale prose, worked examples, and supersession notes out. Comparable prior: `capture-problem` and `analyze-context` both carry `REFERENCE.md` siblings under the same ADR. Estimated byte saving: `not estimated — no prior data` (no `SKILL.md`/`REFERENCE.md` split in this repo has been measured before and after).
2. **skills/itil — `manage-problem/SKILL.md` (145,507 bytes)** — same split. This file is read in full by every problem-working iteration, so it is the highest-frequency read of the five. Estimated byte saving: `not estimated — no prior data`.
3. **problems (5,948,212 bytes, 57.7% of measured)** — the dominant bucket and the fastest-growing in absolute terms (+374 KB in 23 days). Growth is inflow, not bloat: the backlog is ~80 open/known-error tickets plus a large closed archive. The lever is not trimming ticket prose but closing tickets — the Verification Queue drains that `run-retro` Step 4a and `transition-problem` perform are what bound this bucket. Comparable prior: the 2026-07-26 batch closes (43 + 20 + 5 verifying tickets across three commits). Estimated byte saving: `not estimated — no prior data` (the closes moved files between subdirectories rather than removing bytes, so no reclamation was measured).
4. **decisions (2,226,557 bytes, +129 KB)** — 21.6% of measured context and growing at 5.6 KB/day. `docs/decisions/README.md` is the compendium surface that keeps this readable without loading every ADR; no trim is proposed. Estimated byte saving: `not estimated — no prior data`.
5. **hooks/itil (185,278 bytes, 29.1% of hooks)** — hooks grew 12% this cycle, the joint-fastest relative mover. Every `PreToolUse` hook runs on every matching tool call, so hook bytes are execution cost as well as source cost. Worth watching rather than acting on: no single hook dominates, and the growth reflects new gates shipping. Estimated byte saving: `not estimated — no prior data`.

## Policy Breaches

| Budget | Offender | Bytes | Citation |
|--------|----------|-------|----------|
| P097 / ADR-038 — `SKILL.md` ≤ 50 KB | `packages/itil/skills/work-problems/SKILL.md` | 231,201 | 4.6× the line |
| P097 / ADR-038 — `SKILL.md` ≤ 50 KB | `packages/itil/skills/manage-problem/SKILL.md` | 145,507 | 2.9× the line |
| P097 / ADR-038 — `SKILL.md` ≤ 50 KB | `packages/retrospective/skills/run-retro/SKILL.md` | 93,950 | 1.9× the line |
| P097 / ADR-038 — `SKILL.md` ≤ 50 KB | `packages/itil/skills/review-problems/SKILL.md` | 79,478 | 1.6× the line |
| P097 / ADR-038 — `SKILL.md` ≤ 50 KB | `packages/itil/skills/capture-problem/SKILL.md` | 57,989 | 1.2× the line |
| P097 / ADR-038 — `SKILL.md` ≤ 50 KB | `packages/itil/skills/update-upstream/SKILL.md` | 50,333 | marginally over |

ADR-040 Tier 3 briefing budgets: `check-briefing-budgets.sh` reported one `OVER` row this cycle
(`afk-subprocess.md` at 5,858 bytes against a 5,120 threshold), rotated split-by-date during
`run-retro` Step 3 and now clean at 4,527 bytes. No `MUST_SPLIT` rows.

ADR-038 hook prose budget (≤150 bytes per subsequent-prompt reminder): not sampled this cycle —
`not measured — deep-layer hook-branch sampling not run`.

<!--
context-snapshot:
  total-bytes: 10979386
  hooks: 636988
  skills: 1332734
  memory: 593921
  briefing: 168576
  decisions: 2226557
  problems: 5948212
  jtbd: 66501
  project-claude-md: 5897
  framework-injected: not measured
  measurement-method: byte-count-on-disk
  measured-at: 2026-07-26
-->
