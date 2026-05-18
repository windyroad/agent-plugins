# Problem 262: P165 README-refresh hook conflicts with capture-problem SKILL's deferred-README-refresh contract — hook wins; SKILL needs update OR hook needs carve-out

**Status**: Open
**Reported**: 2026-05-18
**Priority**: 6 (Medium) — Impact: 2 (Minor — capture commit denied until workaround applies; not destructive) x Likelihood: 3 (Likely — fires on every capture commit; observed 4× this session for P254/P255/P256/P257)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems; either SKILL.md amendment or hook carve-out, architect verdict)
**Type**: technical

## Description

Surfaced 2026-05-18 during session 6 captures (P254, P255, P256, P257). The `/wr-itil:capture-problem` SKILL.md Step 6 contract explicitly says:

> **Stage list**: ONLY the new ticket file. **Do NOT** stage `docs/problems/README.md`. The deferred-README-refresh contract is the load-bearing distinction from `/wr-itil:manage-problem` — capture-time speed depends on skipping the regenerate-and-stage cycle.

But the P165 README-refresh hook (`packages/itil/hooks/itil-readme-refresh-discipline.sh`) DENIES commits where a new ticket file is staged without `docs/problems/README.md` staged alongside:

```
BLOCKED: P165. P<NNN> needs README refresh: git add docs/problems/README.md. Bypass: BYPASS_README_REFRESH_GATE=1 via .claude/settings.json env (P173).
```

Per the hook's `_readme_refresh_staged_is_ranking_bearing` logic (lines 207-244): any NEW ticket file (status `A`) is treated as ranking-bearing → README MUST be staged. There's no carve-out for `docs(problems): capture` commits.

The hook is the LOAD-BEARING enforcement surface (P165 + ADR-014 amended); the SKILL contract is documentation. Hook wins.

**Workaround used 4× this session**: Edit `docs/problems/README.md` to add the new ticket's row to WSJF Rankings with deferred-placeholder values (e.g. `| 1.5 | P<NNN> | <title> (captured via /wr-itil:capture-problem; Priority/Effort deferred to next /wr-itil:review-problems) | 3 Med | Open | M | 2026-05-18 |`), stage README + ticket together, commit.

## Symptoms

- `git commit -m "docs(problems): capture P<NNN> <title>"` denied with the P165 error above.
- The capture-problem SKILL contract is silent on this hook's existence.
- Adopters following the SKILL contract verbatim will hit this on every capture.

## Workaround

Refresh `docs/problems/README.md` WSJF Rankings with a deferred-placeholder row for the new ticket; stage README alongside the ticket file; commit. The deferred-placeholder shape (`Priority/Effort deferred to next /wr-itil:review-problems`) preserves the SKILL's intent (deferred re-rating) while satisfying the hook's "README must reflect new tickets" enforcement.

## Impact Assessment

- **Who is affected**: Every capture-problem invocation. Observed 4× this session.
- **Frequency**: Likely (3) — fires on every capture commit.
- **Severity**: Minor — workaround works, but the SKILL contract is misleading.

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems.
- [ ] Architect verdict on the resolution shape:
  - **Option A — Update capture-problem SKILL.md Step 6**: replace "Do NOT stage docs/problems/README.md" with "Stage docs/problems/README.md with a deferred-placeholder row appended". Documents the actual contract.
  - **Option B — Hook carve-out for `docs(problems): capture` commit subjects**: amend `packages/itil/hooks/itil-readme-refresh-discipline.sh` to skip the gate when the commit subject starts with `docs(problems): capture`. Preserves the deferred-README-refresh contract.
  - **Option C — Hybrid**: capture-problem Step 6 writes the deferred-placeholder row automatically (no manual Edit); hook carve-out is unchanged.
- [ ] Implement chosen option + bats coverage.

## Dependencies

- **Blocks**: (none — workaround works)
- **Blocked by**: (none)
- **Composes with**: P165 (README-refresh hook driver), P155 (capture-problem skill driver), P173 (BYPASS env propagation), P094 (refresh-on-create contract)

## Related

- `packages/itil/hooks/itil-readme-refresh-discipline.sh` — hook source.
- `packages/itil/skills/capture-problem/SKILL.md` Step 6 — SKILL contract.
- P165 — README-refresh hook driver.
- P155 — capture-problem skill driver.
- P094 — refresh-on-create contract.

(captured via /wr-retrospective:run-retro Step 4b Stage 1; expand at next investigation)
