# Session Retrospective — Session 8, iter 5 (AFK)

**Iter scope**: batched P268 sibling-hook sweep — P273 + P274 + P275 in one ADR-014 commit (`377af18b`).
**Mode**: `claude -p` AFK iteration-worker per P086 (retro-on-exit before ITERATION_SUMMARY emit).
**Commit shipped**: `377af18b687aaee365e67438ffd74feb81f1a44d`.

## Briefing Changes

- **Updated**: `docs/briefing/hooks-and-gates.md` line-14 entry on the `git commit` substring-match pattern — renamed from P165-specific to multi-sibling-canonical scope; signal-score bumped +2 → +3 (cited and acted on this iter); progress note added documenting all 5 siblings now fixed at source; architect-directed Option B at `packages/shared/hooks/lib/` recorded.
- **Updated**: `docs/briefing/README.md` Critical Points entry on `git commit` substring-match — workaround scope narrowed to the cache-lag window (3 of 5 hooks at cache still substring-match until next release).
- **Added**: (none — no new learnings warrant a new entry beyond the scope expansion above).
- **Removed**: (none).

## Signal-vs-Noise Pass (P105)

AFK iter retro — narrow scoring window. Entries cited or acted on this iter:

| Entry | Topic file | Old score | New score | Classification | Citation |
|-------|-----------|-----------|-----------|----------------|----------|
| Multiple gate hooks substring-match `git commit` | `hooks-and-gates.md` line 14 | +2 | +3 | signal | This iter's commit (`377af18b`) closes the sweep — direct action on the entry's named anti-pattern. |
| Four edit gates fire on every edit; markers expire mid-batch | `README.md` Critical Points line 10 | +N/A (Critical Points entry, no per-entry score) | n/a | signal | Architect + JTBD markers expired between iter turns; both re-fired to refresh markers covering newly-created files (`sync-command-detect.sh`, `sync-command-detect.bats`). Pattern played out as documented. |
| Plugin hooks run from marketplace cache, not source | `README.md` Critical Points line 11 | n/a | n/a | signal | Cited in commit-message construction (writing message to file via `git commit -F` to avoid cached substring-match hooks substring-tripping on heredoc body). Also drove the briefing-update note that the cache-lag window keeps the workaround active for 3 of 5 hooks. |
| `git mv` + `Edit` + `git add` requires re-stage after the Edit | `README.md` Critical Points line 14 | n/a | n/a | signal | This iter applied `git mv` of 3 problem tickets `open/` → `verifying/`, then `Edit`ed Status fields, then re-staged. First attempt's Edit failed (`File has not been read yet`) — the re-read + re-edit flow worked. The pattern itself is canonical and held. |

**Critical Points changes**: line 16 entry rewritten in-place to reflect closure progress; line count unchanged.

**Delete queue** (≤ -3): empty.

**Budget overflow**: none — Tier 1 budget unchanged.

## Problems Created/Updated

- **P273 / P274 / P275** — transitioned Open → Verification Pending via fold-fix in the same commit (per ADR-022 + P143). README WSJF Rankings rows removed; Verification Queue rows added; line-3 P134 fragment rotated.
- **No new problem tickets created in this retro** — no codify-worthy NEW observations beyond what shipped in the commit. The orchestrator-Option-A-vs-architect-Option-B framing mismatch (see Codification Candidates below) is a positive framework interaction (architect correctly tightened orchestrator's loose framing per ADR-017 § Confirmation), not friction worth a ticket.

## Tickets Deferred

(None — no Step 4b Stage 1 fallback gates fired.)

## Verification Candidates

(Step 4a) Same-session exclusion applies to all `.verifying.md` tickets exercised in this iter:

| Ticket | Fix summary | In-session citations | Decision |
|--------|-------------|----------------------|----------|
| P268 | `command_invokes_git_commit` shared helper at `packages/shared/hooks/lib/command-detect.sh` | 28/28 helper bats green; consumed by 3 new sibling hooks (P273/P274/P275) plus P272's existing consumption; new behavioural fixtures positively assert the helper's leading-executable semantics. | left Verification Pending — **same-session exclusion** (P268 transitioned `.verifying.md` earlier in session 8; subsequent-session exercise is the meaningful close signal per Step 4a contract). |
| P272 | `itil-changeset-discipline.sh` consumes the helper at line 78 | 31/31 changeset-discipline bats green this iter (no cross-regression after P273+P274+P275 land). | left Verification Pending — **same-session exclusion** (P272 transitioned earlier in session 8). |
| P273 / P274 / P275 | This iter's commit | n/a | left Verification Pending — **same-session exclusion** (just-transitioned this iter; bats green at commit time but a session cannot verify its own fix beyond commit-time bats per Step 4a contract). |

Net: zero close-on-evidence transitions this retro. All five tickets in the sweep await subsequent-session exercise.

## Pipeline Instability

Step 2b scan — categorical detections:

| Signal | Category | Citations | Decision |
|--------|----------|-----------|----------|
| Architect + JTBD gate markers expired between turns when batch crossed multiple newly-created file paths | Hook-protocol friction | After architect/JTBD initial verdicts (~5 min into iter), Write attempts on `sync-command-detect.sh` + `sync-command-detect.bats` + `package.json` + `ci.yml` all returned `BLOCKED: Cannot edit '<file>' without architecture review.` — required a second architect + JTBD delegation to refresh markers covering the new file paths. Marker TTL appears tied to file paths reviewed in initial delegation, not to a global session marker. | recorded in retro only (not ticket-worthy) — this is the documented Critical Points pattern playing out as expected. The iter cost was ~30s for re-fire (parallel call), well within tolerance. Already tracked in briefing Critical Points line 10 and `hooks-and-gates.md` line 11/14. |

**JTBD currency advisory**: clean (12 packages with `has_jtbd_anchor=yes`, `drift_instances=0`).

## Topic File Rotation Candidates

Step 3 Tier 3 budget pass surfaced 15 OVER + 1 MUST_SPLIT files. **Per Branch B fall-through-to-`split-by-date` (safe default)** and Branch A `split-by-date` on `MUST_SPLIT`, rotation IS required and the do-nothing options are not eligible. **However**, this iter's commit was already at ADR-014 batch-grain limit (3 hook fixes + canonical promotion + sync infra + 3 ticket transitions + README refresh — single concern: closing the substring-match sibling sweep). N×16-file briefing rotations would burst the iter into multi-concern territory.

| Topic file | Bytes | Threshold | Proposed rotation | Decision |
|------------|-------|-----------|-------------------|----------|
| `plugin-distribution.md` | 10370 | 5120 (2.03×, MUST_SPLIT) | split-by-date (safe default per Branch A; archive oldest entries to `plugin-distribution-archive.md`) | **flagged (AFK-deferred)** — orchestrator main turn or next interactive session owns the rotation per P195 recurring-defer tracker. |
| `hooks-and-gates-archive.md` | 10009 | 5120 (1.96×) | split-by-date | **flagged (AFK-deferred)** — same as above. |
| `releases-and-ci-archive.md` | 9941 | 5120 (1.94×) | split-by-date | **flagged (AFK-deferred)**. |
| `agent-hook-gate-quirks.md` | 9434 | 5120 (1.84×) | split-by-date | **flagged (AFK-deferred)**. |
| `afk-subprocess-recovery.md` | 9397 | 5120 (1.84×) | split-by-date | **flagged (AFK-deferred)**. |
| `afk-subprocess-mechanics.md` | 9093 | 5120 (1.78×) | split-by-date | **flagged (AFK-deferred)**. |
| `hooks-and-gates.md` | 8908 | 5120 (1.74×) | split-by-date | **flagged (AFK-deferred)**. |
| `afk-subprocess.md` | 8603 | 5120 (1.68×) | split-by-date | **flagged (AFK-deferred)**. |
| `governance-workflow-surprises.md` | 8269 | 5120 (1.62×) | split-by-date | **flagged (AFK-deferred)**. |
| `releases-and-ci.md` | 8249 | 5120 (1.61×) | split-by-date | **flagged (AFK-deferred)**. |
| `hooks-and-gates-archive-pre-2026-05-04.md` | 7615 | 5120 (1.49×) | split-by-date | **flagged (AFK-deferred)**. |
| `agent-interaction-patterns.md` | 6684 | 5120 (1.31×) | split-by-date | **flagged (AFK-deferred)**. |
| `governance-workflow-archive.md` | 6086 | 5120 (1.19×) | split-by-date | **flagged (AFK-deferred)**. |
| `governance-workflow-archive-mid.md` | 5568 | 5120 (1.09×) | split-by-date | **flagged (AFK-deferred)**. |
| `governance-workflow-archive-pre-2026-04-23.md` | 5529 | 5120 (1.08×) | split-by-date | **flagged (AFK-deferred)**. |

**Honest disclosure** (recurring-defer per P195): this is the N-th retro that has surfaced these rotations and deferred. Branch B safe-default is `split-by-date`, NOT defer — the AFK iter constraint (single ADR-014 commit grain) is the framework-mediated rationale for not absorbing this scope here. Recommend `/wr-retrospective:run-retro` or `/wr-itil:work-problems` against P195 specifically at the next orchestrator main turn to actually drain the queue.

## Context Usage (Cheap Layer)

| Bucket | Bytes | % of total |
|--------|-------|-----------|
| decisions | 1434818 | 39.6% |
| skills | 913053 | 25.2% |
| problems | 469557 | 13.0% |
| hooks | 392162 | 10.8% |
| memory | 232651 | 6.4% |
| briefing | 135408 | 3.7% |
| jtbd | 43805 | 1.2% |
| project-claude-md | 4277 | 0.1% |
| framework-injected | not measured — framework-injected-no-on-disk-source | — |

**Total measured**: ~3.6 MB. **Top-5 offenders**: decisions (1.43 MB), skills (913 KB), problems (470 KB), hooks (392 KB), memory (233 KB). Measurement-method: bucket byte-sum via `wc -c` on `packages/*/{hooks,skills,agents,scripts}/`, `docs/{decisions,problems,jtbd,briefing}/`, `~/.claude/projects/.../memory/` per `measure-context-budget.sh` contract.

**No prior snapshot for delta-from-prior** — first retro reading the snapshot trailer this session (per ADR-026 `not measured — no prior data` sentinel).

Per-plugin breakdown available in `/wr-retrospective:analyze-context` (deep layer).

## Ask Hygiene (P135 Phase 5 / ADR-044)

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|

(No AskUserQuestion calls in this iter — architect + JTBD + risk-scorer + voice-tone delegations were Agent tool invocations, not AskUserQuestion. The orchestrator pre-empted AskUserQuestion mid-loop per P135 / ADR-044 — direction-setting questions are batched at loop end via Step 2.5.)

**Lazy count: 0**
**Direction count: 0**
**Deviation-approval count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## Codification Candidates

| Kind | Shape | Suggested name / Target file | Scope / Flaw | Triggers / Evidence | Decision |
|------|-------|-----------------------------|--------------|----------------------|----------|
| improve | docs (ADR-017 housekeeping) | `docs/decisions/017-shared-code-sync-pattern.proposed.md` § Consequences / Reassessment | The architect verdict noted that `packages/shared/hooks/lib/` already hosts 3 helpers (`session-marker.sh`, `leak-detect.sh`, `external-comms-key.sh`) under a NESTED layout, while ADR-017 + `packages/shared/derive-first-dispatch.sh` precedent describes a FLAT layout. The two coexisting conventions are undocumented. Architect described as "useful housekeeping but not gate-required". | This iter — architect verdict on Option A.bridge vs Option A.ADR-017-strict vs Option B; orchestrator's iter-prompt framing of "Option A defers shared/ promotion" did NOT match ADR-017 § Confirmation strict shape; architect tightened to Option B at `packages/shared/hooks/lib/command-detect.sh`. | **flagged (AFK-deferred)** — note in retro summary so orchestrator main turn can decide whether to amend ADR-017 § Consequences with a one-line acknowledgement that `packages/shared/hooks/lib/` nesting is the established shape for hook helpers (cross-cutting libs stay flat). Not ticket-worthy on its own — observation count = 1; threshold for recurring-pattern ticket = 3+. |

## No Action Needed

- The orchestrator's Option A vs Option B framing in the iter prompt was loose (described "Option A defers `packages/shared/` promotion" as a Stage-1 bridge), but the architect agent correctly pivoted to Option B per ADR-017 § Confirmation. **This is the framework working as designed** — architect IS the framework-resolution surface for ADR-mediated shape questions, and it caught the loose framing. No friction; not ticket-worthy as a single observation.
- Whitespace mismatch on first `old_string` attempt for P275 hook source edit was caught immediately when downstream bats went red. The TDD discipline (RED → fix → GREEN) successfully recovered the agent error within one cycle. No codification needed.
- Marker re-fire pattern (architect + JTBD) on newly-created files between iter turns is the documented Critical Points pattern playing out as expected.

## ITERATION_SUMMARY context for orchestrator

```yaml
ticket_id: P273+P274+P275
commit_sha: 377af18b687aaee365e67438ffd74feb81f1a44d
iter_outcome: shipped
lazy_askuserquestion_count: 0
outstanding_questions:
  - category: deviation-approval
    existing_decision: "ADR-017 § Consequences — single flat layout under packages/shared/ per derive-first-dispatch.sh precedent"
    contradicting_evidence: "packages/shared/hooks/lib/ already hosts session-marker.sh / leak-detect.sh / external-comms-key.sh under nested hooks/lib/; architect note 2026-05-19 iter 5 surfaced the two coexisting conventions"
    proposed_shape: amend
    rationale: "One-line note in ADR-017 § Consequences acknowledging that hook helpers cluster under packages/shared/hooks/lib/ while cross-cutting libs stay flat — codifies the architect verdict's verified observation. Not gate-required; useful housekeeping."
    ticket_id: null
release_cadence_signal: "Within-appetite (commit=4 push=4 release=4 Low); orchestrator Step 6.5 owns drain."
```
