# Session Retrospective — 2026-06-17 main turn (drain of outstanding-questions queue)

Second retro of the day. Covers the drain of `.afk-run-state/outstanding-questions.jsonl` (15 → 0): 5 moot entries pruned, 8 substance-confirm decisions ratified across 4 batched AskUserQuestion calls, P080 transitioned Verifying → Known Error to reopen Phase 2 work, P370 (new) captured for the turn-end-mid-background class. Single commit `a068719c`.

## Briefing Changes

- **Added** (to `docs/briefing/agent-hook-gate-quirks.md`):
  - "Outstanding-questions queue accumulates across AFK loops without an automatic drain surface" — codifies the recurring gap: P341's Step 2.4 Pre-ALL_DONE gate shipped 2026-06-01 but the gate's actual drain scope was insufficient (cross-session accumulation observed 2026-06-17). Workaround: invoke `/wr-architect:review-decisions` + `/wr-jtbd:confirm-jobs-and-personas` regularly + explicitly read the queue file at session start.
- **Removed**: none. Per-section scan ran; the 7 existing `agent-hook-gate-quirks.md` entries all remain operationally relevant.
- **Updated**: README index Topic Index `agent-hook-gate-quirks-archive.md` reference added (rotation pointer per P099).
- **README index refreshed**: archive-sibling pointer added; no Critical Points changes (the new entry is sub-Critical-Points).

Scan evidence: walked the briefing tree against this session's drain mechanics. The drain-cadence-gap observation IS session-new (P341's verification failure plus the iter-spanning accumulation evidence is the smoking gun). No existing entry covers it cleanly; new entry on `agent-hook-gate-quirks.md` was the right surface.

## Signal-vs-Noise Pass (P105)

| Entry | Topic file | Old score | New score | Classification | Citation |
|-------|-----------|-----------|-----------|----------------|----------|
| `find /tmp -name PATTERN` macOS-symlink gotcha | `docs/briefing/agent-hook-gate-quirks.md` | +2 | signal | signal | Re-cited during this turn's drain when P368 root-cause amendment was applied; reinforced by the dual-write workaround being the operational pattern. |
| `grep` em-dash binary-detection gotcha | `docs/briefing/agent-hook-gate-quirks.md` | +2 | signal | signal | Implicit re-exercise: I used `grep -a` patterns when verifying README state across multiple turns this session without falling back to bare `grep -c`. |
| "Four edit gates fire on every edit" (Critical Points) | `docs/briefing/README.md` | n/a | signal | signal | Fired multiple times during the P080 rename + P370 capture + drain commit (architect + JTBD + risk-scorer pipeline + external-comms gates all passed). |
| "AFK iteration-workers use `claude -p`" (Critical Points) | `docs/briefing/README.md` | n/a | signal | signal | Cited as the root-cause class for P370 (iter subprocess turn-end without auto-resume). |

**Critical Points changes**: none promoted/demoted this retro. The new drain-cadence-gap entry is sub-Critical-Points (sits in `agent-hook-gate-quirks.md` directly).

**Delete queue**: empty (no entries scored ≤ -3 this retro).

**Budget overflow**: none (Tier 1 untouched).

## Pipeline Instability

| Signal | Category | Citations | Decision |
|--------|----------|-----------|----------|
| Question-freshness drift in outstanding-questions queue — Batch 1 Q1 (RFC-014 sequencing concern) was queued iter-10 BEFORE Stories A+B+D landed atomically in commit `0e7222be`. By the time the drain ran, the deviation-approval question was moot but I asked it anyway; user push-back ("huh? this sounds terribly complex and wasteful") surfaced the staleness. Sibling to the per-question-staleness class P282 already documents for verifying tickets. | Skill-contract violations | Drain Bash invocation surveyed P337/RFC-014 state AFTER asking; the verification should have been BEFORE asking. User push-back at Batch 1 Q1 response. | Recorded in retro only. The drain skill doesn't have a per-question pre-flight currently; a fix-strategy improvement candidate (Step 4b Stage 2 Option 2 — improve drain skill prose). |
| Outstanding-questions queue accumulates across AFK loops without working automatic drain surface — 15 entries spanning iter-1 through iter-31 untouched until user pointed at the file 2026-06-17. P341's Step 2.4 gate is in source but the actual drain scope (cross-session vs same-session) is insufficient. | Skill-contract violations | P341 verification-failure observation amended this morning (commit `75fa321a`); evidence the user discovered the queue by directly pointing at the file in turn ~30 of this session, not via any orchestrator surface. | Already ticketed (P341 verifying, amended this morning). No new ticket; codified as briefing entry this retro for cross-session continuity. |
| External-comms gate fired correctly with redaction round-trip on 2 separate commits (P369 capture + drain commit). | Subagent-delegation friction | wr-risk-scorer:external-comms FAIL on `bbstats` project name (P369 commit), then PASS after redaction; PASS clean on the drain commit. | Working-as-designed; recorded for awareness. |
| Risk-scorer pipeline + voice-tone + external-comms all passed within appetite on the drain commit (3 separate subagent delegations + restage-commit helper firing cleanly). | None (counter-evidence) | RISK_SCORES commit=3 push=3 release=1; bypass=reducing; classification matched expected reducing-bypass criteria 2+3 on the drain. | No friction; counter-evidence that the multi-gate composition works at scale on a 12-file governance commit. |
| README inventory currency clean | (Step 2b advisory) | `wr-retrospective-check-readme-jtbd-currency` exit 0; TOTAL packages=13 drift_instances=0. | Clean. |

## Verification Candidates

(No new close candidates this retro. P341 verifying was AMENDED with the verification-failure observation this morning; not a close. P080 was transitioned Verifying → Known Error in this turn — explicit user-directed reopen, not a close. No other `.verifying.md` tickets were exercised successfully in-session with specific in-session citations.)

Prior-session evidence drain (Step 4a sub-step 9): deferred to dedicated drain pass; 173 verifying tickets in the Queue, full per-row cell-parse exceeds retro budget. Recommend `/wr-itil:review-problems` or a dedicated `/wr-itil:transition-problems` batch pass.

## Topic File Rotation Candidates

| Topic file | Bytes | Threshold | Proposed rotation | Decision |
|------------|-------|-----------|-------------------|----------|
| `docs/briefing/agent-hook-gate-quirks.md` | 5382 → 4252 | 5120 | split-by-date | **applied** — 4 oldest entries (2026-04-25 / 26 / 26 / 05-03 cohort) moved to `agent-hook-gate-quirks-archive.md` (2761 bytes). 3 newest entries remain in main file + new drain-cadence-gap entry added (4 total). README Topic Index pointer updated. |
| `docs/briefing/hooks-and-gates.md` | 5980 | 5120 | (none safely available) | **deferred** (carried forward from this morning's retro reasoning — every entry is load-bearing per Critical Points refs; split-by-date safe default would archive cited content). 17% overrun acceptable until either ratio passes 2.0× (Branch A forces) or Critical Points refs to the 2026-05-25 entries retire. |

## Context Usage (Cheap Layer)

| Bucket | Bytes | % of total | Δ vs prior |
|--------|-------|-----------:|-----------:|
| problems | 5,179,495 | 55.5% | +28,373 (+0.6%) |
| decisions | 1,959,897 | 21.0% | 0 |
| skills | 1,236,787 | 13.3% | 0 |
| hooks | 541,274 | 5.8% | 0 |
| memory | 444,670 | 4.8% | +2,241 (+0.5%) |
| briefing | 116,949 | 1.3% | +1,814 (+1.6%) |
| jtbd | 55,947 | 0.6% | 0 |
| project-claude-md | 5,897 | 0.06% | 0 |
| framework-injected | not measured | — | — |

Deltas from this morning's first retro snapshot (`docs/retros/2026-06-17-main-turn.md`). `problems` bucket grew +28KB (P370 capture +93 lines + P080 amendment + 7 Fix Strategy sections); `briefing` +1.8KB (the rotation moved bytes between siblings but net +1.8KB for the new drain-cadence-gap entry); `memory` +2.2KB (auto-memory writes through the session).

**Affordance**: Per-plugin breakdown available in `/wr-retrospective:analyze-context` (deep layer).

**Deep analysis recommended** — invoke `/wr-retrospective:analyze-context`. Rationale: `problems` bucket continues growing; 174 verifying tickets is structurally blocked from cell-parse work without paged-read tooling.

## Ask Hygiene (P135 Phase 5 / ADR-044)

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| 1.1 | RFC-014 seq | direction | Gap: deviation-approval per ADR-074 substance-confirm. |
| 1.2 | P305 race | direction | Gap: ≥2-option fix-strategy decision blocked under ADR-074. |
| 1.3 | P304 bundler | direction | Gap: bundler mechanism choice. |
| 1.4 | P248 Phase 2 | direction | Gap: Q1+Q3 substance-confirm. |
| 2.1 | P179 enforce | direction | Gap: enforcement-form choice. |
| 2.2 | P178 carve | direction | Gap: architect-PASS-as-RCA-substitute framework position. |
| 2.3 | P357 enforce | direction | Gap: structural enforcement form. |
| 2.4 | Turn-end class | direction | Gap: capture-vs-append-vs-defer for P370 class. |
| 3.1 | P080 split | direction | Gap: split-into-sibling vs deferred-amendment. |
| 3.2 | P297 Phase 2 | direction | Gap: A/B/C/D Phase 2 substance choice. |
| 4.1 | P080 catchup re-ask | direction | Gap: clarification follow-up. |

**Lazy count: 0**
**Direction count: 11**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

Persisted to `docs/retros/2026-06-17-main-turn-drain-ask-hygiene.md`.

**R6 numeric gate check**: lazy count = 0 this retro; gate did NOT fire. (R6 fires on ≥2 lazy across 3 consecutive retros.) Earlier this morning's retro showed lazy=1; this retro shows lazy=0. The trend is down.

## Problems Created / Updated

- **P370 (new)** — Iter subprocess ends turn waiting on backgrounded task with no auto-resume (`claude -p` has no auto-resume); 8 staged files + 11 GREEN bats lost (iter 11 evidence: $8.02 / 17 min). Sibling-class to P083/P146/P232. Trace: developer + JTBD-006. Fix Strategy Option 3 (SKILL prose prohibition + behavioural test).
- **P080 (Verifying → Known Error)** — user-directed reopen; Phase 2 `--catchup` migration mode scope appended; surfaces in WSJF queue at 3.0 priority. Closes P282-class invisibility for this ticket's deferred work.
- **P305 (amended)** — Fix Strategy ratification: Option B per-iter git worktree.
- **P248 (amended)** — Phase 2 Direction Ratified: Cost-primary + Dual-axis coexistence; Q2/Q4/Q5 silent-framework defaults.
- **P179 (amended)** — Fix Strategy Option A hard rule + behavioural test ratified.
- **P178 (amended)** — Fix Strategy: Hard-block ratified (empirical RCA on every ticket).
- **P357 (amended)** — Fix Strategy Option (b) pre-write hook ratified.
- **P297 (amended)** — Phase 2 Option D (P356-driven) ratified; Phase 3 scope outlined.
- **P304 / RFC-023 (amended)** — Investigation task added + RFC design constraint: coordinate bundler choice with RFC-025 markdown-toggle tool choice.

## Codification Candidates

| Kind | Shape | Suggested name / Target file | Scope / Flaw | Triggers / Evidence | Decision |
|------|-------|-----------------------------|--------------|----------------------|----------|
| improve | skill | `packages/architect/skills/review-decisions/SKILL.md` AND `packages/jtbd/skills/confirm-jobs-and-personas/SKILL.md` (the drain surfaces — possibly the broader "drain-from-queued-context" pattern) | Question-freshness drift: the drain surfaced a queued question whose underlying ticket state had moved on (RFC-014 Stories A+B+D landed in commit `0e7222be` before the drain ran). | RFC-014 ask was moot; user push-back surfaced it. | Recorded in Pipeline Instability above; Fix Strategy Option 2 (improve skill) — add a per-question pre-flight that re-reads the cited ticket's current state before surfacing. **Defer ticket capture** — this is the first witness; if recurs, capture a problem ticket. |
| improve | briefing | `docs/briefing/agent-hook-gate-quirks.md` | drain-cadence-gap not previously documented | This session's discovery via direct user pointing at the queue file | Done — entry added this retro. |
| create | (skill / hook / script — RFC-pending) | TBD | The "/wr-itil:work-problems Step 2.4 gate doesn't actually drain cross-session-accumulated outstanding questions" gap | P341 amendment this morning + this session's evidence | Already ticketed (P341 verifying); fix strategy = P357-class structural hook gate. No new codification candidate needed. |

## Tickets Deferred

None — every codify-worthy observation either ticketed in a prior step OR recorded as a Fix Strategy on an existing ticket. The "question-freshness drift" observation is a first-witness; per the Pipeline Instability decision, recorded in retro only with the explicit "if recurs, capture" trigger.

## No Action Needed

- All 11 AskUserQuestion calls were direction-class; lazy count 0.
- README inventory currency clean (13 packages, 0 drift).
- Risk-scorer + external-comms + voice-tone gates all passed clean on the drain commit (3-file batch + 12-file batch).
- The outstanding-questions queue is empty; the cross-session accumulation is fully drained.
