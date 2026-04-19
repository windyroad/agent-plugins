# Problem Backlog

> Last reviewed: 2026-04-20 (AFK iter 1 review — three new tickets filed since prior review: P055 (problem-reporting channel), P056 (next-ID blob-SHA false match), P057 (git mv + Edit staging trap). P046 transitioned to Verification Pending after runtime-path performance review fix released (commit b2f1646). P054 transitioned to Verification Pending after stable drift hash fix released (commit 45e9c71). P036 and P037 newly transitioned to Verification Pending (commits c5f8039, 6e7c2e4). Missing WSJF lines added for P015, P038, P039.
> Run `/wr-itil:manage-problem review` to refresh WSJF rankings.

## WSJF Rankings

Dev-work queue only. Verification Pending (`.verifying.md`, WSJF multiplier 0) and Parked (`.parked.md`, multiplier 0) tickets are excluded per ADR-022 — surfaced in their own sections below.

| WSJF | ID | Title | Severity | Status | Effort |
|------|-----|-------|----------|--------|--------|
| 6.0 | P057 | git mv + Edit + git add staging-ordering trap drops content edits | 6 Med | Open | S |
| 4.0 | P056 | Ticket-creator next-ID lookup greps blob SHAs producing wrong origin_max | 4 Low | Open | S |
| 2.25 | P015 | TDD enforcement does not flag vague Gherkin outcome steps | 9 Med | Open | L |
| 2.0 | P018 | TDD enforce BDD + Example Mapping principles | 16 High | Open | XL |
| 2.0 | P022 | Agents must not fabricate time estimates | 16 High | Open | XL |
| 2.0 | P039 | Autonomous loops conflate diagnose with implement | 16 High | Open | XL |
| 1.5 | P014 | No lightweight aside invocation for governance skills | 12 High | Open | XL |
| 1.5 | P019 | Deprecate single-file JTBD fallback | 6 Med | Open | L |
| 1.5 | P038 | No voice-and-tone gate on external communications | 12 High | Open | XL |
| 1.5 | P045 | Auto plugin install after governance release (deferred) | 6 Med | Open | L |
| 1.125 | P055 | No standard problem-reporting channel for plugin users | 9 Med | Open | XL |
| 0.75 | P012 | Skill testing harness scope undefined | 6 Med | Open | XL |
| 0.75 | P034 | Centralise risk reports for cross-project skill improvement | 6 Med | Open | XL |

## Verification Queue

Fix released, awaiting user verification (driven off `docs/problems/*.verifying.md` via glob per ADR-022). Ranked by release age, oldest first. `Likely verified?` column marks tickets ≥14 days old (P048 Candidate 4 default).

| ID | Title | Released | Likely verified? |
|----|-------|----------|------------------|
| P016 | manage-problem should split multi-concern tickets | 2026-04-17 | no (3 days) |
| P017 | create-adr should split multi-decision records | 2026-04-17 | no (3 days) |
| P024 | Risk-scorer WIP flag uncommitted completed work | 2026-04-17 | no (3 days) |
| P033 | No persistent risk register for ISO 31000 / ISO 27001 | 2026-04-17 | no (3 days) |
| P029 | Edit gate overhead for governance docs | 2026-04-17 (ac9d453) | no (3 days) |
| P020 | No on-demand assessment skills | v0.3.2 | no (age unknown — pre-v0.3.2 release date) |
| P021 | Governance skill structured prompts | v0.3.2 | no (age unknown) |
| P035 | manage-problem commit-gate no subagent delegation fallback | pending — fallback path never fired this session (primary subagent always available) | no (not yet released to npm — user-verifiable only after a session exercises the fallback) |
| P044 | run-retro does not recommend new skills when it should | @windyroad/retrospective@0.1.6 (commit 6510b29) | no (1 day) |
| P047 | WSJF effort buckets coarse and not re-rated at lifecycle transitions | 2026-04-19 (AFK iter 1 commit 5c677cc) | no (1 day) |
| P050 | run-retro generalises codification branch from skill-only to 12 shapes | @windyroad/retrospective@0.2.0 (b401c7b) | no (1 day) |
| P051 | run-retro extended with improvement axis (12 create + 6 improve shapes) | @windyroad/retrospective@0.3.0 (4a107a3) | no (1 day) |
| P053 | work-problems surfaces outstanding design questions at stop-condition #2 | @windyroad/itil@0.5.0 (a0600d9) | no (1 day) |
| P049 | Verification Pending `.verifying.md` status — SKILL.md contract + migration | @windyroad/itil@0.6.0 (5b9aa96) | no (1 day) |
| P048 | manage-problem Verification Queue detection: fast-path 9d + `Likely verified?` column | 2026-04-19 (pending commit) | no (1 day) |
| P054 | release:watch requires stable drift hash across push | commit 45e9c71 | no (1 day) |
| P046 | wr-architect agent misses runtime-path performance implications | commit b2f1646 | no (1 day) |
| P037 | jtbd-reviewer returns bare verdict without reason | commit 6e7c2e4 | no (1 day) |
| P036 | work-problems commit-gate: inter-iteration verification | commit c5f8039 | no (1 day) |

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
