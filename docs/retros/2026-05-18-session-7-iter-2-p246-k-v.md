# Session 7 iter 2 retro — P246 K → V transition

> AFK `claude -p` subprocess invocation per P086. Scope: `--iter-only --auto-skip-tier-3-rotation`. Foreground iter ran K→V transition for P246; this retro records the iter-bounded findings.

## Briefing Changes

- Added: none — K→V workflow already codified across SKILL.md + ADR-022 P143 amendment + prior retro precedent.
- Removed: none.
- Updated: none.
- README index refreshed: no.

## Signal-vs-Noise Pass (P105)

Pass elided — `--iter-only` scope; no per-entry score writes this iter. The full pass runs in the session-wrap retro that aggregates iters.

## Problems Created/Updated

- **P246** (this iter's target): Known Error → Verifying. Single commit `9eea44c` (3 files, +28/-5). Architect + JTBD pre-edit reviews PASS; risk 1/1/1 reducing.

## Verification Candidates (Step 4a)

P246 is the K→V transition this iter (same-session — excluded from close-candidate per P068's same-session-verifyings rule). No other `.verifying.md` ticket was exercised by this iter's tool-call history (the iter only touched docs/problems/ for the transition itself + docs/changesets-holding/README.md as a *read* for the in-session evidence citation).

| Ticket | Fix summary | In-session citations | Decision |
|--------|-------------|----------------------|----------|

No close-candidates surfaced.

## Pipeline Instability (Step 2b)

| Signal | Category | Citations | Decision |
|--------|----------|-----------|----------|
| `Edit` rejected `git mv`-renamed file because the new path had not been Read in this session | Skill-contract violations (P057 staging-trap sibling at Edit-tool surface, NOT a git staging issue) | Edit tool error after `git mv docs/problems/known-error/246-...md docs/problems/verifying/246-...md`; recovered with one Read + Edit retry; one round-trip lost | recorded in retro only (not ticket-worthy) — known Edit-tool contract; documented in P057-class friction; bounded one-off per iter |

JTBD currency advisory: `wr-retrospective-check-readme-jtbd-currency` not invoked in `--iter-only` scope (the advisory is session-grain, not iter-grain).

## Context Usage (Cheap Layer)

| Bucket | Bytes | % of total | Δ vs prior |
|--------|-------|------------|------------|
| decisions | 1,427,785 | 39.3% | not measured — prior snapshot (2026-05-15) predates HTML-trailer shape |
| skills | 913,053 | 25.1% | not measured — prior snapshot lacks bucket field |
| problems | 424,768 | 11.7% | not measured |
| hooks | 371,318 | 10.2% | not measured |
| memory | 227,111 | 6.2% | not measured |
| briefing | 131,535 | 3.6% | not measured |
| jtbd | 43,805 | 1.2% | not measured |
| project-claude-md | 4,277 | 0.1% | not measured |
| framework-injected | not measured — framework-injected-no-on-disk-source | — | — |

THRESHOLD bytes=10240 (per-bucket informational; cheap-layer report itself well under ceiling).

Top-5 offenders (script-emitted bucket bytes, measurement-method: `du -b` recursive on bucket roots per `wr-retrospective-measure-context-budget`):
1. decisions — 1,427,785 bytes (39.3%)
2. skills — 913,053 bytes (25.1%)
3. problems — 424,768 bytes (11.7%)
4. hooks — 371,318 bytes (10.2%)
5. memory — 227,111 bytes (6.2%)

Per-plugin breakdown available in `/wr-retrospective:analyze-context` (deep layer). Last deep run: 2026-05-15 — older than 14 days NOT yet (3 days ago); no auto-advisory.

## Ask Hygiene (P135 Phase 5 / ADR-044)

| Call # | Header | Classification | Citation |
|---|---|---|---|

**Lazy count: 0**
**Direction count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

Trail persisted at `docs/retros/2026-05-18-session-7-iter-2-p246-k-v-ask-hygiene.md`. **Fifth consecutive zero-lazy iter** — R6 numeric gate (≥2 across 3 consecutive retros) does NOT fire; declarative-first remains sufficient per ADR-044 Reassessment.

## Topic File Rotation Candidates

Skipped per `--auto-skip-tier-3-rotation` arg. The full Tier 3 budget pass runs in the session-wrap retro per session 7 iter 1's documented deferral to P247 Phase 2 scheduled-future-surface.

## Codification Candidates

| Kind | Shape | Suggested name / Target file | Scope / Flaw | Triggers / Evidence | Decision |
|------|-------|-----------------------------|--------------|----------------------|----------|

No codification candidates this iter. The K→V transition flow is well-codified (manage-problem Step 7 + ADR-022 P143 + ADR-014 + ADR-031 + P186) and exercised cleanly here.

Session 7 iter 1 retro queued a codification candidate (`derive-release-vehicle.sh` helper to reduce hand-typed-release-citation hazard). This iter validates the iter-1 observation — the agent did NOT hand-type the release vehicle this time; it read `git log --diff-filter=D` output + `git show --stat a032ca9` + `git show 303c1f2 -- packages/itil/CHANGELOG.md` directly and cross-referenced before writing citations. Zero misattribution observed (compared to session 7 iter 1's pre-applied-with-wrong-refs preamble). The candidate remains useful but is not blocking; defer to a session-wrap aggregating retro.

## No Action Needed

- The `Edit` tool's read-first contract is documented; the one round-trip loss this iter is bounded recovery, not a class-of-behaviour.
- Release-vehicle citation was hand-verified end-to-end (changeset filename → version-packages commit → PR merge → current version) before writing — session 7 iter 1's wrong-citation preamble was successfully avoided.

## Iter outcome

P246 Known Error → Verifying transition committed as `9eea44c`. Recovery path: `/wr-itil:transition-problem 246 known-error` after reverting `9eea44c`. Verification window in-flight — 5 AFK iters across ≥2 sessions per § Verification (post-release).

RISK_SCORES: commit=1 push=1 release=1
RISK_BYPASS: doc-only (this retro is doc-only itself).
