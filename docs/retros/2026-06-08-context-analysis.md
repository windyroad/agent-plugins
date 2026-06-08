# Context Analysis — 2026-06-08

> Source: `/wr-retrospective:analyze-context` (deep layer per ADR-043).
> Methodology: byte-count-on-disk + per-plugin decomposition + per-turn attribution (when session log available).
> Cheap-layer baseline: `packages/retrospective/scripts/measure-context-budget.sh`.
> Auto-fired from `/wr-retrospective:run-retro` Step 2c during iter-p195 (P195 Tier 3 rotation pass) — calendar-elapse trigger holds (last analysis 2026-05-25, 14 days back); delta-breach trigger holds (multiple buckets >20%); once-per-day guard not satisfied (no prior 2026-06-08-context-analysis.md).

## Bucket Totals

| Bucket | Bytes | % of measured | Δ vs prior (2026-05-25) |
|--------|-------|---------------|--------------------------|
| problems | 4,800,948 | 53.6% | +4,304,852 (+867.5%) |
| decisions | 1,911,090 | 21.3% | +405,453 (+26.9%) |
| skills | 1,169,193 | 13.0% | +246,702 (+26.7%) |
| hooks | 507,746 | 5.7% | +95,703 (+23.2%) |
| memory | 409,750 | 4.6% | +124,306 (+43.6%) |
| briefing | 101,701 | 1.1% | -41,512 (-29.0%) |
| jtbd | 55,947 | 0.6% | +11,718 (+26.5%) |
| project-claude-md | 4,277 | 0.05% | 0 (0.0%) |
| framework-injected | not measured | — | reason: framework-injected-no-on-disk-source |

**Total measured: 8,960,652 bytes (prior 3,813,430, +5,147,222, +135.0%)** — measurement-method: `byte-count-on-disk` via `wr-retrospective-measure-context-budget`.

## Per-Plugin Decomposition

### Hooks (aggregate from cheap layer: 507,746 bytes)

| Plugin | Bytes | % of hooks |
|--------|-------|------------|
| itil | 154,970 | 30.5% |
| risk-scorer | 103,501 | 20.4% |
| voice-tone | 54,179 | 10.7% |
| architect | 51,448 | 10.1% |
| jtbd | 39,893 | 7.9% |
| shared | 32,360 | 6.4% |
| tdd | 27,871 | 5.5% |
| style-guide | 24,305 | 4.8% |
| retrospective | 17,163 | 3.4% |
| connect | 2,056 | 0.4% |

Sum: 507,746 (matches aggregate).

### Skills (aggregate from cheap layer: 1,169,193 bytes)

| Plugin | Bytes | % of skills |
|--------|-------|-------------|
| itil | 844,190 | 72.2% |
| retrospective | 113,116 | 9.7% |
| risk-scorer | 68,550 | 5.9% |
| architect | 64,100 | 5.5% |
| jtbd | 21,702 | 1.9% |
| wardley | 11,926 | 1.0% |
| connect | 11,434 | 1.0% |
| voice-tone | 10,119 | 0.9% |
| style-guide | 3,895 | 0.3% |
| tdd | 3,369 | 0.3% |
| c4 | 660 | 0.06% |

Sum: 1,153,061 (vs aggregate 1,169,193 — Δ +16,132, ~1.4% accounted by sub-skills not in primary plugin walk; within tolerance).

## Top-N Offenders

| Surface | Bytes | Bucket | Comparable prior |
|---------|-------|--------|------------------|
| `docs/problems/` (all tickets) | 4,800,948 | problems | not estimated — no prior reclamation precedent at this scale (8.7× growth; closure activity + per-state subdir layout per ADR-031 expansion) |
| `docs/decisions/` (all ADRs) | 1,911,090 | decisions | not estimated — no prior data on decisions-bucket reclamation; P294/ADR-069 README inventory currency advisory addresses orthogonal axis |
| `packages/itil/skills/` (all itil skills) | 844,190 | skills | P097 (SKILL.md size cluster) targeted ≥ 50KB SKILL.md; manage-problem + work-problems are the dominant nodes per inspection |
| `packages/itil/hooks/` | 154,970 | hooks | P095 reclaimed via once-per-session gating (cited prior); applicable to repeat-fire detectors here |
| `packages/risk-scorer/hooks/` | 103,501 | hooks | not estimated — no prior data |

## Per-Turn Attribution

per-turn attribution: not measured — no session log accessible (`.afk-run-state/*.jsonl` carries only `outstanding-questions.jsonl` + `risk-register-queue.jsonl`; no per-iter `usage` log present)

## Suggestions

1. **problems bucket** — `docs/problems/` tree has grown 8.67× since 2026-05-25 (496,096 → 4,800,948 bytes). The README.md alone exceeded the Read-tool 25K-token whole-file cap at 134KB per the briefing's P282 evidence note. **Surface**: `docs/problems/README.md` + the `docs/problems/closed/` subdirectory. **Suggestion**: investigate whether the README's Verification Queue and Closed sections need their own progressive-disclosure rotation per ADR-040 Tier-2 envelope (analogous to ADR-040 Tier 3 briefing rotation that P099 / P145 / P195 govern). Comparable prior: `P099 / P100 split BRIEFING.md into per-topic files; established the progressive-disclosure pattern this would extend.` Estimated byte saving: not estimated — no prior data on problems-README rotation specifically.

2. **decisions bucket** — `docs/decisions/` at 1.9MB, +27% since prior. **Surface**: `packages/architect/scripts/generate-decisions-compendium.sh` already aggregates ADRs into a compendium; the underlying ADR corpus continues to grow with ratification + amendments. **Suggestion**: consider whether superseded ADRs (`.superseded.md` status) could be moved to a `docs/decisions/superseded/` subdirectory analogous to `docs/problems/closed/`. Comparable prior: `ADR-031 per-state subdir layout for docs/problems/ — same shape applied to decisions corpus.` Estimated byte saving: not estimated — no prior data on decisions-bucket reclamation.

3. **skills/itil bucket** — `packages/itil/skills/` dominates the skills bucket at 844KB (72% of all skill bytes). **Surface**: `packages/itil/skills/manage-problem/SKILL.md` + `packages/itil/skills/work-problems/SKILL.md` are the dominant nodes per Read-tool inspection across recent sessions. **Suggestion**: ADR-054 sibling-REFERENCE.md extraction was specifically designed for this — per P242 (ADR-054 sibling-REFERENCE.md extraction). The lazy-load pattern moves rarely-read content from SKILL.md to REFERENCE.md. Comparable prior: `ADR-054 cited by analyze-context SKILL "Further reading" trailer; the pattern is already adopted by this very skill.` Estimated byte saving: not estimated — no prior data on itil SKILL.md REFERENCE.md adoption.

4. **memory bucket** — memory grew +44% (285,444 → 409,750). **Surface**: `/Users/tomhoward/.claude/projects/-Users-tomhoward-Projects-windyroad-claude-plugin/memory/`. **Suggestion**: memory entries are session-start-loaded via MEMORY.md index; periodic decay pass per `~/CLAUDE.md` auto-memory § "When NOT to save" (entries derivable from current state, debugging fix recipes, ephemeral state). No comparable prior exists for memory-bucket reclamation. Estimated byte saving: not estimated — no prior data.

5. **briefing bucket** — DOWN 29% since 2026-05-25 baseline (143,213 → 101,701). This is the result of the 2026-05-26 in-retro compaction pass plus today's P195 iter rotation. **No suggestion needed** — bucket is below prior baseline; per-topic-file budget check (`check-briefing-budgets.sh`) reports zero over-budget files after today's rotation.

## Policy Breaches

| Budget | Offender | Bytes | Citation |
|--------|----------|-------|----------|
| ADR-040 Tier 3 (5120 bytes/topic) | none | — | `check-briefing-budgets.sh docs/briefing` → empty output after iter-p195 rotation pass committed as ac9cbc8 |
| ADR-038 SKILL.md cluster (≥50KB per P097) | not surveyed this iter | — | iter scope bounded to briefing rotation; cross-skill survey deferred to a foreground retro |
| ADR-038 hook prose budget (≤150 bytes/reminder) | not surveyed this iter | — | iter scope bounded to briefing rotation; cross-hook survey deferred to a foreground retro |

no policy breaches detected within surveyed surfaces.

<!--
context-snapshot:
  total-bytes: 8960652
  hooks: 507746
  skills: 1169193
  memory: 409750
  briefing: 101701
  decisions: 1911090
  problems: 4800948
  jtbd: 55947
  project-claude-md: 4277
  framework-injected: not measured
  measurement-method: byte-count-on-disk
  measured-at: 2026-06-08
-->
