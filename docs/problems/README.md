# Problem Backlog

> Last reviewed: 2026-04-19 (AFK iter 3 — P051 shipped: run-retro extended with improvement axis — 6 improvement-shaped options + Kind column + concern-boundary splitting + non-interactive Kind recording; 5 new P051 structural tests RED→GREEN; 246/246 project tests pass. Iter 2: P050; iter 1: P047).
> Run `/wr-itil:manage-problem review` to refresh WSJF rankings.

## WSJF Rankings

| WSJF | ID | Title | Severity | Status | Effort |
|------|-----|-------|----------|--------|--------|
| 18.0 | P029 | Edit gate overhead for governance docs | 9 Med | Known Error | S |
| 12.0 | P021 | Governance skill structured prompts | 12 High | Known Error | M |
| 8.0 | P020 | No on-demand assessment skills | 16 High | Known Error | L |
| 8.0 | P044 | run-retro does not recommend new skills when it should | 8 Med | Known Error | M |
| 8.0 | P050 | run-retro does not recommend new agents, hooks, or other codifiable outputs (generalises P044) | 8 Med | Known Error | M |
| 8.0 | P051 | run-retro does not recommend improvements to existing skills, agents, hooks, or other codifiables | 8 Med | Known Error | M |
| 6.0 | P047 | WSJF effort buckets coarse and not re-rated at lifecycle transitions | 6 Med | Known Error | M |
| 4.5 | P016 | manage-problem should split multi-concern tickets | 9 Med | Known Error | M |
| 4.5 | P017 | create-adr should split multi-decision records | 9 Med | Known Error | M |
| 4.5 | P033 | No persistent risk register for ISO 31000 / ISO 27001 | 9 Med | Known Error | L |
| 4.0 | P024 | Risk-scorer WIP flag uncommitted completed work | 8 Med | Known Error | L |
| 4.0 | P048 | manage-problem does not surface Fix Released tickets as verification candidates | 8 Med | Open | M |
| 4.0 | P049 | Known Error status overloaded — "fix released, awaiting verification" deserves its own status | 8 Med | Open | M |
| 4.0 | P053 | work-problems does not surface outstanding design questions at stop-condition #2 | 8 Med | Open | M |
| 2.25 | P015 | TDD vague Gherkin outcome steps | 9 Med | Open | L |
| 2.0 | P018 | TDD enforce BDD + Example Mapping principles | 16 High | Open | XL ↑ |
| 2.0 | P022 | Agents must not fabricate time estimates | 16 High | Open | XL ↑ |
| 2.0 | P046 | wr-architect agent misses performance implications on high-traffic endpoints | 8 Med | Open | L |
| 1.5 | P014 | No lightweight aside invocation for governance skills | 12 High | Open | XL ↑ |
| 1.5 | P019 | Deprecate single-file JTBD fallback | 6 Med | Open | L |
| 1.5 | P045 | Auto plugin install after governance release (deferred) | 6 Med | Open | L |
| 0.75 | P012 | Skill testing harness scope undefined | 6 Med | Open | XL ↑ |
| 0.75 | P034 | Centralise risk reports for cross-project skill improvement | 6 Med | Open | XL ↑ |

Legend: ↑ = effort bucket re-rated upward in this review (P047 closure, 2026-04-19).

## Known Errors (Fix Released — pending user verification)

| ID | Title | Released in |
|----|-------|-------------|
| P016 | manage-problem should split multi-concern tickets | 2026-04-17 |
| P017 | create-adr should split multi-decision records | 2026-04-17 |
| P020 | No on-demand assessment skills | v0.3.2 |
| P021 | Governance skill structured prompts | v0.3.2 |
| P024 | Risk-scorer WIP flag uncommitted completed work | 2026-04-17 |
| P029 | Edit gate overhead for governance docs | commit ac9d453 |
| P033 | No persistent risk register for ISO 31000 / ISO 27001 | 2026-04-17 |
| P044 | run-retro does not recommend new skills when it should | @windyroad/retrospective@0.1.6 (commit 6510b29) — local plugin cache still at 0.1.5 until re-install, so this session couldn't exercise the fix; user verification needed after plugin re-install |
| P035 | manage-problem commit-gate no subagent delegation fallback | pending user verification — fallback path never fired this session (primary `wr-risk-scorer:pipeline` subagent was always available) |
| P047 | WSJF effort buckets coarse and not re-rated at lifecycle transitions | 2026-04-19 (AFK iter 1 commit 5c677cc) — next `manage-problem review` or `work-problems` iteration exercises the new XL bucket and the step 7 / step 9b re-rate language; user verification needed at that point |
| P050 | run-retro generalises codification branch from skill-only to 12 shapes | 2026-04-19 (AFK iter 2 commit pending) — next `/wr-retrospective:run-retro` invocation should present the generalised Step 2 prompt and the flat shape-prefixed Step 4b `AskUserQuestion`; user verification needed at that point. |
| P051 | run-retro extended with improvement axis (6 improvement-shaped options + Kind column + concern-boundary splitting) | 2026-04-19 (AFK iter 3, pending commit) — next `/wr-retrospective:run-retro` invocation should present Step 2's improvement reflection category, a 19-option flat `AskUserQuestion` at Step 4b (12 create + 6 improve + 1 skip), and a Kind column in the Step 5 Codification Candidates table. User verification needed at that point. |

## Closed

Recently closed this session (2026-04-19, against direct in-session evidence):

| ID | Title | Closed via |
|----|-------|-----------|
| P026 | install-utils duplicated across packages | CI `check:install-utils` passed on every push this session |
| P031 | Stale cache detection in manage-problem work | Returned correct output at AFK loop start and after subsequent commits |
| P040 | work-problems does not fetch origin before starting | `git fetch origin` ran at AFK loop start per orchestrator spec |
| P041 | work-problems does not enforce release cadence | `assess-release` ran after each iteration with correct scores |
| P042 | changesets does not sync plugin manifest version | End-to-end validated in the 2026-04-19 release (PR #30 contained paired plugin.json entries after P052 fix) |
| P043 | Next-ID collision guard in ticket-creator skills | `max(local, origin)+1` used for 10 new IDs this session (8 problems + 2 ADRs) |
| P052 | ADR-021 release.yml missing `version:` input | End-to-end validated in the 2026-04-19 release; paired with P042's closure |
| P028 | Governance skills should auto-release (non-AFK) | Verified end-to-end in the 2026-04-19 AFK loop iter 2: push of `f0de540` triggered Release workflow → PR #31 auto-created with version bumps and plugin.json manifest syncs → `release:watch` merged and published both `@windyroad/itil@0.4.5` and `@windyroad/retrospective@0.2.0` to npm (run `24619740990`, merge commit `b401c7b`). No manual intervention within the AFK loop. |

## Parked

| ID | Title | Reason | Parked since |
|----|-------|--------|-------------|
| P005 | Connect setup skill doesn't match Discord plugin | Upstream: same --channels bug as P007/P008 — all connect work suspended | 2026-04-16 |
| P007 | Discord inbound reactions not delivered | Upstream: Discord channel plugin doesn't forward reaction events | 2026-04-16 |
| P008 | AskUserQuestion unavailable with --channels | Upstream: Anthropic `--channels` flag removes AskUserQuestion | 2026-04-16 |
