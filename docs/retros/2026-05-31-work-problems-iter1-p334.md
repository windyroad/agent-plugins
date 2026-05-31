# Retro — work-problems iter 1 (P334 Open→Closed via verification close-on-evidence)

Date: 2026-05-31
Iter: 1
Scope: P334 (generate-decisions-compendium.sh awk substr Unicode `…` portability) Open → Closed
Session role: AFK iteration-worker subprocess (`claude -p` per P086)
Orchestrator: `/wr-itil:work-problems`

## What changed this iter

- `docs/problems/open/334-generate-decisions-compendium-awk-substr-unicode-ellipsis-not-portable-bsd-vs-gnu-awk.md` → `docs/problems/closed/334-...md` (per-state subdir rename per ADR-031). Ticket Status: `Open` → `Closed`. `Closed: 2026-05-31` field added. Resolution section appended with commit chain + verification evidence.
- `docs/problems/README.md`: P334 WSJF Rankings row removed (was top of WSJF 12.0 band); P334 Closed-table row appended with one-line summary + commit chain + verification evidence; Last-reviewed line refreshed from prior `Step 0b pre-flight refresh` fragment to P334 O→Closed fragment.
- `docs/problems/README-history.md`: prior `Step 0b pre-flight refresh` fragment rotated per P134.
- Single commit landed: `835bbb8` (`fix(architect): P334 Open→Closed — verification close-on-evidence`).
- Retro Stage 1 capture: P345 (Fix-titled commits do not transition ticket lifecycle in same commit grain) — captured via `/wr-itil:capture-problem` per P342 mechanical-stage carve-out; commit `431d9dd`.

## Briefing Changes

- Added: none — iter was a lifecycle-close-on-already-shipped-work with no novel session-start-surface signal.
- Removed: none.
- Updated: none.
- README index refreshed: none.

## Signal-vs-Noise Pass (P105)

Skipped per AFK-iter scope — the iter's tool-call activity cited 0 briefing entries directly (selection was driven by orchestrator's brief, not briefing signals). Decay (-1) applies to all entries this cycle but classification + persistence deferred to next interactive retro. Same approach as session-8 iter-9 precedent.

## Context Usage (Cheap Layer)

| Bucket | Bytes | % of total | Δ vs prior |
|--------|-------|-----------|------------|
| problems | 4,213,824 | 53.4% | no prior snapshot — first measurement this iter |
| decisions | 1,725,431 | 21.9% | no prior snapshot |
| skills | 982,722 | 12.5% | no prior snapshot |
| hooks | 430,790 | 5.5% | no prior snapshot |
| memory | 379,043 | 4.8% | no prior snapshot |
| briefing | 98,947 | 1.3% | no prior snapshot |
| jtbd | 47,091 | 0.6% | no prior snapshot |
| project-claude-md | 4,277 | 0.05% | no prior snapshot |
| framework-injected | not measured — framework-injected-no-on-disk-source | — | — |

Per-plugin breakdown available in `/wr-retrospective:analyze-context` (deep layer).

## Problems Created/Updated

- **P334** (`docs/problems/closed/334-...md`): Status `Open` → `Closed`. Resolution section records that the fix shipped in `@windyroad/architect@0.12.2` across commits `3945878` (ASCII `...`) + `3e53a94` (LC_ALL=C wrap) + `e9f7ce4` (compendium regen). Verified locally (`bash packages/architect/scripts/generate-decisions-compendium.sh --check docs/decisions` exit 0 — 76 ADRs / 69 in-force / 7 historical) AND on Linux CI (workflow "CI" green on commit `bad2eac`, run `26701674556`). Reversible via `/wr-itil:transition-problem 334 known-error`.
- **P345** (`docs/problems/open/345-fix-titled-commits-do-not-transition-ticket-lifecycle.md`): NEW. Recurring class observation from this iter's evidence chain — `fix(<pkg>): P<NNN> ...` commits land code without transitioning the named ticket's lifecycle; ticket stays Open across release + CI-verify + N intervening commits. P334 was the witness. Sibling-class of P228 (K→V seam) on the upstream O→KE seam. Fix-strategy candidates (deferred): post-commit advisory hook OR extension of P228's belt-and-braces design OR manage-problem-style paired-transition requirement. Deferred placeholders flagged for re-rate at next `/wr-itil:review-problems`.

## Verification Candidates

| Ticket | Fix summary | In-session citations | Decision |
|--------|-------------|----------------------|----------|
| P334 | ASCII `...` + LC_ALL=C in `generate-decisions-compendium.sh` shipped @ `@windyroad/architect@0.12.2` (commits `3945878` + `3e53a94` + `e9f7ce4`) | Local `--check` exit 0 on macOS BSD awk (76 ADRs / 69 in-force / 7 historical); CI workflow "CI" green on main commit `bad2eac` run `26701674556` (Linux GNU awk); both halves of the byte-portability contract verified | closed via /wr-itil:manage-problem (this iter's commit `835bbb8`) |

Sub-step 9 prior-session evidence drain not run — out of scope for an AFK iter retro (cross-session README Verification-Queue drain is the orchestrator-end wrap retro's surface per P282 evidence).

## Pipeline Instability

### Fix-titled commits skip ticket-lifecycle transition (Category 2: Skill-contract violation)

**Signal**: P334's fix code shipped in commits titled `fix(architect): P334 ...` (`3945878` + `3e53a94`) plus a downstream compendium-regen commit (`e9f7ce4`) released as `@windyroad/architect@0.12.2`. None of these commits transitioned the ticket's Status from `Open`. The ticket stayed Open across the release + CI-verify (commit `bad2eac` run `26701674556` green) + N intervening commits until this iter manually closed it. The ADR-022 K→V auto-detection at release time has nothing to act on because the Open → Known Error transition never fires for fix-titled commits.

**Citations**:
- Commit `3945878` (2026-05-30) — `fix(architect): P334 awk substr Unicode portability — ASCII '...' for cross-platform compendium`. Ticket Status remained `Open`.
- Commit `3e53a94` (2026-05-30) — `fix(architect): P334 follow-up — LC_ALL=C wrap for compendium generator`. Ticket Status remained `Open`.
- Commit `e9f7ce4` (2026-05-31) — `fix(architect): regenerate compendium with @windyroad/architect@0.12.2 (unblocks CI test 2145)`. Ticket Status remained `Open`.
- This iter dispatched explicitly to close P334's stale `Open` Status against already-shipped code.

**Decision**: new ticket P345 captured via `/wr-itil:capture-problem` (commit `431d9dd`) per P342 mechanical-stage carve-out. P345 documents the recurring class with three fix-strategy candidates; composes with P228 (sibling K→V class), P206 (sibling changeset-discipline class), and P234 (closed; umbrella defer-with-rationalization class).

### README inventory currency advisory

Detector invocation skipped this iter — out-of-scope for an AFK iter retro's narrow tool-call surface; the cross-cutting plugin-README inventory check is the parent wrap retro's surface. No drift observed in-scope (architect-package READMEs not touched).

## Ask Hygiene (P135 Phase 5 / ADR-044)

Cross-references the sibling trail file `docs/retros/2026-05-31-work-problems-iter1-p334-ask-hygiene.md`.

**Lazy count: 0**
**Direction count: 0**
**Deviation-approval count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

No `AskUserQuestion` fires this iter per orchestrator brief; all decisions framework-mediated (manage-problem + capture-problem SKILL Steps + wr-risk-scorer:pipeline gate delegations).

## Codification Candidates

| Kind | Shape | Suggested name / Target file | Scope / Flaw | Triggers / Evidence | Decision |
|------|-------|------------------------------|--------------|----------------------|----------|
| improve | hook | post-commit advisory: `fix(<pkg>): P<NNN>` title + ticket Status check | Fix-titled commits land without paired lifecycle transition (see Pipeline Instability section) | P334 evidence chain `3945878` + `3e53a94` + `e9f7ce4` + this iter's manual close | improvement stub recorded on **P345** § Description "Fix-strategy candidates (a)/(b)/(c)" per Step 4b Stage 2 contract |

Stage 2 fix-strategy recorded on the ticket itself per the deferred-placeholder pattern; concrete shape choice (advisory hook vs run-retro Step 4a extension vs manage-problem paired-transition gate) deferred to next `/wr-itil:review-problems` re-rate + investigation.

## Tickets Deferred

None — Stage 1 mechanical-auto-ticket ran successfully for the one observation (P345 captured via `/wr-itil:capture-problem`).

## Topic File Rotation Candidates

Skipped per AFK-iter scope — Tier 3 budget pass is the parent wrap-retro's surface per session-8 wrap deviation-approval direction #3 ("defer Tier 3 to parent retro when iter-invoked").

## No Action Needed

- Memory `feedback_if_you_see_something_broken_fix_it.md` (added 2026-05-31 from same session origin) is the primary umbrella for this iter's "lifecycle gap noticed → fix immediately" behaviour. Already in context; no new memory needed.

## Related

- `docs/problems/closed/334-...md` — closure target.
- `docs/problems/open/345-...md` — recurring-class capture.
- `docs/decisions/044-decision-delegation-contract.proposed.md` — Step 2d ask-hygiene contract.
- `docs/decisions/014-governance-skills-commit-their-own-work.proposed.md` — single-commit grain.
- `docs/decisions/032-governance-skill-invocation-patterns.proposed.md` — AFK subprocess + P342 mechanical-stage carve-out for retro-surfaced capture.
- `docs/decisions/077-decisions-compendium-as-token-cheap-load-surface.proposed.md` — the system P334 fix is operating in.
- `docs/retros/2026-05-31-work-problems-iter1-p334-ask-hygiene.md` — sibling trail file.
