# Session 7 iter 1 — P250 Known Error → Verification Pending

> AFK `claude -p` subprocess iter of `/wr-itil:work-problems`. Single ticket transition: P250 ("`/wr-itil:work-problems` Step 6.5 '≤3 within appetite — no drain' clause defers low-risk releases, encoding accumulation") — fix shipped in `@windyroad/itil@0.32.3` (version-packages commit `4a0e1b7`, 2026-05-17 21:29 UTC, PR #141 merge `4df08ec`). Transition per ADR-022 + P143 fold-fix amendment.

## Outcome

| Metric | Value |
|---|---|
| Ticket | P250 |
| Action | worked |
| Outcome | verifying |
| Commit | `53a2f75` |
| Files changed | 3 (ticket rename + Status update + Change Log; README WSJF row removal + VQ row insertion + line 3 refresh; README-history rotation) |
| Risk score | commit=1 push=1 release=1 (Very Low) |
| Lazy AskUserQuestion count | 0 (AFK subprocess; brief forbids mid-iter ask) |

## Verification evidence (per ADR-022 + P186 evidence-based shape)

- Changeset `.changeset/p250-step-6-5-drain-on-releasable-material.md` was consumed in version-packages commit `4a0e1b7` (2026-05-17 21:29 UTC, github-actions[bot]). Per P143 fold-fix amendment to ADR-022, changeset removal IS the canonical "fix shipped to npm" signal.
- Current cache ships `@windyroad/itil@0.35.2` across 4 subsequent release cycles (0.33.0/0.34.0/0.35.0/0.35.1/0.35.2) with zero regression.
- In-session verification evidence cited in the VQ row: session 6 iter 3 (2026-05-18 07:56:29 AEST) drained via `push:watch` only at 1/1/1 within-appetite score with unpushed commits present — exercising the new three-band Step 6.5 logic that pre-fix wording would have skipped.

## Step 2 reflection — class-of-behaviour observations

### Observation 1: prior session pre-applied K → V edits with wrong version-packages refs

**Signal**: prior session (pre-this-iter) staged the `git mv` for P250 known-error → verifying AND applied partial K → V edits to the working tree (Status field, Fix released line, Change Log entry, VQ row insertion). But the version-packages commit/PR refs cited in those edits were WRONG:

- Wrong: `consumed in version-packages commit 1ef3157 2026-05-17 23:01 UTC, merged via PR #143 / merge commit 10aecdf`
- Right: `consumed in version-packages commit 4a0e1b7 2026-05-17 21:29 UTC, merged via PR #141 / merge commit 4df08ec`

The wrong refs belong to **P247's release** (`@windyroad/retrospective@0.19.0`), not P250's. The prior session most likely confused the two adjacent release cycles when reading the git log.

**This iter's catch**: pre-commit verification cross-checked the changeset filename against `git log` for the version-packages commit that consumed it. The check returned `4a0e1b7` (which deleted `.changeset/p250-step-6-5-drain-on-releasable-material.md`), not `1ef3157` (which deleted `wr-retro-p247-step-3-tier-3-branch-b-evidence-based.md`). Refs corrected in:
- Ticket `## Fix released` field (line 6)
- Ticket `## Change Log` entry (line 118)
- README VQ row (line 209)
- README line 3 transition fragment

Also caught: `drainging` → `draining` typo in the ticket's Transition line.

**Class of behaviour**: K → V transitions composed from inline-pre-flight evidence are fragile to "wrong release cycle cited" errors. The prior session's K → V edit was structurally correct (right ticket, right `Status` field, right Change Log shape) but had wrong factual content (which release cycle shipped the fix). If those edits had committed without this iter's verification pass, the README + ticket would have carried false provenance into the Verifying state — and the falsehood would have propagated forward into the eventual V → Closed transition.

**Codification candidate**: a K → V transition pre-commit check that resolves the changeset filename against `git log` to derive the version-packages commit + merge PR + merge commit deterministically. Shape: helper script `packages/itil/scripts/derive-release-vehicle.sh` invoked from `/wr-itil:transition-problem` Step 7 when transitioning to Verifying. Inputs: changeset filename pattern (`.changeset/p<NNN>-*.md`). Outputs: `version_packages_commit=<sha> merged_pr=<number> merge_commit=<sha> release_timestamp=<utc>`. Deterministic — eliminates the failure mode entirely.

**Queued for orchestrator Step 2.5** as a Stage 1 ticket candidate (this iter is AFK; orchestrator handles ticket creation at loop end per AFK semantics).

### Observation 2: P252 is likely a duplicate of P264

Per orchestrator brief, P252 ("reconcile-readme false-positive parses Inbound Upstream Reports `Matched local ticket` column as Verification Queue", captured 2026-05-17) and P264 ("reconcile-readme script misattributes Inbound Upstream Reports section IDs as Verification Queue rows", captured 2026-05-18) describe the same bug at the same location with the same fix shape.

P252 (2026-05-17 capture) actually documents the FIX as landed in commit `52a50e9` — "P252 fixed at commit 52a50e9: `packages/itil/scripts/reconcile-readme.sh` now scopes the Verification Queue slice to terminate at `## Inbound Upstream Reports` (ADR-062 / RFC-004) when present, eliminating the 31 false-positive `STALE verification-queue` entries". So P252 should be in the Verifying state, not Open. P264 was captured today (2026-05-18) describing the same bug.

**Queued for orchestrator Step 2.5** as a deviation candidate: merge P252 + P264, transition P252 to Verifying (fix shipped in commit `52a50e9`), and close P264 as a duplicate citing P252 as the authoritative ticket.

### Observation 3: P165 hook denies cat-append Bash commands when tickets staged without README refresh

**Signal**: while preparing the README-history.md append via `cat >> docs/problems/README-history.md <<EOF`, the P165 hook (`packages/itil/hooks/itil-readme-refresh-discipline.sh`) denied the Bash invocation with:

> BLOCKED: P165. P250 needs README refresh: git add docs/problems/README.md. Bypass: BYPASS_README_REFRESH_GATE=1 via .claude/settings.json env (P173).

The deny was technically correct (a problem ticket was staged but the README wasn't yet staged), but the trigger surface — `cat >> file` to append to README-history — is not what P165's spec describes. P165's spec gates `git commit` on staged-ticket-without-README. The hook appears to fire on any PreToolUse:Bash invocation while the staged-ticket-no-README precondition holds.

**Workaround applied this iter**: stage README first (`git add docs/problems/README.md`), then run the append. The append succeeded.

**Class of behaviour**: hook surface scope creep — gates that should fire only on `git commit` may fire on adjacent Bash invocations during the staged-but-uncommitted window. P165's wider trigger surface is probably intentional defense-in-depth (catches the pattern before commit instead of at commit), but it surfaces as friction when the workflow needs intermediate Bash commands between the rename and the README refresh.

**Queued for orchestrator Step 2.5** as a Stage 1 ticket candidate.

## Step 2b — Pipeline instability

| Signal | Category | Citations | Decision |
|---|---|---|---|
| P165 hook denies `cat >> README-history.md` while ticket-staged-no-README precondition holds | Hook-protocol friction | See Observation 3 above; deny message captured verbatim | new ticket via /wr-itil:manage-problem (queued for orchestrator Step 2.5) |
| Prior-session K → V edit landed wrong version-packages refs (P247's release cited instead of P250's) | Session-wrap silent drops | See Observation 1 above; pre-commit verification caught the error | new ticket via /wr-itil:manage-problem (queued for orchestrator Step 2.5) |

JTBD currency advisory: clean (12 packages, 0 drift instances).

## Step 2c — Context Usage (Cheap Layer)

| Bucket | Bytes | % of total | Δ vs prior |
|---|---|---|---|
| decisions | 1,427,785 | 41.4% | not measured — no prior snapshot for this iter |
| skills | 913,053 | 26.5% | not measured |
| problems | 420,916 | 12.2% | not measured |
| hooks | 371,318 | 10.8% | not measured |
| memory | 227,111 | 6.6% | not measured |
| briefing | 131,535 | 3.8% | not measured |
| jtbd | 43,805 | 1.3% | not measured |
| project-claude-md | 4,277 | 0.1% | not measured |
| framework-injected | not measured | — | reason=framework-injected-no-on-disk-source |

**Top-5 offenders** (by absolute bytes): decisions (1.43 MB), skills (913 KB), problems (421 KB), hooks (371 KB), memory (227 KB). Measurement method: `wr-retrospective-measure-context-budget` per ADR-026 grounding.

Per-plugin breakdown available in `/wr-retrospective:analyze-context` (deep layer).

## Step 2d — Ask Hygiene

| Call # | Header | Classification | Citation |
|---|---|---|---|

**Lazy count: 0** | **Direction count: 0** | **Override count: 0** | **Silent-framework count: 0** | **Taste count: 0** | **Correction-followup count: 0**

Zero `AskUserQuestion` calls fired this iter — AFK subprocess; orchestrator brief forbids `AskUserQuestion` mid-iter per P083 / ADR-013 Rule 6. Fourth consecutive zero-lazy iter (session 6 iter 7 P233 K-V: 0; iter 8 P087 Phase 3b: 0; iter 9 P087 Phase 3d: 0; this iter P250 K-V: 0). TREND lazy=0 stable.

## Step 3 — Briefing changes

No briefing entries added or removed this iter — the P250 K → V transition is a routine ITIL lifecycle move; observations are routed through Step 4 / Step 4b ticketing, not briefing.

## Step 3 Tier 3 budget rotation pass (P099)

`check-briefing-budgets.sh` output (threshold=5120 bytes):

- 14 files OVER (bytes range 5529 → 10370)
- 1 MUST_SPLIT: `plugin-distribution.md` bytes=10370 (ratio 2.03×)

**Decision**: defer rotation to scheduled-future-surface per **P247 Phase 2** carve-out (rotate the 14 currently-OVER topic files under the new contract — explicitly deferred to a separate iter per ADR-014 commit grain). P247 Phase 2 is in the Open WSJF queue; the rotation will land in its own AFK iter. This iter's commit grain is bounded to the P250 K → V transition.

| Topic file | Bytes | Threshold | Proposed rotation | Decision |
|---|---|---|---|---|
| `docs/briefing/plugin-distribution.md` | 10370 | 5120 | split-by-date (MUST_SPLIT — Branch A safe default; no clear sub-topic boundary) | deferred to P247 Phase 2 |
| `docs/briefing/hooks-and-gates-archive.md` | 10009 | 5120 | split-by-date | deferred to P247 Phase 2 |
| `docs/briefing/releases-and-ci-archive.md` | 9941 | 5120 | split-by-date | deferred to P247 Phase 2 |
| `docs/briefing/agent-hook-gate-quirks.md` | 9434 | 5120 | split-by-date | deferred to P247 Phase 2 |
| `docs/briefing/afk-subprocess-recovery.md` | 9397 | 5120 | split-by-date | deferred to P247 Phase 2 |
| `docs/briefing/afk-subprocess-mechanics.md` | 9093 | 5120 | split-by-date | deferred to P247 Phase 2 |
| `docs/briefing/governance-workflow-surprises.md` | 8269 | 5120 | split-by-date | deferred to P247 Phase 2 |
| `docs/briefing/releases-and-ci.md` | 8249 | 5120 | split-by-date | deferred to P247 Phase 2 |
| `docs/briefing/afk-subprocess.md` | 7666 | 5120 | split-by-date | deferred to P247 Phase 2 |
| `docs/briefing/hooks-and-gates-archive-pre-2026-05-04.md` | 7615 | 5120 | split-by-date | deferred to P247 Phase 2 |
| `docs/briefing/agent-interaction-patterns.md` | 6684 | 5120 | split-by-date | deferred to P247 Phase 2 |
| `docs/briefing/governance-workflow-archive.md` | 6086 | 5120 | split-by-date | deferred to P247 Phase 2 |
| `docs/briefing/hooks-and-gates.md` | 5972 | 5120 | split-by-date | deferred to P247 Phase 2 |
| `docs/briefing/governance-workflow-archive-mid.md` | 5568 | 5120 | split-by-date | deferred to P247 Phase 2 |
| `docs/briefing/governance-workflow-archive-pre-2026-04-23.md` | 5529 | 5120 | split-by-date | deferred to P247 Phase 2 |

## Step 4a — Verification candidates

| Ticket | Fix summary | In-session citations | Decision |
|---|---|---|---|
| P250 | Step 6.5 drain-on-releasable-material amendment shipped in `@windyroad/itil@0.32.3` | same-session transition (this iter just performed Known Error → Verification Pending) | not eligible for close-on-evidence per Step 4a step 8 — same-session verifyings are excluded; subsequent-session exercise is the meaningful signal |

No other `.verifying.md` tickets were exercised in-session.

## Step 4b — Codification candidates

| Kind | Shape | Suggested name / Target file | Scope / Flaw | Triggers / Evidence | Decision |
|---|---|---|---|---|---|
| create | shell script | `packages/itil/scripts/derive-release-vehicle.sh` | K → V transitions risk wrong release-cycle citation when refs are hand-typed from git log — fragile to adjacent-cycle confusion (P250's `4a0e1b7`/PR #141 vs P247's `1ef3157`/PR #143). | Observation 1 above — prior session's pre-applied K → V edits cited P247's release for P250's transition. This iter caught it via pre-commit ref verification. | queued for orchestrator Step 2.5 ticketing |
| improve | hook | `packages/itil/hooks/itil-readme-refresh-discipline.sh` (P165) | Hook denies any Bash command (not just `git commit`) during the staged-ticket-no-README precondition window — friction for intermediate `cat >> README-history.md` appends between the rename and the README refresh. | Observation 3 above — `BLOCKED: P165` fired on `cat >> docs/problems/README-history.md` invocation. | queued for orchestrator Step 2.5 ticketing |

## Step 5 — Tickets Deferred

No Step 4b Stage 1 tickets were deferred under a SKILL-UNAVAILABLE cause. The two codification candidates above are queued via the orchestrator's `outstanding_questions` channel per AFK iter contract — Stage 1 ticketing fires at the orchestrator's loop-end Step 2.5, which is the canonical AFK pattern (and IS the framework-mediated path per ADR-044, not a deferral).

## Summary

P250 transitions Known Error → Verification Pending; fix is empirically shipped (changeset removed in `4a0e1b7`, four subsequent release cycles green). Single iter commit `53a2f75` carries the rename + Status update + README refresh per ADR-014 grain. Three observations queued for orchestrator Step 2.5: (1) `derive-release-vehicle.sh` helper to prevent wrong-refs class of behaviour; (2) P252 ↔ P264 merge candidate (likely duplicate); (3) P165 hook scope-creep (denies non-`git commit` Bash during staged-ticket window).
