# Problem 027: `manage-problem work` re-scans all problems on every invocation

**Status**: Open
**Reported**: 2026-04-16
**Priority**: 15 (High) — Impact: Significant (4) x Likelihood: Almost Certain (5)
**Effort**: M
**WSJF**: 7.5 — (15 × 1.0) / 2

## Description

The `manage-problem work` command performs a full WSJF review on every invocation: it reads all open/known-error problem files, recalculates severity and effort, checks git history for each, presents a ranked table, handles verification queries, and then runs a work-selection `AskUserQuestion`. With 18+ open problems, this is ~20 file reads plus two roundtrips before any work begins.

Two related inefficiencies compound the scan cost:

1. **Parked/suspended problems have no first-class status.** Problems blocked on upstream (P007, P008) are informally marked `## Status: Parked pending upstream` in their description, but the skill has no way to recognise this — so they are read, ranked, and included in the selection prompt every session. The user must specify the exclusion at each invocation ("not on the connect plugin").

2. **No WSJF cache.** There is no `docs/problems/BACKLOG.md` or equivalent. The full re-rank runs even when no problem files have changed since the last review.

These costs compound as the backlog grows. JTBD-001 requires governance operations to complete in under 60 seconds.

## Symptoms

- `manage-problem work` reads 18+ files on every invocation regardless of whether any problem changed since the last review.
- User must re-specify parked/suspended problem exclusions in natural language on every invocation.
- The WSJF table is recomputed from scratch even when the answer will be identical to the previous session.
- As the backlog grows, the overhead grows proportionally — the skill gets slower as governance debt accumulates.
- Observed this session: user stated "it feels very inefficient doing this each time we want to work problems."

## Workaround

Specify exclusions each session ("not on the connect plugin"). Accept the re-scan overhead.

## Impact Assessment

- **Who is affected**:
  - Solo-developer persona (JTBD-001 Enforce Governance Without Slowing Down) — "under 60 seconds" outcome target threatened as backlog grows
  - Solo-developer persona (JTBD-005 Invoke Governance Assessments On Demand) — per-invocation overhead erodes the "must not leave task context" constraint
- **Frequency**: Every `manage-problem work` invocation.
- **Severity**: High — the friction directly attacks the core premise of the governance suite: that governance is fast enough to not interrupt flow.
- **Analytics**: Observed this session with 18 open/known-error problems; will worsen with time.

## Root Cause Analysis

Two root causes:

1. **No "Parked" lifecycle status.** The problem lifecycle (`SKILL.md` lines 27-31) defines Open, Known Error, and Closed. There is no Parked state. Problems blocked on upstream fixes or suspended by user decision have no machine-readable signal — they look identical to workable Open problems to the review step.

2. **No WSJF cache.** The `manage-problem review` step (step 9) re-derives the ranking from scratch every time. There is no persistent ranked list that could be reused when no problem files changed since the last review.

### Investigation Tasks

- [ ] Add "Parked" as a first-class lifecycle status to `packages/itil/skills/manage-problem/SKILL.md`:
  - File suffix: `.parked.md`
  - Entry criteria: upstream blocker identified, or user explicitly suspends; transition documented with reason and expected resolution trigger
  - Review behaviour: parked problems are read but excluded from WSJF ranking and work selection; displayed in a separate "Parked" table section
  - Exit criteria: user explicitly un-parks, or the upstream blocker resolves
  - `git mv` to/from `.parked.md` (not to `.open.md` directly — preserve the parked history)
- [ ] Transition P007 and P008 to `.parked.md` status as the first users of the new status
- [ ] Implement `docs/problems/BACKLOG.md` cache:
  - Written by the review step (step 9e) after every full re-rank, containing the WSJF table in machine-readable form with a `reviewed:` timestamp
  - `problem work` checks whether any `docs/problems/*.md` file has a newer mtime than `BACKLOG.md`; if not, reads `BACKLOG.md` only (1 file, not 18+)
  - `problem review` always re-scans (its purpose is to refresh the cache)
  - Cache invalidation: any problem file write (create, update, transition) invalidates the cache (mtime comparison)
- [ ] Update `SKILL.md` to describe the cache read-path in the `work` operation
- [ ] Add a BATS test asserting `BACKLOG.md` is written after `problem review` runs (structural check, not LLM test)
- [ ] Re-run architect review after fix scope is confirmed (ADR-010 lifecycle table change may need noting)

## Related

- `packages/itil/skills/manage-problem/SKILL.md` — primary target (lifecycle table + work step)
- P007: `docs/problems/007-discord-inbound-reactions-not-delivered.open.md` — candidate for `.parked.md`
- P008: `docs/problems/008-askuserquestion-unavailable-with-channels.open.md` — candidate for `.parked.md`
- JTBD-001: `docs/jtbd/solo-developer/JTBD-001-enforce-governance.proposed.md` — "under 60 seconds" outcome target
- JTBD-005: `docs/jtbd/solo-developer/JTBD-005-assess-on-demand.proposed.md` — on-demand friction constraint
- ADR-014: `docs/decisions/014-governance-skills-commit-their-own-work.proposed.md` — BACKLOG.md cache writes must be committed alongside problem file updates
