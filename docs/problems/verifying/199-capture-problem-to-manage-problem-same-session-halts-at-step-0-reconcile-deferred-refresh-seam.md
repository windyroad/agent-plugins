# Problem 199: capture-problem → manage-problem same-session halts at Step 0 reconcile (HALT_ROUTE_RECONCILE on deferred-refresh seam)

**Status**: Verification Pending
**Reported**: 2026-05-15
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Description

`/wr-itil:capture-problem` followed by `/wr-itil:manage-problem` (or `/wr-itil:work-problem`) on the same ticket in the same session halts at manage-problem's Step 0 reconcile preflight. capture-problem defers `docs/problems/README.md` refresh by design (its trailing pointer: *"Run /wr-itil:review-problems next to fold P<NNN> into the WSJF rankings"*), but the subsequent manage-problem invocation immediately runs the Step 0 preflight reconcile and detects the just-captured ticket as MISSING from WSJF Rankings → `wr-itil-reconcile-readme` exits 1 with `MISSING  P<NNN> wsjf-rankings: actual=open`; `wr-itil-classify-readme-drift` returns `classify_exit=1 HALT_ROUTE_RECONCILE` (the "committed cross-session drift" class — the capture-problem commit landed without staging a README refresh, which fits the classifier's pattern literally even though it's the same session).

The fix-forward path requires invoking `/wr-itil:reconcile-readme` first, committing the README refresh in its own commit, then re-running manage-problem / work-problem. This adds an extra round-trip on the natural capture-then-work flow. Observed twice in the 2026-05-14 P220 session: capture → work-problem halt → reconcile → manage-problem halt → reconcile.

**Note: this monorepo session (2026-05-15) inverted the precedent**: the P165 README-refresh-discipline hook now BLOCKS the capture-problem commit unless README is staged. So in this monorepo, capture-problem can no longer commit without README — the deferred-refresh contract has been silently broken by P165. See P197 commit message + this ticket's Notes for the contract-conflict trail. Two reasonable resolutions: (a) update capture-problem SKILL.md Step 6 to acknowledge P165 takes precedence and stage README; (b) update P165 hook to recognise capture-problem commits and waive the refresh requirement.

## Symptoms

- `wr-itil-reconcile-readme docs/problems` exits 1 reporting `MISSING  P<NNN> wsjf-rankings: actual=open` after the capture-problem commit.
- `wr-itil-classify-readme-drift` returns exit 1 (HALT_ROUTE_RECONCILE).
- manage-problem (and work-problem, which dispatches manage-problem) halts with the directive to invoke `/wr-itil:reconcile-readme` first.

## Workaround

Three viable paths: (1) Run `/wr-itil:review-problems` between capture-problem and manage-problem; (2) Run `/wr-itil:reconcile-readme` on the halt; (3) Use `/wr-itil:manage-problem` directly for capture (skipping capture-problem) — loses the capture-problem speed advantage.

## Impact Assessment

- **Who is affected**: every maintainer using the capture-then-work flow.
- **Frequency**: deterministic on the canonical capture-then-work pattern.
- **Severity**: Moderate (adds friction; not a load-bearing block).

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Decide on Option 1 OR Option 2 OR Option 3 — **DECIDED 2026-05-31 (user direction)**: Option 2 (kill deferred-refresh; stage README in capture-problem). User reasoning: the P165 hook already blocks capture-problem commits without README, so the deferred-refresh contract is already half-superseded; Option 2 acknowledges reality rather than working around the contradiction.
- [x] Reconcile with P165 in-monorepo precedent — **DECIDED 2026-05-31 (user direction)**: keep P165; update capture-problem SKILL.md Step 6 to stage README inline (consistent with Option 2 above). No rollback of P165.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P149 (uncommitted-rename carve-out — symmetric precedent), P165 (README-refresh-discipline hook — supersedes capture-problem Step 6 deferred-refresh in this monorepo), P094 (manage-problem inline README refresh), P062 (transition README refresh), P118 (README reconciliation preflight)

## Fix Strategy

Option 2 (user direction recorded 2026-05-31): kill the deferred-README-refresh contract; `/wr-itil:capture-problem` Step 6 stages `docs/problems/README.md` inline (mirroring `/wr-itil:manage-problem` Step 5 P094 refresh-on-create + P134 last-reviewed rotation). The `RISK_BYPASS: capture-deferred-readme` trailer is dropped from capture commits (no longer needed because the P165 README-refresh hook is satisfied by inline staging). ADR-032 § Foreground-lightweight-capture variant cost-shape amended to reflect inline refresh. ADR-014 bypass-token table row amended: trailer no longer emitted; allow-list entry retained as inert dead code for adopter compatibility per minimal-change discipline.

**Why Option 2 (not Option 1 — keep deferred + waive P165 for capture commits)**: the P165 hook always felt half-superseded by the deferred-refresh contract. Option 2 acknowledges P165 reality and aligns capture-problem's commit shape with manage-problem's P094 path — the capture-time speed distinction comes from capture-problem skipping the wide-net duplicate grep + AskUserQuestion branches, not the README skip. The P262 workaround (allow-list trailer) is superseded — no longer emitted by capture-problem, but the inert allow-list entry stays for adopters that may have registered against it.

**Surfaces touched** (single coherent commit per ADR-014):
- `packages/itil/skills/capture-problem/SKILL.md` — frontmatter description + Step 6 body + Step 7 trailing pointer + composition table + Related section.
- `packages/itil/skills/capture-problem/REFERENCE.md` — Deferred-README-refresh contract subsection rewritten as "README refresh: inline (P199 Option 2 amendment 2026-06-05)".
- `docs/decisions/032-governance-skill-invocation-patterns.proposed.md` — Foreground-lightweight-capture variant cost-shape + deferred-README-refresh bullet amended.
- `docs/decisions/014-governance-skills-commit-their-own-work.proposed.md` — bypass-token table row + paragraph amended (trailer-no-longer-emitted note + inert-entry-retained discipline).
- `docs/decisions/README.md` — compendium regenerated.
- `docs/problems/README.md` — P062 inline refresh covering P199 known-error → verifying transition.
- `docs/problems/README-history.md` — line-3 rotation per P134.
- `.changeset/<slug>.md` — `@windyroad/itil` patch.

## Fix Released

Awaiting release of `@windyroad/itil <next-patch>`. Capture-problem Step 6 now stages `docs/problems/README.md` inline (P094 mirror); the `RISK_BYPASS: capture-deferred-readme` trailer is dropped from capture commits; ADR-032 cost-shape amended; ADR-014 bypass-token-table row amended; inert allow-list entry retained in `readme-refresh-detect.sh`. Verification: invoke `/wr-itil:capture-problem <description>` and confirm (a) the resulting `docs(problems): capture P<NNN> <title>` commit lands without the P165 deny, (b) `docs/problems/README.md` is staged + committed alongside the new ticket file, (c) no `RISK_BYPASS: capture-deferred-readme` trailer in the commit message, (d) subsequent `/wr-itil:manage-problem` / `/wr-itil:work-problem` Step 0 reconcile does NOT halt on the just-captured ticket. Orchestrator Step 6.5 drains the release.

## Related

- **Reported Upstream**: https://github.com/windyroad/agent-plugins/issues/126 (filed 2026-05-13 from downstream windyroad/bbstats project ticket P221).
- **Pipeline classification** (review-problems Step 4.5e): JTBD-alignment=aligned-with-existing-JTBD (JTBD-006 + JTBD-001); dual-axis-risk=safe-low-fix-risk; route=safe-and-valid.
- **Affected plugin**: @windyroad/itil.
