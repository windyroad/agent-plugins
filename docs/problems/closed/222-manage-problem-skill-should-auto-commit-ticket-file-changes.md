# Problem 222: manage-problem skill should auto-commit ticket file changes

**Status**: Closed (Superseded)
**Reported**: 2026-05-15
**Closed**: 2026-06-08 (work-problems AFK iter — superseded by ADR-014; every manage-problem write path commits its own work)
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Resolution

**Closed as Superseded 2026-06-08.** The reported gap — "manage-problem writes the file but explicitly does not commit; the user must remember to commit" — is structurally impossible against the current `packages/itil/skills/manage-problem/SKILL.md`. Every write path commits per ADR-014 ("governance skills commit their own work", ratified after this ticket was filed):

- **Step 5 (new problems)** — `git add docs/problems/<NNN>-<title>.open.md docs/problems/README.md docs/problems/README-history.md` staged together; the Step 11 commit captures all three in one ADR-014 single-commit grain (SKILL.md line 616).
- **Step 6 (update existing)** — when the update changes Priority / Effort / WSJF (the ranking-bearing fields), the P094 refresh stages `docs/problems/README.md` alongside the ticket update so both ride the same Step 11 commit (SKILL.md line 659). Non-ranking-bearing edits skip the README refresh but still commit the ticket file in the same Step 11 transaction.
- **Step 7 (status transitions)** — Open → Known Error / Known Error → Verification Pending / Verification Pending → Closed / Parked all stage the renamed file + README refresh together; the commit message conventions in Step 11 carry the transition (SKILL.md line 760). The K→V path additionally seeds `Release vehicle` BEFORE rename per P330.
- **Step 11 (Report)** — `git add` all created/modified files (including any `git mv`-then-`Edit` file per the P057 staging-trap rule); commit gate via `wr-risk-scorer:pipeline` subagent (with `/wr-risk-scorer:assess-release` fallback); land the commit via `wr-risk-scorer-restage-commit` (the P326 atomic re-stage + commit wrapper). The message conventions enumerate every operation type (new / known-error / verifying / closed / review / fix). SKILL.md lines 994-1011.
- **`packages/itil/skills/capture-problem/SKILL.md` Step 6** — same single-commit pattern for the lightweight aside surface; stages `docs/problems/open/<NNN>-<kebab-title>.md` + `docs/problems/README.md` (+ `README-history.md` when line-3 rotates) and runs the same two-path commit gate (capture-problem SKILL.md line 292). The "update-ticket sub-flow" the original ticket referenced does not exist as a separate skill — it is the inline Step 6 update flow in manage-problem, which IS covered above.

**Substantive fixes already shipped**:

1. **ADR-014 "Governance skills commit their own work"** (ratified after this report) is the framework decision that closes this gap. The SKILL.md prose at every commit-bearing step cites `per ADR-014` and the `wr-risk-scorer-restage-commit` helper enforces atomic re-stage + commit + non-empty cached diff in a single bash call (P326). Adopter-safe via the ADR-049 `$PATH` shim — never repo-relative `packages/...` sourcing from a SKILL (P317/RFC-009).

2. **Investigation Task #2** (*"Verify all manage-problem update-ticket flows commit per ADR-014; close as resolved if so, OR identify remaining gaps and fix"*) is satisfied — verification at this closure confirmed every write path (Step 5 new / Step 6 update / Step 7 transitions / Step 11 commit / capture-problem Step 6) commits per ADR-014 single-commit grain. No gap identified.

3. **Investigation Task #1** (Priority/Effort re-rate at next `/wr-itil:review-problems`) is moot at closure — Closed tickets are excluded from WSJF ranking.

**Why "no further work" instead of "still pending"**: P222 (2026-05-15) pre-dates ADR-014 acceptance. The ticket body's own note already flagged the resolution path (*"may already be largely resolved by ADR-014's acceptance; verify and close as duplicate / resolved if so"*). This closure performs the verification and confirms no residual gap. The "update-ticket" sub-flow named in the original Description does not exist as a separate skill; it is the inline Step 6 path which is covered.

No code change in this transition; KE→Closed direct per ADR-079 lifecycle extension (bypasses Verifying when no fix is released in this commit). Upstream issue https://github.com/windyroad/agent-plugins/issues/61 should be closed with the same resolution body. Reversible via `/wr-itil:transition-problem 222 known-error`.

## Description

The `wr-itil:manage-problem` skill (and its `update-ticket` sub-flow) writes the problem-ticket markdown file but explicitly does not commit. The note says "the user will commit when ready." In practice this means after every `/problem` invocation the file sits unstaged until the maintainer remembers to commit, breaking the AFK promise that ticket lifecycle changes are durable.

Note: ADR-014 (governance skills commit their own work) was accepted AFTER this report was filed. The current `/wr-itil:manage-problem` Step 11 + `/wr-itil:capture-problem` Step 6 DO commit per ADR-014. This ticket may already be largely resolved by ADR-014's acceptance; verify and close as duplicate / resolved if so.

## Workaround

ADR-014's acceptance closed this gap for new-ticket-creation + transitions. Audit any update-ticket flow that hasn't yet adopted ADR-014.

## Impact Assessment

- **Severity**: Low (already largely resolved by ADR-014).

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Verify all manage-problem update-ticket flows commit per ADR-014; close as resolved if so, OR identify remaining gaps and fix.

## Related

- **Reported Upstream**: https://github.com/windyroad/agent-plugins/issues/61
- **Pipeline classification**: safe-low-fix-risk; route=safe-and-valid.
- **Affected plugin**: @windyroad/itil.
- **Likely resolved by**: ADR-014.
