# Problem Backlog

> Last reviewed: 2026-04-19 (AFK iter 6 — P048 minimal-scope fix shipped: fast-path step 9d always fires; Verification Queue gains `Likely verified?` column with 14-day release-age default. Candidates 2/3/5 deferred pending architect ADR-scope decision. 5 new P048 tests RED→GREEN; 269/269 project tests pass. Iter 5: P049 contract + migration (retrospective/itil merged); iter 4: P053; iter 3: P051; iter 2: P050; iter 1: P047).
> Run `/wr-itil:manage-problem review` to refresh WSJF rankings.

## WSJF Rankings

Dev-work queue only. Verification Pending (`.verifying.md`, WSJF multiplier 0) and Parked (`.parked.md`, multiplier 0) tickets are excluded per ADR-022 — surfaced in their own sections below.

| WSJF | ID | Title | Severity | Status | Effort |
|------|-----|-------|----------|--------|--------|
| 2.25 | P015 | TDD vague Gherkin outcome steps | 9 Med | Open | L |
| 2.0 | P018 | TDD enforce BDD + Example Mapping principles | 16 High | Open | XL |
| 2.0 | P022 | Agents must not fabricate time estimates | 16 High | Open | XL |
| 2.0 | P046 | wr-architect agent misses performance implications on high-traffic endpoints | 8 Med | Open | L |
| 1.5 | P014 | No lightweight aside invocation for governance skills | 12 High | Open | XL |
| 1.5 | P019 | Deprecate single-file JTBD fallback | 6 Med | Open | L |
| 1.5 | P045 | Auto plugin install after governance release (deferred) | 6 Med | Open | L |
| 0.75 | P012 | Skill testing harness scope undefined | 6 Med | Open | XL |
| 0.75 | P034 | Centralise risk reports for cross-project skill improvement | 6 Med | Open | XL |

## Verification Queue

Fix released, awaiting user verification (driven off `docs/problems/*.verifying.md` via glob per ADR-022). Ranked by release age, oldest first:

| ID | Title | Released in |
|----|-------|-------------|
| P016 | manage-problem should split multi-concern tickets | 2026-04-17 |
| P017 | create-adr should split multi-decision records | 2026-04-17 |
| P024 | Risk-scorer WIP flag uncommitted completed work | 2026-04-17 |
| P033 | No persistent risk register for ISO 31000 / ISO 27001 | 2026-04-17 |
| P020 | No on-demand assessment skills | v0.3.2 |
| P021 | Governance skill structured prompts | v0.3.2 |
| P029 | Edit gate overhead for governance docs | commit ac9d453 |
| P035 | manage-problem commit-gate no subagent delegation fallback | pending user verification — fallback path never fired this session (primary `wr-risk-scorer:pipeline` subagent was always available) |
| P044 | run-retro does not recommend new skills when it should | @windyroad/retrospective@0.1.6 (commit 6510b29) — local plugin cache still at 0.1.5 until re-install, so earlier session couldn't exercise the fix; user verification needed after plugin re-install |
| P047 | WSJF effort buckets coarse and not re-rated at lifecycle transitions | 2026-04-19 (AFK iter 1 commit 5c677cc) — next `manage-problem review` or `work-problems` iteration exercises the new XL bucket and the step 7 / step 9b re-rate language; user verification needed at that point |
| P050 | run-retro generalises codification branch from skill-only to 12 shapes | 2026-04-19 (AFK iter 2, @windyroad/retrospective@0.2.0, merge commit b401c7b) — next `/wr-retrospective:run-retro` invocation should present the generalised Step 2 prompt and the flat shape-prefixed Step 4b `AskUserQuestion`; user verification needed at that point. |
| P051 | run-retro extended with improvement axis (6 improvement-shaped options + Kind column + concern-boundary splitting) | 2026-04-19 (AFK iter 3, @windyroad/retrospective@0.3.0, commit 4a107a3) — next `/wr-retrospective:run-retro` invocation should present Step 2's improvement reflection category, a 19-option flat `AskUserQuestion` at Step 4b (12 create + 6 improve + 1 skip), and a Kind column in the Step 5 Codification Candidates table. User verification needed at that point. |
| P053 | work-problems surfaces outstanding design questions at stop-condition #2 | 2026-04-19 (AFK iter 4, @windyroad/itil@0.5.0, commit a0600d9) — next AFK loop that hits stop-condition #2 with ≥1 user-answerable skipped ticket should emit an `### Outstanding Design Questions` table in the final summary. User verification needed at that point. |
| P049 | Verification Pending `.verifying.md` status — SKILL.md contract + migration of 13 existing `.known-error.md` Fix-Released tickets per ADR-022 | 2026-04-19 (AFK iter 5, @windyroad/itil@0.6.0, commit 5b9aa96) — next `manage-problem review` invocation should present a dedicated Verification Queue section and target `.verifying.md` via glob in step 9d. User verification needed at that point. |
| P048 | manage-problem Verification Queue detection: fast-path fires step 9d; `Likely verified?` column with 14-day release-age default (candidates 1 + 4 minimal scope) | 2026-04-19 (AFK iter 6, pending commit) — next `manage-problem review` should show the `Likely verified?` column in the Verification Queue and fire step 9d even on fast-path. User verification needed at that point. Candidates 2/3/5 deferred pending ADR-scope decision. |

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
