# Context Analysis — 2026-08-29

> Source: `/wr-retrospective:analyze-context` (deep layer per ADR-043).
> Methodology: byte-count-on-disk + per-plugin decomposition. Per-turn attribution was not available (see that section).
> Cheap-layer baseline: `wr-retrospective-measure-context-budget`.
> Auto-fired from `run-retro` Step 2c: 2026-08-20 was the latest snapshot, so the calendar axis exceeded 14 days.

## Bucket Totals

Prior snapshot: the `context-snapshot:` trailer of `docs/retros/2026-08-20-context-analysis.md`.

| Bucket | Bytes | % of measured | Δ vs prior |
|--------|------:|--------------:|-----------:|
| problems | 6,727,954 | 54.22% | +337,911 (+5.29%) |
| decisions | 2,520,991 | 20.32% | +61,435 (+2.50%) |
| skills | 1,368,133 | 11.03% | +5,423 (+0.40%) |
| memory | 761,091 | 6.13% | +47,689 (+6.69%) |
| hooks | 665,765 | 5.37% | +5,451 (+0.83%) |
| briefing | 239,405 | 1.93% | +17,707 (+7.99%) |
| jtbd | 117,702 | 0.95% | +11,822 (+11.17%) |
| project-claude-md | 7,272 | 0.06% | +1,081 (+17.46%) |
| framework-injected | not measured — framework-injected-no-on-disk-source | — | — |

Total measured: 12,408,313 bytes, +488,519 (+4.10%) from the 11,919,794-byte 2026-08-20 snapshot. Measurement method: `wr-retrospective-measure-context-budget .` on 2026-08-29.

## Per-Plugin Decomposition

### Hooks (aggregate from cheap layer: 665,765 bytes)

The plugin rows sum to 665,765 bytes and reconcile with the cheap-layer aggregate.

| Plugin | Bytes | % of hooks |
|--------|------:|-----------:|
| itil | 196,437 | 29.5% |
| risk-scorer | 131,985 | 19.8% |
| architect | 79,654 | 12.0% |
| voice-tone | 65,316 | 9.8% |
| jtbd | 43,624 | 6.6% |
| shared | 43,318 | 6.5% |
| tdd | 31,593 | 4.7% |
| style-guide | 27,980 | 4.2% |
| cruise | 21,984 | 3.3% |
| retrospective | 21,818 | 3.3% |
| connect | 2,056 | 0.3% |

### Skills (aggregate from cheap layer: 1,368,133 bytes)

| Plugin | Bytes | % of attributed skills |
|--------|------:|-----------------------:|
| itil | 1,028,617 | 75.9% |
| retrospective | 119,689 | 8.8% |
| risk-scorer | 75,584 | 5.6% |
| architect | 66,509 | 4.9% |
| jtbd | 21,624 | 1.6% |
| wardley | 12,225 | 0.9% |
| connect | 11,434 | 0.8% |
| voice-tone | 10,473 | 0.8% |
| style-guide | 3,895 | 0.3% |
| tdd | 3,369 | 0.2% |
| cruise | 984 | 0.1% |
| c4 | 660 | 0.0% |

The plugin rows sum to 1,355,063 bytes. The remaining 13,070 bytes are `REFERENCE.md` and evaluation assets counted by the cheap layer's whole-tree walk but not by the attribution helper's `SKILL.md` walk.

## Top-N Offenders

| Surface | Bytes | Bucket | Comparable prior |
|---------|------:|--------|------------------|
| `packages/itil/skills/work-problems/SKILL.md` | 242,685 | skills | P097 (SKILL.md size cluster) — no measured reclamation yet |
| `packages/itil/skills/manage-problem/SKILL.md` | 153,291 | skills | P097 — no measured reclamation yet |
| `packages/retrospective/skills/run-retro/SKILL.md` | 95,311 | skills | P097 — no measured reclamation yet |
| `packages/itil/skills/review-problems/SKILL.md` | 79,174 | skills | P097 — no measured reclamation yet |
| `packages/itil/skills/capture-problem/SKILL.md` | 57,989 | skills | P097 — no measured reclamation yet |

## Per-Turn Attribution

per-turn attribution: not measured — no session log accessible. `.afk-run-state/` contains queue files, not per-turn records with `usage` fields.

## Suggestions

1. **skills / `packages/itil/skills/work-problems/SKILL.md`** — At 242,685 bytes, this file is 17.7% of the skills bucket and 4.7× the 50 KB P097 threshold. ADR-054's established `REFERENCE.md` split is the available progressive-disclosure shape. Estimated byte saving: not estimated — no prior data.
2. **skills / `packages/itil/skills/manage-problem/SKILL.md`** — At 153,291 bytes, this file is 11.2% of the skills bucket and 3.0× the P097 threshold. Reuse ADR-054's `REFERENCE.md` split if P097 prioritises this surface. Estimated byte saving: not estimated — no prior data.
3. **skills / itil aggregate** — The itil plugin contributes 1,028,617 of 1,355,063 attributed skill bytes (75.9%). Per-turn attribution is unavailable, so runtime savings are not estimated — no prior data.
4. **briefing** — The tree is 239,405 bytes, +17,707 (+7.99%) since 2026-08-20. Comparable prior: P100 split the former single briefing into topic files; today's `wr-retrospective-check-briefing-budgets` emitted no `OVER` rows. Estimated byte saving: not estimated — no prior data.
5. **problems** — The corpus is 6,727,954 bytes (54.22% of measured bytes), including a 544,006-byte history and 225,778-byte live index; individual tickets are loaded on demand. Comparable prior: P095 reclaimed about 120 KB through once-per-session gating. No edit is proposed by this measurement-only workflow.

## Policy Breaches

| Budget | Offender | Bytes | Citation |
|--------|----------|------:|----------|
| ADR-038 SKILL.md ≤50 KB (P097) | `packages/itil/skills/work-problems/SKILL.md` | 242,685 | `find packages -path '*/skills/*/SKILL.md' -type f -exec wc -c` |
| ADR-038 SKILL.md ≤50 KB (P097) | `packages/itil/skills/manage-problem/SKILL.md` | 153,291 | same measurement |
| ADR-038 SKILL.md ≤50 KB (P097) | `packages/retrospective/skills/run-retro/SKILL.md` | 95,311 | same measurement |
| ADR-038 SKILL.md ≤50 KB (P097) | `packages/itil/skills/review-problems/SKILL.md` | 79,174 | same measurement |
| ADR-038 SKILL.md ≤50 KB (P097) | `packages/itil/skills/capture-problem/SKILL.md` | 57,989 | same measurement |
| ADR-038 SKILL.md ≤50 KB (P097) | `packages/itil/skills/update-upstream/SKILL.md` | 56,067 | same measurement |
| ADR-038 SKILL.md ≤50 KB (P097) | `packages/itil/skills/report-upstream/SKILL.md` | 53,300 | same measurement |

`wr-retrospective-check-briefing-budgets` emitted no `OVER` rows. ADR-038's ≤150-byte subsequent-prompt reminder budget was not measured — no branch-level hook sampling was performed.

<!--
context-snapshot:
  total-bytes: 12408313
  hooks: 665765
  skills: 1368133
  memory: 761091
  briefing: 239405
  decisions: 2520991
  problems: 6727954
  jtbd: 117702
  project-claude-md: 7272
  framework-injected: not measured
  measurement-method: byte-count-on-disk
  measured-at: 2026-08-29
-->
