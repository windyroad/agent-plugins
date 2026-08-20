# Context Analysis — 2026-08-20

> Source: `/wr-retrospective:analyze-context` (deep layer per ADR-043).
> Methodology: byte-count-on-disk + per-plugin decomposition. Per-turn attribution not available this cycle (see that section).
> Cheap-layer baseline: `packages/retrospective/scripts/measure-context-budget.sh`.
> Auto-fired from `run-retro` Step 2c: calendar axis (25 days since the 2026-07-26 snapshot, threshold 14) AND delta axis (three buckets cleared both the 20% and the 10 KB floor).

## Bucket Totals

Prior snapshot: the `context-snapshot:` trailer of `docs/retros/2026-07-26-context-analysis.md`.

| Bucket | Bytes | % of measured | Δ vs prior |
|--------|-------|---------------|------------|
| problems | 6,390,043 | 53.6% | +441,831 (+7.4%) |
| decisions | 2,459,556 | 20.6% | +232,999 (+10.5%) |
| skills | 1,362,710 | 11.4% | +29,976 (+2.2%) |
| memory | 713,402 | 6.0% | **+119,481 (+20.1%)** |
| hooks | 660,314 | 5.5% | +23,326 (+3.7%) |
| briefing | 221,698 | 1.9% | **+53,122 (+31.5%)** |
| jtbd | 105,880 | 0.9% | **+39,379 (+59.2%)** |
| project-claude-md | 6,191 | 0.05% | +294 (+5.0%) |
| framework-injected | not measured — framework-injected-no-on-disk-source | — | — |

Total measured: 11,919,794 bytes (prior 10,979,386) — **+940,408 (+8.6%) over 25 days**, roughly 37.6 KB/day.

The prior cycle ran at 29.5 KB/day, so the accumulation rate rose about 27%. Three buckets cleared both delta gates (bold above); the prior cycle had none, and fired on the calendar axis alone.

**`jtbd` at +59.2% is the standout.** It nearly doubled off a small base (66,501 → 105,880). It remains 0.9% of the corpus, so it is not a context problem yet — it is recorded here because a bucket growing at 4× the total's rate is the shape that becomes one, and because two jobs still lack human oversight per this session's SessionStart nudge.

**`briefing` at +31.5% is the one to watch on its own terms.** The briefing tree is loaded at every session start, so its bytes are paid on every session rather than on demand. It grew 53 KB in 25 days while its own Tier 3 rotation pass reports only two files over budget — meaning growth is spread across many files, each individually compliant.

## Per-Plugin Decomposition

### Hooks (aggregate from cheap layer: 660,314 bytes)

Per-plugin rows sum to exactly 660,314 — the decomposition reconciles with the cheap layer.

| Plugin | Bytes | % of hooks |
|--------|-------|------------|
| itil | 191,939 | 29.1% |
| risk-scorer | 131,032 | 19.8% |
| architect | 79,654 | 12.1% |
| voice-tone | 65,316 | 9.9% |
| jtbd | 43,624 | 6.6% |
| shared | 43,318 | 6.6% |
| tdd | 31,593 | 4.8% |
| style-guide | 27,980 | 4.2% |
| cruise | 21,984 | 3.3% |
| retrospective | 21,818 | 3.3% |
| connect | 2,056 | 0.3% |

### Skills (aggregate from cheap layer: 1,362,710 bytes)

| Plugin | Bytes | % of skills |
|--------|-------|-------------|
| itil | 1,024,555 | 75.2% |
| retrospective | 118,328 | 8.7% |
| risk-scorer | 75,584 | 5.5% |
| architect | 66,509 | 4.9% |
| jtbd | 21,624 | 1.6% |
| wardley | 12,225 | 0.9% |
| connect | 11,434 | 0.8% |
| voice-tone | 10,473 | 0.8% |
| style-guide | 3,895 | 0.3% |
| tdd | 3,369 | 0.2% |
| cruise | 984 | 0.07% |
| c4 | 660 | 0.05% |
| *unattributed* | *13,070* | *1.0%* |

**Reconciliation note.** The per-plugin rows sum to 1,349,640, which is 13,070 bytes short of the cheap layer's 1,362,710. The hooks decomposition reconciles exactly, so the gap is specific to the skills walk: `wr-retrospective-list-plugin-attribution` measures `SKILL.md` files, while the cheap layer's `skills` bucket measures the whole `packages/*/skills/` tree, which also holds `REFERENCE.md` and eval fixtures. The 1.0% residual is recorded rather than silently absorbed into a plugin row.

## Top-N Offenders

| Surface | Bytes | Bucket | Comparable prior |
|---------|-------|--------|------------------|
| `packages/itil/skills/work-problems/SKILL.md` | 231,908 | skills | P097 (SKILL.md size cluster) — no reclamation landed yet |
| `packages/itil/skills/manage-problem/SKILL.md` | 145,781 | skills | P097 — same |
| `packages/retrospective/skills/run-retro/SKILL.md` | 93,950 | skills | P097 — same |
| `packages/itil/skills/review-problems/SKILL.md` | 79,461 | skills | P097 — same |
| `packages/itil/skills/capture-problem/SKILL.md` | 57,989 | skills | P097 — same |

The top five are all `SKILL.md` bodies, and all five sit in the two plugins that dominate the skills bucket. `itil` alone is 75.2% of all skill bytes; its four largest skills are 515,139 bytes, which is 37.8% of the entire skills bucket across every plugin.

## Per-Turn Attribution

per-turn attribution: not measured — no session log accessible. The two files under `.afk-run-state/` this cycle (`outstanding-questions.jsonl`, `risk-register-queue.jsonl`) are orchestrator queues, not per-turn `usage` logs; this session ran interactively rather than under an AFK orchestrator, so no turn-level token record was produced.

## Suggestions

1. **skills / `packages/itil/skills/work-problems/SKILL.md`** — At 231,908 bytes this is 17.0% of the entire skills bucket in one file, and 4.5× the 50 KB P097 threshold. ADR-054's SKILL.md runtime-budget policy and ADR-038's progressive disclosure both prescribe the same shape: move rationale, worked examples, and supersession history into a lazy-loaded `REFERENCE.md`, leaving the executable contract in `SKILL.md`. Comparable prior: `not estimated — no prior data` (P097 is open with no reclamation landed, so no measured saving exists to anchor against). The `run-retro` SKILL.md this report was produced under carries its own `REFERENCE.md` split already, which is the shape to copy.

2. **skills / `itil` plugin aggregate** — `itil` holds 1,024,555 of 1,362,710 skill bytes (75.2%). Four skills account for 515,139 of that. Comparable prior: `not estimated — no prior data`. The concentration is the finding; whether it is a problem depends on how many of those four load in a typical session, which per-turn attribution would answer and this cycle could not.

3. **briefing** — 221,698 bytes, +31.5% this cycle, and paid at every session start rather than on demand. Comparable prior: **P100 split the single `docs/BRIEFING.md` into per-topic files**, which is why only two files are over the Tier 3 ceiling today despite the tree growing 53 KB in 25 days. That split converted a single-file budget problem into a per-file one; the growth rate suggests the next question is whether the *number* of topic files needs a budget, not just their size. Estimated byte saving: `not estimated — no prior data` (no prior file-count reclamation to anchor to).

4. **memory** — 713,402 bytes, +20.1%, the first cycle it has cleared the delta gate. Comparable prior: `not estimated — no prior data`. Memory files are per-project and loaded at session start via `MEMORY.md`; the index line count, not the corpus size, is what is actually paid per session, so this bucket's growth may be cheaper than its byte count implies. Recorded for trend, not actioned.

5. **problems** — 6,390,043 bytes, 53.6% of the corpus and the largest absolute grower (+441,831). Comparable prior: **P095 reclaimed ~120 KB by once-per-session gating**. The corpus is not loaded wholesale — `docs/problems/README.md` is the routine-load surface and individual tickets are read on demand — so byte count overstates the per-session cost. The README itself is the surface worth watching: a prior cycle recorded it exceeding the Read-tool 25K-token whole-file cap and forcing paged reads (P282 Related).

## Policy Breaches

| Budget | Offender | Bytes | Citation |
|--------|----------|-------|----------|
| ADR-038 SKILL.md ≤50 KB (P097) | `packages/itil/skills/work-problems/SKILL.md` | 231,908 | `find packages -name SKILL.md -size +50k` |
| ADR-038 SKILL.md ≤50 KB (P097) | `packages/itil/skills/manage-problem/SKILL.md` | 145,781 | same |
| ADR-038 SKILL.md ≤50 KB (P097) | `packages/retrospective/skills/run-retro/SKILL.md` | 93,950 | same |
| ADR-038 SKILL.md ≤50 KB (P097) | `packages/itil/skills/review-problems/SKILL.md` | 79,461 | same |
| ADR-038 SKILL.md ≤50 KB (P097) | `packages/itil/skills/capture-problem/SKILL.md` | 57,989 | same |
| ADR-038 SKILL.md ≤50 KB (P097) | `packages/itil/skills/report-upstream/SKILL.md` | 53,300 | same |
| ADR-038 SKILL.md ≤50 KB (P097) | `packages/itil/skills/update-upstream/SKILL.md` | 51,640 | same |
| ADR-040 Tier 3 ≤5,120 bytes | `docs/briefing/afk-ratification-hold.md` | 5,857 | `check-briefing-budgets.sh` |
| ADR-040 Tier 3 ≤5,120 bytes | `docs/briefing/story-map-ratification-queue.md` | 5,199 | `check-briefing-budgets.sh` |

Neither briefing file carries a `MUST_SPLIT` line (both are under 2× the ceiling), so both take the Branch B rotation path in `run-retro` Step 3.

**Both were resolved in the same retro pass that produced this report, so the two rows above are a measurement record rather than live findings.** `afk-ratification-hold.md` rotated its oldest entry to a new `afk-ratification-hold-archive.md` (5,857 → 4,987 bytes). `story-map-ratification-queue.md` was **deleted**: it was a transient queue written 2026-08-09 for a specific morning ratification pass, and both maps it queued now carry `human-oversight: confirmed` with its branch merged as PR #418. Two further files (`external-comms-gate.md`, `hooks-and-gates.md`) went over budget during the same pass because entries were added to them, and were rotated in turn. `check-briefing-budgets.sh` reports clear against the resulting tree.

**ADR-038 hook prose budget (≤150 bytes per subsequent-prompt reminder)**: not measured this cycle — sampling each `UserPromptSubmit` hook's terse-reminder branch was not performed, so no breach row is emitted for that budget either way. Recorded as a gap rather than as a clean result.

<!--
context-snapshot:
  total-bytes: 11919794
  hooks: 660314
  skills: 1362710
  memory: 713402
  briefing: 221698
  decisions: 2459556
  problems: 6390043
  jtbd: 105880
  project-claude-md: 6191
  framework-injected: not measured
  measurement-method: byte-count-on-disk
  measured-at: 2026-08-20
-->
