# Problem 186: VQ `Likely verified?` column uses age-based heuristic (≥14 days = yes) instead of session-observed evidence — sibling proxy-for-evidence anti-pattern to P185

**Status**: Open
**Reported**: 2026-05-12
**Priority**: 10 (High) — Impact: 2 (Minor — VQ display heuristic misframes closure signal in installed SKILL; published packages unaffected; no incorrect closure because user still confirms each close, but the framing primes default-yes on age) x Likelihood: 5 (Almost certain — every `/wr-itil:review-problems` pass re-renders the column; observed today on the P016/P017/P024/P047/P048 prompt batch where the heuristic surfaced 5 candidates and user critiqued 3 of them as not-evidence)
**Effort**: M (rewrite `Likely verified?` semantics from age-based to session-observed-evidence; update Step 3 + Step 5 render contracts in `/wr-itil:review-problems` SKILL.md + sibling drift-detection across `/wr-itil:list-problems` + `/wr-itil:manage-problem` Steps 5/7/9c/9e + `/wr-itil:transition-problem(s)` + `/wr-itil:reconcile-readme`; behavioural bats for cell-render contract; full sibling-skill contract suites re-run)
**WSJF**: 5.0 = (Severity 10 × Status Multiplier 1.0 Open) / Effort divisor 2 (M)
**Type**: technical

## Description

VQ `Likely verified?` column uses age-based heuristic (≥14 days = yes) instead of session-observed evidence — sibling proxy-for-evidence anti-pattern to P185 at the review-problems Step 3/5 surface. User critique 2026-05-12 during Step 4 prompt batch: "I don't like 'it's been a while, so likely verified' approach. We want firm evidence. For these, it should be things you actually observe."

## Symptoms

(deferred to investigation)

## Workaround

(deferred to investigation)

## Impact Assessment

- **Who is affected**: (deferred to investigation)
- **Frequency**: (deferred to investigation)
- **Severity**: (deferred to investigation)
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [x] Re-rate Priority and Effort at next /wr-itil:review-problems (re-rated inline 2026-05-12 — Severity 10 High, Effort M, WSJF 5.0; same pass as capture per "newly captured ticket in this review pass" carve-out)
- [ ] Audit existing VQ entries in `docs/problems/README.md` for over-staged `yes (N days)` rows lacking direct session-evidence
- [ ] Decide canonical cell shape — proposal: `yes — observed: <evidence>` / `no — not observed` / `no — observed regression`; aging surfaces separately (Released-date column already carries it)
- [ ] Decide evidence-detection mechanism — proposal: Step 4 AskUserQuestion confirmation populates cell; close-on-evidence retro Step 4a populates; otherwise default `no — not observed`
- [ ] Sweep co-located SKILL.md files for cross-file drift (P138 / P150 pattern): review-problems, list-problems, manage-problem 5/7/9c/9e, transition-problem(s), reconcile-readme
- [ ] Behavioural bats: render assertions for all cell states; close-on-evidence path populates correctly; cross-file drift detection
- [ ] Investigate P048 design-intent vs implementation-drift on the heuristic — was age explicitly chosen or did framing slip during implementation?

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P185 (sibling proxy-for-evidence anti-pattern at /wr-itil:capture-problem Step 1.5 — same fix pattern), P048 (original VQ-detection ticket that introduced the 14-day default — this ticket reopens design-intent vs implementation-drift question), P132 (inverse-P078 / over-ask SKILL-surface variant)

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)
