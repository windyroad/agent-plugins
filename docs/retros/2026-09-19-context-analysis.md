# Context Analysis — 2026-09-19

> Source: `/wr-retrospective:analyze-context` (deep layer per ADR-043), auto-fired from `run-retro` Step 2c step 4 during the P463 iteration retro. Calendar-elapse trigger: the prior report is 21 days old (>14-day threshold). Once-per-day guard clear.
> Methodology: byte-count-on-disk + per-plugin decomposition + per-turn attribution (when a session log is available).
> Cheap-layer baseline: `wr-retrospective-measure-context-budget .`, run 2026-09-19.
> Prior snapshot: the `context-snapshot:` trailer of `docs/retros/2026-08-29-context-analysis.md`.

## Bucket Totals

| Bucket | Bytes | % of measured | Δ vs prior |
|--------|------:|--------------:|-----------:|
| problems | 6,928,192 | 54.63% | +200,238 (+2.98%) |
| decisions | 2,627,167 | 20.71% | +106,176 (+4.21%) |
| skills | 1,398,457 | 11.03% | +30,324 (+2.22%) |
| memory | 880,799 | 6.94% | +119,708 (+15.73%) |
| hooks | 737,349 | 5.81% | +71,584 (+10.75%) |
| briefing | 242,065 | 1.91% | +2,660 (+1.11%) |
| jtbd | 122,979 | 0.97% | +5,277 (+4.48%) |
| project-claude-md | 7,594 | 0.06% | +322 (+4.43%) |
| framework-injected | not measured — framework-injected-no-on-disk-source | — | — |

Total measured: 12,944,602 bytes, +536,289 (+4.32%) from the 12,408,313-byte 2026-08-29 snapshot.

Two buckets cleared the ADR-043 delta-axis gate this cycle (>20% is the trigger; neither reached it, but both cleared the 10 KB absolute floor by a wide margin and are the growth story): **memory** at +15.73% / +119,708 bytes and **hooks** at +10.75% / +71,584 bytes. Hooks is the one to watch — it grew faster in 21 days than it had in the preceding nine, and hook bytes are loaded on every prompt rather than on demand.

## Per-Plugin Decomposition

### Hooks (aggregate from cheap layer: 737,349 bytes)

| Plugin | Bytes | % of hooks | Δ vs 2026-08-29 |
|--------|------:|-----------:|----------------:|
| itil | 196,957 | 26.7% | +520 |
| risk-scorer | 135,956 | 18.4% | +3,971 |
| architect | 91,875 | 12.5% | +12,221 |
| voice-tone | 78,264 | 10.6% | +12,948 |
| jtbd | 56,350 | 7.6% | +12,726 |
| shared | 54,269 | 7.4% | +10,951 |
| tdd | 40,909 | 5.5% | +9,316 |
| style-guide | 36,911 | 5.0% | +8,931 |
| cruise | 21,984 | 3.0% | 0 |
| retrospective | 21,818 | 3.0% | 0 |
| connect | 2,056 | 0.3% | 0 |

The plugin rows sum to 737,349 bytes and reconcile exactly with the cheap-layer aggregate.

The growth is not concentrated — seven plugins each added 4–13 KB, and the two biggest hook surfaces (`itil`, `risk-scorer`) barely moved. That pattern reads as a shared change propagated across consumers rather than one plugin's feature, which is what `shared`'s +10,951 alongside six similar-sized siblings suggests.

### Skills (aggregate from cheap layer: 1,398,457 bytes)

| Plugin | Bytes | % of attributed skills | Δ vs 2026-08-29 |
|--------|------:|-----------------------:|----------------:|
| itil | 1,052,830 | 75.9% | +24,213 |
| retrospective | 119,865 | 8.6% | +176 |
| risk-scorer | 75,504 | 5.4% | -80 |
| architect | 69,601 | 5.0% | +3,092 |
| jtbd | 22,202 | 1.6% | +578 |
| voice-tone | 12,818 | 0.9% | +2,345 |
| wardley | 12,225 | 0.9% | 0 |
| connect | 11,434 | 0.8% | 0 |
| style-guide | 3,895 | 0.3% | 0 |
| tdd | 3,369 | 0.2% | 0 |
| cruise | 984 | 0.1% | 0 |
| c4 | 660 | 0.0% | 0 |

The plugin rows sum to 1,385,387 bytes. The remaining 13,070 bytes are `REFERENCE.md` files and evaluation assets counted by the cheap layer's whole-tree walk but not by the attribution helper's `SKILL.md` walk — the same 13,070-byte residual as the prior snapshot, so the gap is structural, not drift.

## Top-N Offenders

| Surface | Bytes | Bucket | Δ vs 2026-08-29 | Comparable prior |
|---------|------:|--------|----------------:|------------------|
| `packages/itil/skills/work-problems/SKILL.md` | 251,431 | skills | +8,746 | P097 (SKILL.md runtime size) — no measured reclamation yet |
| `packages/itil/skills/manage-problem/SKILL.md` | 154,854 | skills | +1,563 | P097 — no measured reclamation yet |
| `packages/retrospective/skills/run-retro/SKILL.md` | 95,487 | skills | +176 | P097 — no measured reclamation yet |
| `packages/itil/skills/review-problems/SKILL.md` | 80,475 | skills | +1,301 | P097 — no measured reclamation yet |
| `packages/itil/skills/capture-problem/SKILL.md` | 59,000 | skills | +1,011 | P097 — no measured reclamation yet |

`work-problems/SKILL.md` crossed a quarter of a megabyte this cycle. It is now 5.0× the 50 KB threshold and 18.0% of the entire skills bucket on its own.

## Per-Turn Attribution

per-turn attribution: not measured — no session log accessible. `.afk-run-state/` holds `outstanding-questions.jsonl` and `risk-register-queue.jsonl`, which are queue files, not per-turn records carrying `usage` fields. Same limitation as the 2026-08-29 and 2026-08-20 reports; three consecutive cycles have now been unable to measure this axis.

## Suggestions

1. **skills / `packages/itil/skills/work-problems/SKILL.md`** — At 251,431 bytes this file is 5.0× the 50 KB P097 threshold and grew 8,746 bytes in 21 days, the largest single-surface growth measured this cycle. ADR-054's `REFERENCE.md` split is the established progressive-disclosure shape and this surface has never had one applied. Estimated byte saving: not estimated — no prior data.
2. **hooks (whole bucket)** — 737,349 bytes, +71,584 (+10.75%), spread across seven plugins in 4–13 KB increments rather than concentrated. Hook bytes load on every prompt, so this bucket's growth costs more per byte than any on-demand bucket. Worth identifying whether the seven similar increments share a common origin (`shared` grew 10,951 in the same window) before treating them as seven separate surfaces. Estimated byte saving: not estimated — no prior data.
3. **memory** — 880,799 bytes, +119,708 (+15.73%), the fastest-growing bucket by rate. Comparable prior: P095 reclaimed about 120 KB through once-per-session gating. Whether that shape applies here depends on which memory surfaces are loaded per-session versus per-prompt, which this measurement does not decompose. Estimated byte saving: not estimated — no prior data.
4. **problems** — 6,928,192 bytes, 54.63% of measured bytes and still the dominant bucket, but its growth rate fell from +5.29% to +2.98%. Within it, `docs/problems/README-history.md` is 554,432 bytes and `docs/problems/README.md` is 229,903 — 784,335 bytes of index and accumulator against a corpus of individually on-demand tickets. The history file is append-only by the P134 rotation contract and has no rotation of its own. Comparable prior: P100 split the single briefing file into per-topic files with archive siblings; the same date-stratified archive shape would apply. Estimated byte saving: not estimated — no prior data.
5. **decisions** — 2,627,167 bytes, +106,176 (+4.21%), second-largest bucket. Growth is expected and structural: ADR-116 makes ratified decisions immutable, so every change adds a file and none shrinks one. This is the cost the supersession model was chosen with eyes open (ADR-116 Consequences → Bad records it), not a defect. No trim is proposed.

## Policy Breaches

| Budget | Offender | Bytes | Citation |
|--------|----------|------:|----------|
| ADR-038 SKILL.md ≤50 KB (P097) | `packages/itil/skills/work-problems/SKILL.md` | 251,431 | `find packages -path '*/skills/*/SKILL.md' -type f -exec wc -c` |
| ADR-038 SKILL.md ≤50 KB (P097) | `packages/itil/skills/manage-problem/SKILL.md` | 154,854 | same measurement |
| ADR-038 SKILL.md ≤50 KB (P097) | `packages/retrospective/skills/run-retro/SKILL.md` | 95,487 | same measurement |
| ADR-038 SKILL.md ≤50 KB (P097) | `packages/itil/skills/review-problems/SKILL.md` | 80,475 | same measurement |
| ADR-038 SKILL.md ≤50 KB (P097) | `packages/itil/skills/capture-problem/SKILL.md` | 59,000 | same measurement |
| ADR-038 SKILL.md ≤50 KB (P097) | `packages/itil/skills/update-upstream/SKILL.md` | 56,067 | same measurement |
| ADR-038 SKILL.md ≤50 KB (P097) | `packages/itil/skills/report-upstream/SKILL.md` | 53,300 | same measurement |

Seven breaches, the same seven as 2026-08-29; every one grew or held. `wr-retrospective-check-briefing-budgets` emitted no `OVER` rows. ADR-038's ≤150-byte subsequent-prompt reminder budget was not measured — no branch-level hook sampling was performed.

<!--
context-snapshot:
  total-bytes: 12944602
  hooks: 737349
  skills: 1398457
  memory: 880799
  briefing: 242065
  decisions: 2627167
  problems: 6928192
  jtbd: 122979
  project-claude-md: 7594
  framework-injected: not measured
  measurement-method: byte-count-on-disk
  measured-at: 2026-09-19
-->
