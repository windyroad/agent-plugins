# Problem 505: Seven SKILL.md files breach the 50 KB budget, and nothing converts the measurement into work

**Status**: Open
**Reported**: 2026-08-20
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4 — derived at capture. Impact 3: SKILL.md bodies load into the agent's context on invocation, so the breach is paid as context on every use of the affected skills, and the largest is the AFK orchestrator that long loops invoke repeatedly. Likelihood 4: measured today and growing — the skills bucket has grown every measured cycle, and the two worst offenders are the two most-invoked skills in the suite.
**Origin**: internal
**Effort**: L — derived at capture: seven files, and the largest needs a genuine SKILL/REFERENCE contract split rather than a trim. `run-retro` already carries the target shape, so the pattern is established; the work is applying it seven times. Sized above P503's M on file count and on the judgement each split needs.
**WSJF**: 3 — (12 × 1.0) / 4 (added 2026-08-21 review)
**JTBD**: JTBD-001
**Persona**: developer

## Description

Measured 2026-08-20 by `find packages -name SKILL.md -size +50k`, recorded in `docs/retros/2026-08-20-context-analysis.md`:

| SKILL.md | Bytes | × the 50 KB budget |
|---|---|---|
| `packages/itil/skills/work-problems/SKILL.md` | 231,908 | 4.5× |
| `packages/itil/skills/manage-problem/SKILL.md` | 145,781 | 2.8× |
| `packages/retrospective/skills/run-retro/SKILL.md` | 93,950 | 1.8× |
| `packages/itil/skills/review-problems/SKILL.md` | 79,461 | 1.6× |
| `packages/itil/skills/capture-problem/SKILL.md` | 57,989 | 1.1× |
| `packages/itil/skills/report-upstream/SKILL.md` | 53,300 | 1.0× |
| `packages/itil/skills/update-upstream/SKILL.md` | 51,640 | 1.0× |

`itil` holds 1,024,555 of the suite's 1,362,710 skill bytes (75.2%); the four largest files above are 515,139 bytes, which is 37.8% of every skill byte across all fourteen plugins.

**The reason this is a ticket rather than a report line**: the measurement already has a cadence — the deep layer auto-fires every 14 days per ADR-043 and writes the breach table into a committed report. What it does not have is a path from measurement to work. The breach has been measurable for several cycles and no reclamation has landed, because a row in a report is not a backlog item and nothing self-fires on it. This is the P375 class (a governance action with no automatic cadence never happens) applied to a detector whose *detection* is cadenced but whose *remedy* is not.

## Symptoms

- Seven `SKILL.md` files exceed 50 KB; the largest is 4.5× the budget.
- The `## Policy Breaches` section of each deep-layer context report lists them; no ticket, RFC or story references them.
- P097, the ticket that originally carried the SKILL.md size concern, is Closed.

## Workaround

None. The breach is a standing cost paid on every invocation of the affected skills.

## Impact Assessment

- **Who is affected**: every session that invokes one of the seven skills, in this repo and in adopter installs — `SKILL.md` ships in the plugin tarball.
- **Frequency**: every invocation. `work-problems` and `manage-problem` are the two most-invoked skills in the suite, and AFK loops invoke them repeatedly within one session.
- **Severity**: context pressure rather than incorrectness — but context pressure is what drives compaction, and compaction is upstream of several observed failure classes in this repo's history.
- **Analytics**: skills bucket 1,362,710 bytes total, +29,976 (+2.2%) over 25 days; `itil` 75.2% of it. Full decomposition in `docs/retros/2026-08-20-context-analysis.md`.

## Root Cause Analysis

### Preliminary Hypothesis

Two causes compound. First, `SKILL.md` is the only file the skill loader reads, so every clarification, supersession note, worked example and anti-pattern block accretes into the runtime surface — and this repo's discipline of recording *why* a step exists (correctly, per ADR-026) means the accretion is continuous and each individual addition is justified. Second, ADR-054's runtime-budget policy and ADR-038's progressive-disclosure pattern both prescribe the remedy — move rationale into a lazy-loaded `REFERENCE.md` — but neither is enforced at write time, so the budget is honour-system while the accretion is automatic. An automatic input against a manual control drifts one way only.

### Investigation Tasks

- [ ] Confirm the applicable budget and its owner: P097 is Closed, so establish whether ADR-054 or ADR-038 is the live authority and what number it actually sets
- [ ] Split `work-problems/SKILL.md` first — at 4.5× it dominates, and it validates the pattern before the other six pay for it. `run-retro/SKILL.md` already carries a `REFERENCE.md` split and is the shape to copy
- [ ] Decide whether the remedy needs enforcement (a commit-time advisory like `check-briefing-budgets.sh`, or a CI check) or whether ticketed backlog is sufficient cadence — the briefing tree's Tier 3 pass is the precedent for the advisory shape
- [ ] Measure the actual per-invocation context cost, not just bytes on disk, so the split's benefit is verifiable rather than assumed
- [ ] Create a reproduction test: a `SKILL.md` over the budget must be surfaced by whatever detector the fix lands

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P097, P091, P375

## Related

(captured via `/wr-retrospective:run-retro` Step 4b Stage 1; measurement from the same session's deep-layer context analysis)

- **`docs/retros/2026-08-20-context-analysis.md`** — the measurement of record, including the per-plugin decomposition and the full breach table.
- **P097** (`docs/problems/closed/097-skill-md-runtime-size-mixes-policy-with-runtime-steps.md`) — Closed. Carried the original SKILL.md size concern; the breach it named has since grown rather than receded, but this ticket is a distinct framing (no path from a cadenced measurement to work) rather than a reopen of that one.
- **P091** (`docs/problems/open/091-session-wide-context-budget-from-plugin-hook-stack.md`) — the session-wide context-budget meta-ticket; this is the skills-bucket leg of it.
- **P375** — the no-automatic-cadence class. Here the detection is cadenced and the remedy is not, which is the same failure one step further along.
- **ADR-054** — SKILL.md runtime-budget policy. **ADR-038** — progressive disclosure; the SKILL/REFERENCE split is its prescribed shape. **ADR-043** — the two-layer context measurement that produced the numbers.
