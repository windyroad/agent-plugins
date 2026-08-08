# Problem 477: Nothing recomputes WSJF on a status transition, so the Open multiplier persists and halves the ticket's rank

**Status**: Open
**Reported**: 2026-08-08
**Priority**: 12 (High) — Impact: 3 (Moderate) × Likelihood: 4 (Likely) — derived at capture from the description per Step 4a. Impact 3: the backlog is mis-sequenced within its tier, so AFK loops and interactive pickers work the wrong ticket first; no data loss, no security exposure, and ADR-076's tier-first render bounds the blast radius to within-tier ordering. Likelihood 4: potentially every Open → Known Error transition; one confirmed downstream instance (P121 in `windyroad/windyroad`) plus four capture-time siblings of the same arithmetic surface in a single day.
**Origin**: inbound-reported (#413)
**Effort**: M — derived at capture per Step 4a. Two SKILL step reorders, three copy-not-move checklist lines, one new diagnose-only script plus its shim and behavioural bats. Cross-file but shallow; no migration. WSJF = (12 × 1.0) / 2 = 6.0.
**WSJF**: 6.0 — (12 × 1.0) / 2
**JTBD**: JTBD-006, JTBD-001
**Persona**: developer

## Description

WSJF is `(Severity × Status Multiplier) / Effort Divisor`, and the multiplier changes with status: Open 1.0, Known Error 2.0. Both re-score surfaces compute WSJF *before* they auto-transition the ticket, and nothing recomputes afterwards. The value written to disk therefore carries the Open multiplier at the moment the status flips to Known Error, and the ticket renders at half its correct rank for as long as it sits in the queue.

Reported upstream as [windyroad/agent-plugins#413](https://github.com/windyroad/agent-plugins/issues/413), observed 2026-08-05 in the `windyroad/windyroad` consumer project on its ticket P121. The transition correctly re-rated Effort M → L but left the multiplier at 1.0, giving WSJF 3.0 where `(12 × 2.0) / 4 = 6.0`.

The transition case is harder to catch than the capture case. At capture there is no prior value to be inconsistent with, so a review pass catches the error by recomputation. At transition the ticket already carries a plausible-looking WSJF line, and the Effort re-rate the checklist *does* mandate draws attention away from the multiplier that changed alongside it.

## Symptoms

**The recompute runs before the transition, never after.**

- `packages/itil/skills/review-problems/SKILL.md` Step 2: item 8 computes `(Severity × Status Multiplier) / Effort Divisor`, item 9 writes the result to the ticket, item 10 auto-transitions Open → Known Error. The multiplier used at item 8 is the pre-transition one.
- `packages/itil/skills/manage-problem/SKILL.md` Step 9b: identical ordering — item 8 calculates, item 9 writes, item 10 auto-transitions.

**The three transition checklists never mention the multiplier.** All three mandate an Effort re-rate and say nothing about the status multiplier that changes in the same transition:

- `packages/itil/skills/transition-problem/SKILL.md` (Open → Known Error pre-flight)
- `packages/itil/skills/transition-problems/SKILL.md`
- `packages/itil/skills/manage-problem/SKILL.md` Step 7

**Nothing downstream catches the resulting value.** The README refresh is documented as "a render, not a re-rank" and trusts existing WSJF values on the ticket files. `packages/itil/scripts/reconcile-readme.sh` compares ticket-ID-to-status membership only — it never parses a WSJF number, so a value that is wrong in *both* the ticket body and the README row exits 0 clean. Downstream, only the `wr-risk-scorer:pipeline` commit gate caught it, after architect, jtbd, style-guide and voice-tone reviews had all passed. None of those four reads WSJF arithmetic.

## Workaround

Recompute WSJF by hand after every status transition as `(Severity × Status Multiplier) / Effort Divisor`, taking the multiplier from the **post**-transition status.

One trap worth knowing: a *full* recompute that also changes Effort in the same transition can look like a no-op, because M → L doubles the divisor while Open → Known Error doubles the multiplier and the two cancel. That is correct but does not look like a correction. The *partial* recompute is the dangerous case and is what happened downstream — Effort was updated, the multiplier was not, so the divisor doubled with nothing to offset it and the stored value was halved.

## Impact Assessment

- **Who is affected**: `developer` persona in any project using `docs/problems/`, and every AFK orchestrator run.
- **Frequency**: potentially every Open → Known Error status transition.
- **Severity**: 12 (High) — see the Priority line.
- **Analytics**: five instances of the same arithmetic surface recorded in one downstream project across 2026-08-05 (four capture-time miscalculations plus the P121 transition error).

## Root Cause Analysis

Confirmed by reading the two re-score surfaces. The WSJF calculation is sequenced ahead of the auto-transition in both, and neither re-runs it once the status has changed. The three transition checklists then mandate the Effort re-rate without the paired multiplier re-rate, so the manual path repeats the same omission. The consistency layer (`reconcile-readme.sh`) validates membership rather than arithmetic, so a wrong-in-both-places value is invisible to it.

### Investigation Tasks

- [x] Investigate root cause — confirmed at all five surfaces named under Symptoms.
- [x] Create reproduction test — behavioural bats over synthetic fixtures, landing with the fix.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: ADR-076 (tier-first render bounds the blast radius to within-tier ordering); ADR-022 (the multiplier's "dev work remaining" semantic is what the stale value violates).

## Related

- Upstream issue [#413](https://github.com/windyroad/agent-plugins/issues/413) — the inbound report this ticket was captured from.
- **P047** (`docs/problems/closed/047-wsjf-effort-bucket-accuracy-gaps.md`) — the Effort-axis sibling; its fix is the Effort re-rate clause that this ticket shows is only half the transition's arithmetic.
- **P138** (`docs/problems/closed/138-readme-wsjf-row-order-doesnt-match-work-problems-tie-break.md`) — same ranked table, ordering axis rather than arithmetic axis.
- **P118** (`reconcile-readme.sh`) — the membership-drift detector that exits 0 on this defect by design.
- Not covered by #315 (ranking does not factor placement-authority) or #312 (ranking does not exclude just-worked Known Error tickets awaiting push), though both touch the same ranked table.
