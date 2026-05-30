# Retro — work-problems iter 9 (P325 O→KE)

Date: 2026-05-30
Iter: 9
Scope: P325 (CI actions pin Node-20 versions) Open → Known Error with workflow action pin bumps
Session role: AFK iteration-worker subprocess (`claude -p` per P086)
Orchestrator: `/wr-itil:work-problems`

## What changed this iter

- `.github/workflows/ci.yml`: `actions/checkout@v4`→`@v5`, `actions/setup-node@v4`→`@v5`
- `.github/workflows/release.yml`: same two bumps
- `.github/workflows/release-preview.yml`: same two bumps + `actions/github-script@v7`→`@v8` (×2)
- `docs/problems/open/325-...md` → `docs/problems/known-error/325-...md` (per-state-subdir rename per ADR-031)
- Ticket Status: `Open` → `Known Error`; RCA confirmed; 3 investigation tasks ticked; Fix Strategy section added
- `docs/problems/README.md`: P325 WSJF Rankings row Status flipped Open→Known Error and moved to top of WSJF 4.0 band per (KE-first) sort rule; Last-reviewed line rotated from prior P282 iter-6 fragment to P325 O→KE fragment
- `docs/problems/README-history.md`: prior P282 iter-6 fragment appended as rotated history entry per P134
- Single commit landed: `b698b45` (`fix(ci): bump Node-20 action pins to Node-24-supporting majors (P325 known error)`)

## Briefing Changes

- Added: none — iter was a mechanical version bump with no novel pattern emerging
- Removed: none
- Updated: none
- README index refreshed: none

## Signal-vs-Noise Pass (P105)

Skipped per AFK-iter scope — the iter's tool-call activity cited 0 briefing entries (selection was driven by the orchestrator's task prompt, not briefing signals). Decay (-1) applies to all entries this cycle but classification + persistence deferred to next interactive retro that touches more briefing entries. Same approach as iter-4/5/6/7/8 precedent.

## Problems Created/Updated

- **P325** (`docs/problems/known-error/325-ci-actions-pin-node-20-deprecated-bump-to-node-24-supporting-versions.md`): Status Open → Known Error. RCA confirmed (GitHub Actions runner Node-20 deprecation; first-party action pins enumerated and bumped). Fix Strategy section added documenting the 8-pin bump scope across 3 workflow files. K→V follow-on completes in a later orchestrator pass after release-and-verify.

## Tickets Deferred

| Observation | Cause | Citation |
|-------------|-------|----------|
| iter-7 + iter-8 transition commits did not rotate `docs/problems/README.md` line 3 "Last reviewed" per P134 — staleness across 2 prior iters (line 3 still pointed at iter-6 P282 fragment when iter-9 read it; README-history.md had no P281 fragment for iter-7 or iter-8) | `skill_unavailable` | Pipeline Instability detection below; `/wr-itil:capture-problem` carved out of AFK iters per ADR-032 + iter dispatch constraints; `/wr-itil:manage-problem` foreground mid-retro exceeds iter time budget |

## Verification Candidates

(No `.verifying.md` tickets were exercised by this iter's tool-call activity — the iter's scope was narrow to workflow files + ticket lifecycle. Sub-step 9 prior-session evidence drain not run — cross-session evidence drain is the orchestrator-end retro's surface per 134KB Verification Queue evidence in P282.)

## Pipeline Instability

### P134 rotation drift across iter-7 + iter-8 (Category 2: Skill-contract violation)

**Signal**: the transition-problem SKILL.md Step 7 "Last-reviewed line discipline (P134)" contract was not honored in iter-7 (P281 Open → Known Error, commit `dd47f8a`) or iter-8 (P281 Known Error → Verifying, commit `c8455c5`). Both committed README.md refreshes for the WSJF/Verification-Queue tables but did NOT rotate line 3 "Last reviewed" — iter-9 (this iter) found line 3 still carrying the iter-6 P282 O→V fragment.

**Citations**:
- iter-9 session-start `git log --oneline -5 -- docs/problems/README.md` — most-recent commits touching README are c8455c5 (iter-8 transition) and dd47f8a (iter-7 fix), confirming both touched README
- iter-9 Read of `docs/problems/README.md` line 3 — `> Last reviewed: 2026-05-30 **P282 O→V fold-fix (work-problems iter-6)** —` (iter-6 fragment, 3 iters old)
- iter-9 Grep of `docs/problems/README-history.md` for `^## 2026-05-30` — most-recent rotation entry is `2026-05-30 (P316 K→V fragment rotated for P282 O→V fold-fix)` (iter-5 rotation), confirming iter-7 + iter-8 did NOT append rotation entries
- iter-7 retro `docs/retros/2026-05-30-work-problems-iter7-p281.md` "README index refreshed: none" — explicitly states README index was not refreshed (P134 rotation IS index-refresh territory)
- iter-8 retro `docs/retros/2026-05-30-work-problems-iter8-p281-kv.md` "docs/problems/README.md: P281 WSJF Rankings row removed; Verification Queue row inserted" — mentions table edits but NOT Last-reviewed rotation

**Class-of-behaviour**: iter-N retros are recording table-refresh activity but the transition-problem SKILL Step 7 P134 sub-step is being silently skipped. Either the SKILL contract is unclear that Last-reviewed rotation is mandatory (not just table refresh), or the in-iter subprocess context drops P134 awareness, or the iter execution path is bypassing canonical transition-problem in favor of a lighter manual sequence.

**Dedup**: no existing ticket. Candidate sibling: P165 (README-refresh hook contract), P138 (cross-skill drift detection patterns). New ticket warranted — P134 is a documented contract being silently violated across 2+ iters.

**Decision**: deferred to next interactive `/wr-retrospective:run-retro` per skill_unavailable cause (capture-* AFK carve-out per ADR-032; manage-problem foreground mid-retro exceeds iter time budget). User picks up on return; this retro provides the full citation set.

**README inventory currency**: clean (13 packages, 0 drift instances).

**Briefing budgets**: 4 OVERS (none MUST_SPLIT, all between 1.06× and 1.28× threshold):
- `docs/briefing/governance-workflow-archive.md` — 6551 / 5120 (1.28×)
- `docs/briefing/governance-workflow.md` — 5839 / 5120 (1.14×)
- `docs/briefing/hooks-and-gates-archive.md` — 5429 / 5120 (1.06×)
- `docs/briefing/releases-and-ci.md` — 6156 / 5120 (1.20×)

Surfaced as Topic File Rotation Candidates below — same set as iter-7/iter-8; the recurring-defer-pattern P145 risk applies (3rd consecutive iter to flag without action). Acknowledged but iter-9 scope clamps to P325; orchestrator-end retro or next interactive retro should action.

## Topic File Rotation Candidates

| Topic file | Bytes | Threshold | Proposed rotation | Decision |
|------------|-------|-----------|-------------------|----------|
| `docs/briefing/governance-workflow-archive.md` | 6551 | 5120 | split-by-date (2nd-tier archive) | flagged (AFK iter scope clamp — 3rd consecutive iter; P145 recurring-defer risk acknowledged) |
| `docs/briefing/governance-workflow.md` | 5839 | 5120 | split-by-date (safe default) | flagged (AFK iter scope clamp; P145 recurring-defer risk acknowledged) |
| `docs/briefing/hooks-and-gates-archive.md` | 5429 | 5120 | split-by-date (2nd-tier archive) | flagged (AFK iter scope clamp; P145 recurring-defer risk acknowledged) |
| `docs/briefing/releases-and-ci.md` | 6156 | 5120 | split-by-date (safe default) | flagged (AFK iter scope clamp; P145 recurring-defer risk acknowledged) |

## Context Usage (Cheap Layer)

| Bucket | Bytes | % of total | Δ vs prior |
|--------|-------|-----------|-----------|
| problems | 4032014 | 54.4% | not measured — no prior snapshot accessible to this iter |
| decisions | 1682493 | 22.7% | not measured |
| skills | 956794 | 12.9% | not measured |
| hooks | 430293 | 5.8% | not measured |
| memory | 358257 | 4.8% | not measured |
| briefing | 92108 | 1.2% | not measured |
| jtbd | 46488 | 0.6% | not measured |
| project-claude-md | 4277 | 0.06% | not measured |
| framework-injected | not-measured | — | reason=framework-injected-no-on-disk-source |

THRESHOLD: 10240 bytes (cheap-layer report ceiling per ADR-043).

Top-5 offenders by absolute size: `problems` (4.0 MB), `decisions` (1.7 MB), `skills` (957 KB), `hooks` (430 KB), `memory` (358 KB).

Per-plugin breakdown available in `/wr-retrospective:analyze-context` (deep layer).

## Ask Hygiene (P135 Phase 5 / ADR-044)

Trail file: `docs/retros/2026-05-30-work-problems-iter9-p325-ask-hygiene.md`.

**Lazy count: 0** — no AskUserQuestion fired this iter; AFK orchestrator constraint forbids mid-loop AskUserQuestion (P135 / ADR-044). All decisions framework-resolved or pre-pinned by the orchestrator's selection prompt.

## Codification Candidates

(No new codification candidates this iter — the P134-rotation-drift signal is captured as a Pipeline Instability deferred-ticket above; it routes to ticket-then-fix-strategy via the next interactive retro per the standard Step 4b flow.)

## No Action Needed

- Architect verdict PASS (no new ADR — bumps fall under existing "version bumps" exclusion; no ADR covers runner Node versions)
- JTBD verdict PASS (serves JTBD-101 CI/release pipeline keep-alive; protects "Must not break existing plugins" constraint)
- P063 external-root-cause detection NO_MATCH (strict tokens absent in P325 ticket body — GitHub deprecation framed as runner-image change, not third-party vendor; no marker appended)
- Pipeline risk: commit=3 / push=2 / release=0 (all within Low appetite of 4)
- TDD invariant: no implementation file edits (workflow YAML + docs only — not under TDD enforcement scope per ADR-052)
