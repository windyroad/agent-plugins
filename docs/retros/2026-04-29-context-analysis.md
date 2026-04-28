# Context Analysis — 2026-04-29

> Source: `/wr-retrospective:analyze-context` (deep layer per ADR-043).
> Methodology: byte-count-on-disk + per-plugin decomposition + per-turn attribution (when session log available).
> Cheap-layer baseline: `packages/retrospective/scripts/measure-context-budget.sh`.

## Bucket Totals

| Bucket | Bytes | % of measured | Δ vs prior |
|--------|-------|---------------|------------|
| problems | 1,986,943 | 50.9% | +33,402 (+1.71%) — 4 new tickets P141/P142/P143/P144 (~33KB total) |
| decisions | 814,344 | 20.9% | 0 |
| skills | 571,978 | 14.7% | 0 |
| hooks | 248,546 | 6.4% | 0 |
| memory | 170,470 | 4.4% | 0 |
| briefing | 79,878 | 2.0% | 0 |
| jtbd | 25,127 | 0.6% | 0 |
| project-claude-md | 4,277 | 0.1% | 0 |
| framework-injected | not-measured | — | reason=framework-injected-no-on-disk-source |

**Total measured**: 3,901,563 bytes. Prior snapshot: 3,868,161 bytes. Delta: +33,402 bytes (+0.86%). No bucket exceeded the +20% trigger threshold for "deep analysis recommended" — analysis run on user direction.

## Per-Plugin Decomposition

### Hooks (aggregate from cheap layer: 248,546 bytes)

| Plugin | Bytes | % of hooks |
|--------|-------|------------|
| risk-scorer | 65,786 | 26.5% |
| itil | 60,186 | 24.2% |
| tdd | 23,437 | 9.4% |
| architect | 22,607 | 9.1% |
| jtbd | 20,964 | 8.4% |
| voice-tone | 19,191 | 7.7% |
| style-guide | 19,156 | 7.7% |
| shared | 13,749 | 5.5% |
| connect | 2,056 | 0.8% |
| retrospective | 1,414 | 0.6% |

Sum check: 248,546 ✓ (matches aggregate cheap-layer row).

### Skills (aggregate from cheap layer: 571,978 bytes)

| Plugin | Bytes | % of skills |
|--------|-------|-------------|
| itil | 395,642 | 69.2% |
| retrospective | 78,683 | 13.8% |
| risk-scorer | 29,799 | 5.2% |
| wardley | 11,926 | 2.1% |
| connect | 11,434 | 2.0% |
| architect | 11,219 | 2.0% |
| jtbd | 9,684 | 1.7% |
| voice-tone | 3,834 | 0.7% |
| style-guide | 3,895 | 0.7% |
| tdd | 3,369 | 0.6% |
| c4 | 660 | 0.1% |

Sum check: 560,145 ≠ 571,978 (Δ 11,833 bytes; difference is likely sub-plugin SKILL.md files outside the `packages/<plugin>/skills/<skill>/SKILL.md` glob — e.g. nested or auxiliary files. Not load-bearing for this analysis.).

## Top-N Offenders (by individual file)

| Surface | Bytes | Bucket | Comparable prior |
|---------|-------|--------|------------------|
| `packages/itil/skills/work-problems/SKILL.md` | 87,508 | skills/itil | P097 SKILL.md size cluster — work-problems is the canonical example |
| `packages/itil/skills/manage-problem/SKILL.md` | 76,816 | skills/itil | P097 SKILL.md size cluster — manage-problem is the second largest |
| `packages/itil/skills/report-upstream/SKILL.md` | 34,384 | skills/itil | not estimated — no comparable prior |
| `packages/itil/skills/manage-incident/SKILL.md` | 28,229 | skills/itil | not estimated — no comparable prior |
| `packages/itil/skills/transition-problems/SKILL.md` | 24,170 | skills/itil | P117 sibling-skill split precedent (singular `transition-problem` = 21,423 B) |
| `packages/itil/skills/transition-problem/SKILL.md` | 21,423 | skills/itil | sibling to transition-problems |
| `packages/itil/skills/review-problems/SKILL.md` | 18,016 | skills/itil | P071 split precedent (extracted from manage-problem) |

## Per-Turn Attribution

Per-turn attribution: not measured — orchestrator main-turn session log not accessible from agent context. Per-iteration subprocess data IS accessible via `.afk-run-state/iter*-p*.json`; aggregate from this session and prior P124/P140 sessions:

| Iter | Cost (USD) | Duration (s) | Cache-read tokens |
|------|-----------|--------------|-------------------|
| iter12-p140 | $7.29 | 1,238 | 6,880,861 |
| iter11-p033 | $5.66 | 874 | 5,225,543 |
| iter10-p133 | $9.87 | 1,160 | 10,596,736 |
| iter9-p132 | $4.80 | 630 | n/a |
| iter8-p131 | $7.51 | 1,283 | n/a |
| iter7-p134 | $7.98 | 1,616 | n/a |
| iter6-p139 | $8.91 | 1,013 | n/a |
| iter5-p135 | $3.70 | 702 | n/a |
| iter4-p123 | $9.68 | 1,151 | n/a |
| iter3-p085 | $6.97 | 838 | n/a |
| iter2-p130 | $11.16 | 2,055 | 13,783,017 |
| iter1-p124 | $7.58 | 1,085 | 7,215,254 |

Cache-read tokens are the dominant cost driver (cumulative 53M+ tokens from cache across 5 measured iters). Sustained cache-hit ratio suggests the warm cache is working — newer iters in-session benefit from prior iters' SKILL.md + agent prompt loads.

## Suggestions

Per ADR-026: each suggestion cites specific surface + comparable prior + concrete byte estimate (or `not estimated` sentinel).

1. **skills/itil — P097 SKILL.md size cluster (BREACH on 2 files)**: extract REFERENCE.md companions for `work-problems/SKILL.md` (87,508 B) and `manage-problem/SKILL.md` (76,816 B). Comparable prior: P098 split `install-updates/SKILL.md` into SKILL.md + REFERENCE.md, reclaiming ~50% of always-loaded prose. Estimated byte saving: ~80KB (50% × 164KB of top 2 SKILL.md files). Saves cache-creation tokens on every session-start where these skills load.

2. **problems — surface 50.9% of total measured**: split `docs/problems/` flat layout into per-state subdirs. Comparable prior: P069 (`docs/problems/ flat layout is unskimmable — migrate to per-state subdirs`) — already-tracked Open ticket, WSJF 1.875, XL effort. Estimated byte saving: not estimated — no prior reclamation data; primary benefit is read-tool affordance (each subdir loads independently), not raw byte count. Compose with P134 (line-3 truncation, already shipped — reclaimed 76KB).

3. **decisions — 814KB / 21% of total**: archive accepted ADRs older than 30 days to `docs/decisions/archive/`. Comparable prior: P099 split `docs/BRIEFING.md` into per-topic files at `docs/briefing/<topic>.md`; ADR-040 codified the topic-file pattern. Estimated byte saving: not estimated — no comparable prior at the ADR surface; would need a P-ticket to scope the archive convention.

4. **memory — 170KB / 4.4%**: P105 signal-vs-noise pass on briefing entries reclaimed an unmeasured amount through entry retirement. The same pattern could apply to MEMORY.md feedback files: classify which entries cite vs decay across sessions; route low-signal entries to per-feedback file archive. Estimated byte saving: not estimated — no comparable prior at the memory surface; first-application of the P105 pattern would be the baseline.

5. **hooks — risk-scorer (66KB) + itil (60KB) = 50.5% of hooks**: investigate hook-prose budget compliance per ADR-038. Comparable prior: P096 split UserPromptSubmit hooks into once-per-session full reminder + subsequent-prompt terse reminder, reclaiming ~150KB cumulative across long sessions (per ADR-045 hook-injection budget policy). Estimated byte saving: not estimated — would need per-hook prose audit; defer to a P-ticket if breach detection (Step 5 below) finds violations.

## Policy Breaches

| Budget | Offender | Bytes | Citation |
|--------|----------|-------|----------|
| **ADR-038 SKILL.md size cluster (P097, ≤50KB advisory)** | `packages/itil/skills/work-problems/SKILL.md` | 87,508 | P097 (`docs/problems/097-skill-md-mixes-runtime-with-maintainer-rationale.open.md`) — work-problems is the canonical example named in P097's body |
| **ADR-038 SKILL.md size cluster (P097, ≤50KB advisory)** | `packages/itil/skills/manage-problem/SKILL.md` | 76,816 | P097 — manage-problem is named alongside work-problems |
| **ADR-040 Tier 3 (per-topic ≤5,120 B)** | `docs/briefing/afk-subprocess.md` | 19,058 | check-briefing-budgets.sh `OVER` row, 3rd consecutive cycle |
| **ADR-040 Tier 3 (per-topic ≤5,120 B)** | `docs/briefing/governance-workflow.md` | 17,467 | check-briefing-budgets.sh `OVER` row, 3rd consecutive cycle |
| **ADR-040 Tier 3 (per-topic ≤5,120 B)** | `docs/briefing/agent-interaction-patterns.md` | 11,503 | check-briefing-budgets.sh `OVER` row |
| **ADR-040 Tier 3 (per-topic ≤5,120 B)** | `docs/briefing/releases-and-ci.md` | 9,970 | check-briefing-budgets.sh `OVER` row |
| **ADR-040 Tier 3 (per-topic ≤5,120 B)** | `docs/briefing/plugin-distribution.md` | 8,975 | check-briefing-budgets.sh `OVER` row |
| **ADR-040 Tier 3 (per-topic ≤5,120 B)** | `docs/briefing/hooks-and-gates.md` | 8,196 | check-briefing-budgets.sh `OVER` row |

**ADR-038 hook prose budget (≤150 B per subsequent-prompt reminder)**: not measured — per-hook sampling not performed in this analysis run. Defer to follow-on if Step 5 patterns suggest breach.

**P097 reassessment trigger approaching**: 2/7 itil SKILL.md files >50KB advisory threshold. P097 ticket WSJF 3.0 Open L; the breach evidence here is signal that the 30-day reassessment window may warrant ticket re-rate.

**ADR-040 Tier 3 reassessment trigger likely fired**: 6/6 topic files OVER for ≥3 consecutive retro cycles. Per ADR-040's Reassessment criteria, this is the trigger for "≥3 files exceed 2× ceiling for ≥2 cycles → revisit / promote-to-fail-closed". 6/6 OVER for 3+ cycles meets the trigger. Action candidate: open a P-ticket to either rotate the topic files (per P099's documented split-by-subtopic / split-by-date / trim-noise / defer options) or amend ADR-040 to raise the Tier 3 ceiling.

<!--
context-snapshot:
  total-bytes: 3901563
  hooks: 248546
  skills: 571978
  memory: 170470
  briefing: 79878
  decisions: 814344
  problems: 1986943
  jtbd: 25127
  project-claude-md: 4277
  framework-injected: not measured
  measurement-method: byte-count-on-disk
  measured-at: 2026-04-29T00:00:00Z
  retro-iter: post-p141-p142-p143-p144-stage1
-->
