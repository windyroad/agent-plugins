# Problem Backlog

> Last reviewed: 2026-04-20 (AFK iter 6 close — P066 + P063 + P068 + P062 + P060 all shipped and in Verification Pending; P065 re-rated M → L; follow-up P072 opened for the JTBD persona gap. 17 open tickets ranked. Direction pins still hold on P014, P064, P065, P067.
> Run `/wr-itil:manage-problem review` to refresh WSJF rankings.

## WSJF Rankings

Dev-work queue only. Verification Pending (`.verifying.md`, WSJF multiplier 0) and Parked (`.parked.md`, multiplier 0) tickets are excluded per ADR-022 — surfaced in their own sections below.

| WSJF | ID | Title | Severity | Status | Effort |
|------|-----|-------|----------|--------|--------|
| 6.0 | P070 | report-upstream does not check for existing upstream issues before filing | 12 High | Open | M |
| 6.0 | P071 | Argument-based skill subcommands are not discoverable in Claude Code autocomplete | 12 High | Open | M |
| 4.5 | P067 | report-upstream classifier is not problem-first | 9 Med | Open | M |
| 4.0 | P061 | install-updates Step 6 consent-gate violates AskUserQuestion 4-option cap when siblings > 3 | 4 Low | Open | S |
| 3.75 | P069 | docs/problems/ flat layout is unskimmable — migrate to per-state subdirectories | 15 High | Open | L |
| 3.0 | P014 | No lightweight aside invocation for governance skills (background-subagent convention per 2026-04-20 direction) | 12 High | Open | L |
| 3.0 | P064 | No risk-scoring gate on external communications | 12 High | Open | L |
| 3.0 | P065 | No skill scaffolds intake files in downstream projects (re-rated M → L per architect direction) | 12 High | Open | L |
| 2.25 | P015 | TDD enforcement does not flag vague Gherkin outcome steps | 9 Med | Open | L |
| 2.25 | P072 | No persona in docs/jtbd/ models the external repo reporter | 9 Med | Open | M |
| 2.0 | P018 | TDD enforce BDD + Example Mapping principles | 16 High | Open | XL |
| 2.0 | P022 | Agents must not fabricate time estimates | 16 High | Open | XL |
| 2.0 | P039 | Autonomous loops conflate diagnose with implement | 16 High | Open | XL |
| 1.5 | P038 | No voice-and-tone gate on external communications | 12 High | Open | XL |
| 1.5 | P045 | Auto plugin install after governance release (deferred install on next session start per 2026-04-20 direction) | 6 Med | Open | L |
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
| P035 | manage-problem commit-gate no subagent delegation fallback | pending — fallback path never fired this session | no (not yet released to npm — user-verifiable only after a session exercises the fallback) |
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
| P057 | git mv + Edit + git add staging-ordering trap drops content edits | @windyroad/itil@0.7.2 + @windyroad/architect@0.4.1 (commit 3bf2074) | no (0 days) |
| P056 | Ticket-creator next-ID lookup greps blob SHAs producing wrong origin_max | @windyroad/itil@0.7.2 + @windyroad/architect@0.4.1 (commit f9bfa56) | no (0 days) |
| P019 | Deprecate single-file JTBD fallback (ADR-008 Option 3) | @windyroad/jtbd@0.6.0 (commit 6dd6a77) — breaking change | no (0 days) |
| P058 | install-updates regex misses digit-bearing plugin names | commit 3798be8 | no (0 days) |
| P059 | install-updates no plugin rename handling | commit 3261d81 | no (0 days) |
| P066 | Intake templates problem-first (bug-report + feature-request replaced by problem-report) | commit ed36f69 (AFK iter 6 iter 1) | no (0 days) |
| P063 | manage-problem trigger-surface wired to /wr-itil:report-upstream | commit 6ee6adc (AFK iter 6 iter 2) | no (0 days) |
| P068 | run-retro Verification-close housekeeping (Step 4a) | commit c268327 (AFK iter 6 iter 3) | no (0 days) |
| P062 | manage-problem README refresh on transitions (Step 7 + Step 11) | commit 7e19eab (AFK iter 6 iter 4) | no (0 days) |
| P060 | push:watch anchors on HEAD sha + loops all runs + propagates exit code | commit pending (AFK iter 6 iter 5) | no (0 days) |

## Closed

Recently closed this session (2026-04-19/20, against direct in-session evidence):

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
| P055 | No standard problem-reporting channel for plugin users | Closed 2026-04-20 (commit 038c3de). Part A (OSS intake scaffolding) + Part B (`/wr-itil:report-upstream` skill) both shipped; @windyroad/itil@0.8.0 released to npm. |

## Parked

| ID | Title | Reason | Parked since |
|----|-------|--------|-------------|
| P005 | Connect setup skill doesn't match Discord plugin | Upstream: same --channels bug as P007/P008 — all connect work suspended | 2026-04-16 |
| P007 | Discord inbound reactions not delivered | Upstream: Discord channel plugin doesn't forward reaction events | 2026-04-16 |
| P008 | AskUserQuestion unavailable with --channels | Upstream: Anthropic `--channels` flag removes AskUserQuestion | 2026-04-16 |
