# Problem 331: transition-problem SKILL Step 7 P134 Last-reviewed rotation silently skipped across iters

**Status**: Open
**Reported**: 2026-05-30 (work-problems wrap retro — defers from iter 9 retro deferred-ticket observation per iter 10 retro carry-forward)
**Priority**: 6 (Medium) — Impact: 2 (Minor — line 3 staleness propagates across multiple iters; README-history.md misses entries; audit trail decoupled) × Likelihood: 3 (Likely — recurred 2 consecutive iters before iter-9 retro caught it)
**Effort**: S (deferred — re-rate at next /wr-itil:review-problems)
**Type**: technical
**WSJF**: 3.0 (deferred — re-rate at next /wr-itil:review-problems)

## Description

`/wr-itil:transition-problem` Step 7 (and the equivalent inline transition path in `/wr-itil:manage-problem`) prescribes the P134 truncation discipline: rotate line 3 of `docs/problems/README.md` ("Last reviewed" fragment) to `README-history.md` and replace with new fragment naming the transition. This contract was silently skipped in iter 7 + iter 8 of the 2026-05-30 work-problems AFK session; iter 9 retro caught the skip-class via post-fact comparison.

## Symptoms

- Iter 9 retro observed: `docs/problems/README.md` line 3 still carried iter-6 P282 fragment (3 iters old) despite iter 7 (P281 Open → KE) + iter 8 (P281 K→V) both modifying the WSJF Rankings + Verification Queue tables.
- `docs/problems/README-history.md` missing the iter-7 and iter-8 entries that should have been rotated.
- Iter 10 retro inherited the observation under `category: pipeline-instability-prior-iter` and deferred ticketing under `cause: skill_unavailable` (capture-* AFK carve-out per ADR-032).
- Concrete citation set in `docs/retros/2026-05-30-work-problems-iter9-p325.md` Pipeline Instability subsection.

## Workaround

Manual check after each transition + manual rotation if the line 3 hasn't been refreshed. Tedious; relies on operator memory.

## Impact Assessment

- **Who is affected**: every consumer of `docs/problems/README.md` line 3 (session-start surfaces; orchestrator preflight reads; ad-hoc audits).
- **Frequency**: 2 of 9 transition-bearing iters this session (~22%) — significant when transitions cluster.
- **Severity**: Minor — README line 3 is informational; downstream tooling reads tables, not line 3. Audit trail in `README-history.md` is the actual loss.
- **Analytics**: line 3 staleness propagation is silent until a retro catches it; can persist undetected across sessions.

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Reproduce: dispatch 2 consecutive iters that each call transition-problem with K→V; observe whether line 3 rotates on both
- [ ] Audit transition-problem SKILL Step 7 + manage-problem inline Step 7 prose for P134 rotation step explicitness
- [ ] Cross-reference with reconcile-readme Step 5 P134 rotation (which fires correctly in this session) — what's structurally different?
- [ ] Verify whether the silent-skip is per-skill-prose (Step 7 contract clarity) or per-execution (agent reading the contract but skipping the action)

### Hypotheses

1. **Step 7 contract clarity**: the P134 rotation step may be embedded in narrative prose rather than enumerated as a numbered step; agents reading the SKILL may skip it as a non-load-bearing note.
2. **Inline-vs-shim seam**: manage-problem Step 7 inline path may have diverged from the canonical transition-problem Step 7 in the P134 rotation requirement.
3. **Cross-iter race**: each iter sees its OWN line-3 as fresh (just rotated) but the prior-iter line-3 was never rotated, so each iter rotates onto the SAME stale predecessor — only the most-recent rotation persists.

## Fix Strategy

**Kind**: improve  
**Shape**: skill (SKILL.md amendment)  
**Target file**: `packages/itil/skills/transition-problem/SKILL.md` Step 7 (primary) + `packages/itil/skills/manage-problem/SKILL.md` inline Step 7 (sibling)  
**Observed flaw**: P134 line-3 rotation contract silently skipped across 2 consecutive iters; line 3 propagates stale state until next retro catches it  
**Edit summary**: per architect verdict, either (a) elevate the P134 rotation to a numbered Step 7 sub-step with explicit "MUST rotate" prose + bats coverage, or (b) ship a `wr-itil-rotate-readme-line3` shim invoked from both SKILL surfaces, or (c) a PostToolUse hook on `docs/problems/README.md` writes that auto-rotates on Status-row changes

**Evidence**: 2026-05-30 iter-7 + iter-8 silent-skip cited verbatim in `docs/retros/2026-05-30-work-problems-iter9-p325.md`; iter-10 deferred-ticket carry-forward in `docs/retros/2026-05-30-work-problems-iter10-p302.md`

## Dependencies

- **Blocks**: clean cross-iter audit trail in `README-history.md`
- **Blocked by**: (none)
- **Composes with**: ADR-022 (Verifying lifecycle), ADR-031 (per-state subdir layout), `/wr-itil:reconcile-readme` (sibling skill with correct P134 behaviour — model for fix)

## Related

- `docs/retros/2026-05-30-work-problems-iter9-p325.md` — Pipeline Instability subsection (primary citation)
- `docs/retros/2026-05-30-work-problems-iter10-p302.md` — carry-forward observation
- 2026-05-30 work-problems wrap retro (this capture)
- P134 (truncation discipline — the contract being violated)
- `/wr-itil:reconcile-readme` Step 5 (correct P134 implementation — fix model)
