# Problem Backlog

> Last reviewed: 2026-04-22 session — **P101 opened** (`wr-retrospective` has no context-usage analysis — opaque where session tokens are consumed; no guidance on what to trim; L, WSJF 3.0; user-proposed with codeburn as conceptual reference; subsumes P091's measurement-harness investigation task; preferred delivery: layered — cheap in run-retro + deep on demand). Prior context: **P057 + P095 closed** via run-retro Step 4a on in-session evidence (P057 staging-trap exercised 4x this session; P095 ADR-038 once-per-session behaviour observed ~15 prompts) + **P062 stale Verification-Queue row removed** (ticket was closed in a prior session; README wasn't refreshed at closure). Prior context: **P100 opened** (`wr-retrospective` does not auto-surface `docs/BRIEFING.md` at session start — cross-session learnings go unread in adopter projects; M, WSJF 10.0; user-identified during P098 verification — "we shouldn't have to add these things to CLAUDE.md. It should be automatic"; scoped narrowly to `wr-retrospective` after user clarification that `wr-itil`'s backlog stays on on-demand discovery). Prior context: **P099 opened** (docs/BRIEFING.md grows unbounded via run-retro appends; L, WSJF 3.75; composes with P098's progressive-disclosure cluster). Prior context: **P098 fix released → Verification Pending** (ADR-038 progressive-disclosure pattern applied to project/user-owned context contributors; in-repo fix: new project-level `CLAUDE.md` at repo root (24 lines, pointers only); `.claude/skills/install-updates/SKILL.md` split 238 → 149 lines / 13.5KB → 6.8KB with sibling REFERENCE.md; stale memory files pruned (project_state.md 12d old, project_jtbd_migration.md 7d old); BRIEFING note documents the SKILL+REFERENCE pattern as reference implementation for P097's expected generalisation ADR. ~/CLAUDE.md follow-up remains as user action). Prior context: **P095 fix released → Verification Pending** (ADR-038 "Progressive disclosure + once-per-session budget for UserPromptSubmit governance prose" landed with shared `session-marker.sh` helper, 5 per-plugin synced copies, 5 hook edits (architect-detect / jtbd-eval / tdd-inject with dynamic-state carve-out / style-guide-eval / voice-tone-eval), 45 new bats assertions across 7 new files; full suite 735/735 green; reclaims ~120KB / ~30k tokens per 30-turn 3-active-hook session). Prior context: **P091 split** into session-wide context budget meta (retitled + effort re-rated L → XL; WSJF 1.875) + P095 (now Verification Pending, was Known Error WSJF 7.5) + **P096 opened** (PreToolUse/PostToolUse hook injection cluster, L, WSJF 3.0 — ~25 hooks pending audit) + **P097 opened** (SKILL.md runtime size cluster, L, WSJF 3.0 — magnitude confirmed: manage-problem 55KB, work-problems 39KB, run-retro 36KB; fix path via progressive-disclosure REFERENCE.md split pending validation) + **P098 opened** (project/user-owned cluster: global `~/CLAUDE.md` + `.claude/skills/install-updates/SKILL.md` + MEMORY.md curation, M, WSJF 6.0). Unifying solution pattern across all four children: **progressive disclosure** — less info upfront with explicit affordances (agent pointers, REFERENCE.md paths, project-level CLAUDE.md) so the consumer can expand on demand. Prior context: 2026-04-22 session — **P029 + P059 closed** (verified in-session via run-retro Step 4a) + **P091 + P092 + P093 + P094 opened** (startup context; install-updates npm-name; transition-problem circular delegation; manage-problem README creation-refresh gap). Prior context: 2026-04-21 AFK iter 7 — **P076 transitioned to Verification Pending**: WSJF transitive-effort rule now lives inline in `/wr-itil:manage-problem`'s WSJF Prioritisation section. Full itil sweep: 340/340 green. Prior context (iter 7 iter 1): P067 classifier problem-first per ADR-033. Prior context (iter 6): P084 transitioned to Verification Pending; subprocess dispatch variant of ADR-032 now supersedes P077 Agent-tool variant on the Step 5 surface.
> Run `/wr-itil:manage-problem review` to refresh WSJF rankings.

## WSJF Rankings

Dev-work queue only. Verification Pending (`.verifying.md`, WSJF multiplier 0) and Parked (`.parked.md`, multiplier 0) tickets are excluded per ADR-022 — surfaced in their own sections below.

| WSJF | ID | Title | Severity | Status | Effort |
|------|-----|-------|----------|--------|--------|
| 15.0 | P092 | install-updates Step 4 `<plugin-short-name>` placeholder is ambiguous about the `wr-` prefix | 15 High | Open | S |
| 12.0 | P093 | transition-problem ↔ manage-problem circular delegation for `<NNN> <status>` args | 12 High | Open | S |
| 10.0 | P094 | manage-problem does not refresh README.md on ticket creation | 10 High | Open | S |
| 10.0 | P100 | `wr-retrospective` does not auto-surface `docs/BRIEFING.md` to the agent at session start — cross-session learnings go unread in adopter projects | 20 High | Open | M |
| 6.0 | P070 | report-upstream does not check for existing upstream issues before filing | 12 High | Open | M |
| 6.0 | P071 | Argument-based skill subcommands are not discoverable in Claude Code autocomplete | 12 High | Open | M |
| 6.0 | P074 | run-retro does not notice pipeline instability and record corresponding problem tickets | 12 High | Open | M |
| 6.0 | P078 | Assistant does not offer problem ticket on strong-signal user correction | 12 High | Open | M |
| 3.75 | P099 | `docs/BRIEFING.md` grows unbounded via run-retro appends — violates progressive disclosure | 15 High | Open | L |
| 3.0 | P101 | `wr-retrospective` has no context-usage analysis — opaque where session tokens are consumed; no guidance on what to trim | 12 High | Open | L |
| 3.0 | P014 | No lightweight aside invocation for governance skills (background-subagent convention per 2026-04-20 direction) | 12 High | Open | L |
| 3.0 | P064 | No risk-scoring gate on external communications | 12 High | Open | L |
| 3.0 | P065 | No skill scaffolds intake files in downstream projects (re-rated M → L per architect direction) | 12 High | Open | L |
| 3.0 | P096 | PreToolUse / PostToolUse hook injection volume across windyroad plugins — unaudited | 12 High | Open | L |
| 3.0 | P097 | SKILL.md files mix runtime-necessary steps with maintainer-facing rationale, bloating every skill invocation | 12 High | Open | L |
| 2.25 | P015 | TDD enforcement does not flag vague Gherkin outcome steps | 9 Med | Open | L |
| 2.0 | P018 | TDD enforce BDD + Example Mapping principles | 16 High | Open | XL |
| 2.0 | P022 | Agents must not fabricate time estimates | 16 High | Open | XL |
| 2.0 | P039 | Autonomous loops conflate diagnose with implement | 16 High | Open | XL |
| 1.875 | P069 | docs/problems/ flat layout is unskimmable — migrate to per-state subdirs + auto-migrate adopter repos (re-rated L → XL 2026-04-20 after auto-migration scope add) | 15 High | Open | XL |
| 1.875 | P091 | Session-wide context budget — Claude Code consumes substantial context before and during every session across all contributor surfaces (meta) | 15 High | Open | XL |
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
| P056 | Ticket-creator next-ID lookup greps blob SHAs producing wrong origin_max | @windyroad/itil@0.7.2 + @windyroad/architect@0.4.1 (commit f9bfa56) | no (0 days) |
| P019 | Deprecate single-file JTBD fallback (ADR-008 Option 3) | @windyroad/jtbd@0.6.0 (commit 6dd6a77) — breaking change | no (0 days) |
| P058 | install-updates regex misses digit-bearing plugin names | commit 3798be8 | no (0 days) |
| P066 | Intake templates problem-first (bug-report + feature-request replaced by problem-report) | commit ed36f69 (AFK iter 6 iter 1) | no (0 days) |
| P063 | manage-problem trigger-surface wired to /wr-itil:report-upstream | @windyroad/itil@0.9.0 (commit 6ee6adc) | no (0 days) |
| P068 | run-retro Verification-close housekeeping (Step 4a) | @windyroad/retrospective@0.4.0 (commit c268327) | no (0 days) |
| P060 | push:watch anchors on HEAD sha + loops all runs + propagates exit code | commit 4b3d20e (AFK iter 6 iter 5 — repo-internal root script) | no (0 days) |
| P061 | install-updates Step 6 grouping fallback for siblings > 3 | commit b6ba3bd (AFK iter 6 iter 6 — repo-local skill) | no (0 days) |
| P072 | plugin-user persona + JTBD-301 ship; closes external-reporter JTBD gap | commit pending (post-AFK interactive) | no (0 days) |
| P075 | run-retro Step 4b ticket-first two-stage flow (19-option → 4-option per ticket) | commit pending (this AFK iter) | no (0 days) |
| P077 | work-problems Step 5 delegates iterations via the Agent tool (`subagent_type: general-purpose`); ADR-032 amended with AFK iteration-isolation wrapper sub-pattern | commit pending (this AFK iter) | no (0 days) |
| P084 | work-problems iteration worker has no Agent tool — `claude -p` subprocess dispatch closes the tool-surface gap (ADR-032 subprocess-boundary sub-pattern) | @windyroad/itil@0.13.0 (commit 260768f) + @windyroad/itil@0.14.0 (commit 7670ffb, cost logging) | no (0 days) |
| P086 | AFK iteration subprocess runs `/wr-retrospective:run-retro` before emitting `ITERATION_SUMMARY` (ADR-032 subprocess-boundary retro-on-exit clause) | commit pending (this AFK iter 7 iter 5) | no (0 days) |
| P067 | /wr-itil:report-upstream classifier is problem-first (ADR-033 partial supersession of ADR-024 Steps 3 + 5) | commit pending (this AFK iter 7) | no (0 days) |
| P076 | WSJF scoring models transitive dependencies (methodology gap — rule now inline in manage-problem SKILL.md + Step 2.5 traversal in review-problems) | commit pending (this AFK iter 7 iter 2) | no (0 days) |
| P098 | Project-owned and user-owned context contributors — global `~/CLAUDE.md`, local `.claude/skills/`, and memory index | 2026-04-22 (progressive-disclosure project CLAUDE.md + install-updates SKILL+REFERENCE split + stale memory pruning; ~/CLAUDE.md follow-up for user; amendment trimmed redundant CLAUDE.md pointers 2026-04-22) | no (0 days) |

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
| P029 | Edit gate overhead for governance docs | Closed 2026-04-22 (run-retro Step 4a). Every UserPromptSubmit hook message this session carried the governance-docs exclusion line (docs/problems/, docs/BRIEFING.md, RISK-POLICY.md, .changeset/); edits to docs/problems/091-*.open.md, docs/problems/092-*.open.md, and docs/BRIEFING.md all proceeded without demanding architect/JTBD review. Fix contract (ac9d453, 2026-04-17) held end-to-end. |
| P059 | install-updates no plugin rename handling | Closed 2026-04-22 (run-retro Step 4a). This session's `/install-updates` Read rename-mapping.json, scanned all 6 projects for enabled keys matching `renames[].from` (zero stale — no sibling has `wr-problem`), and emitted the transparency line "No rename migrations applied this run." per the ADR-030 Confirmation amendment. |
| P057 | git mv + Edit + git add staging-ordering trap drops content edits | Closed 2026-04-22 (run-retro Step 4a). Rule exercised 4 times this session (P098 .open→.known-error, P098 .known-error→.verifying, P099 creation, P100 creation); explicit re-stage after Edit held contract — no content leaked to subsequent commits. |
| P062 | manage-problem README refresh on transitions | Already closed in a prior session (verified in AFK-iter-7); this run-retro removed a stale Verification-Queue row that had not been cleaned up at the prior closure. |
| P095 | UserPromptSubmit hooks re-emit full MANDATORY prose on every prompt | Closed 2026-04-22 (run-retro Step 4a). ADR-038 once-per-session + terse-reminder contract observed across ~15 user prompts this session: turn 1 emitted full ~4.2KB MANDATORY blocks for architect/JTBD/TDD; turns 2+ emitted ≤150-byte terse reminders. wr-tdd continued emitting dynamic state per-prompt per the ADR-038 carve-out. |

## Parked

| ID | Title | Reason | Parked since |
|----|-------|--------|-------------|
| P005 | Connect setup skill doesn't match Discord plugin | Upstream: same --channels bug as P007/P008 — all connect work suspended | 2026-04-16 |
| P007 | Discord inbound reactions not delivered | Upstream: Discord channel plugin doesn't forward reaction events | 2026-04-16 |
| P008 | AskUserQuestion unavailable with --channels | Upstream: Anthropic `--channels` flag removes AskUserQuestion | 2026-04-16 |
