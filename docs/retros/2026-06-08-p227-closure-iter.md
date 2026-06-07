# Iter retro — P227 closure (work-problems AFK)

**Date**: 2026-06-08
**Iter**: P227 closure (work-problems orchestrator)
**Scope**: single-iter; P227 KE→Closed-as-Superseded — agent-prose category-error fix already shipped 2026-04-18 commit `0edec54`.

## Iter outcome

Closed P227 (Risk scorer credits monitoring/post-release activities as residual-risk reducers) as superseded by commit `0edec54` `fix(risk-scorer): monitoring is not a control` (2026-04-18, ~four weeks BEFORE P227 was reported 2026-05-15 via upstream-mirror intake batch #56). Verification at closure confirmed all three per-action scoring surfaces carry the prose: `packages/risk-scorer/agents/pipeline.md` lines 365-370 (commit/push/release residual), `plan.md` lines 78-82 (plan-level residual), `wip.md` lines 112-115 (wip-state nudge). The "post-release follow-ups" carve-out in pipeline.md line 367-369 is the explicit "detection-and-recovery" sibling category P227 Investigation Task #2 asked for. Behavioural bats `packages/risk-scorer/agents/test/risk-scorer-monitoring-not-a-control.bats` covers Investigation Task #3 (6 assertions, 2 per agent file, ADR-005/P011 Permitted Exception). external-comms.md / inbound-report.md intentionally don't carry the prose — those sibling agents don't score per-action diff residual (no coverage gap). RISK-POLICY.md § Control Composition line 169 carries the rollback-as-impact-reducer qualifier (explicit-rationale gated), keeping rollback-CAPABILITY (design-class control) distinct from rollback-READINESS (forbidden post-release follow-up). No code change in the closure transition; KE→Closed direct per ADR-079 lifecycle extension.

**ADR-079 ratification caveat (continues P218/P222/P225 retro precedent, now SEVENTH-case-deep)**: this iter is the SEVENTH KE→Closed-as-Superseded case this week (P216 / P292 / P217 / P218 / P222 / P225 / P227), all riding the unratified ADR-079 lifecycle extension. The drain backpressure for ADR-079 ratification continues to mount; queued at orchestrator level via the session-start system-reminder #2 outstanding_questions entry. The orchestrator constraint forbid AskUserQuestion this iter, so no fresh queue entry needed — the existing entry already lists ADR-079 as load-bearing for the running-total of KE→Closed-Superseded cases.

Commit (closure): `0b8ae89` (work tree clean post-closure-commit; pre-existing untracked retro files unrelated to this iter).

## Briefing Changes

- Added: none — scanned `hooks-and-gates.md`, `governance-workflow.md`, `agent-interaction-patterns.md` for P227-relevant additions; "Monitoring is not a control" prose has been live in the risk-scorer agents since 2026-04-18 (commit `0edec54`) and is implicit framework. The seventh-in-a-week KE→Closed-as-Superseded cadence remains an operational signal but is already captured by the running ADR-079 ratification drain.
- Removed: none — scanned for staleness against this iter's evidence; ADR-079 / pipeline.md / plan.md / wip.md / R009 / RISK-POLICY.md Control Composition entries remain accurate.
- Updated: none — Critical Points entries unchanged; closure was scoped to verifying agent-prose coverage of an already-shipped fix, not modifying scorer mechanics.

Scan summary: 0 add candidates accepted (of ~2 considered: seventh-KE→Closed-cadence + rollback-capability-vs-readiness distinction — both rejected as either implicit or session-local), 0 remove candidates accepted, 0 update candidates accepted.

## Signal-vs-Noise Pass (P105)

| Entry | Topic file | Old score | New score | Classification | Citation |
|-------|-----------|-----------|-----------|----------------|----------|
| "Monitoring is not a control" prose in all three per-action scoring agents | `docs/briefing/governance-workflow.md` (implicit via SKILL-prose) | 0 | +2 | signal | Cited verbatim as the supersession authority in P227 closure body + commit message + Closed README row; verification touched all three agent files (pipeline.md lines 365-370 / plan.md lines 78-82 / wip.md lines 112-115) + bats. |
| RISK-POLICY.md § Control Composition line 169 rollback-capability impact-reducer qualifier | `docs/briefing/governance-workflow.md` (implicit) | 0 | +1 | signal | Cited as the design-class control distinction that keeps rollback-CAPABILITY separate from forbidden rollback-READINESS; the agent-prose forbids the latter, the policy permits the former with explicit-rationale gating. |
| ADR-079 evidence-based-relevance-close-pass (unratified `proposed`) | `docs/briefing/governance-workflow.md` (implicit via Closed README rows) | 0 | +3 | signal | Cited as the lifecycle-extension authority for the SEVENTH KE→Closed-direct transition this week. The unratified status of the ADR remains the primary outstanding governance debt; queued ratification drain at orchestrator level (system-reminder #2 entry at session start). |

**Critical Points changes**: none. P227 closure reinforced existing entries; no new candidate cleared the +3 promotion threshold (ADR-079 ratification is the standing one already queued).

**Delete queue**: empty.

**Budget overflow**: not triggered.

## Pipeline Instability

| Signal | Category | Citations | Decision |
|--------|----------|-----------|----------|
| Architect + JTBD `PreToolUse` edit gates BOTH fired on `docs/retros/2026-06-08-p227-closure-iter.md` write despite `docs/retros/` being in BOTH `architect-enforce-edit.sh` and `jtbd-enforce-edit.sh` exclusion lists per P203 (shipped 2026-06-06 commit `b13b9e9`). The shipped fix targets `packages/architect/hooks/architect-enforce-edit.sh` lines 108-114 + `packages/jtbd/hooks/jtbd-enforce-edit.sh` lines 114-120; the firing gates are the installed marketplace-cache copies, which appear not yet refreshed to the post-P203 version. | Plugin-distribution cache staleness | Gate deny messages: "Cannot edit '2026-06-08-p227-closure-iter.md' without architecture review" (first) and "Cannot edit '2026-06-08-p227-closure-iter.md' without JTBD review. No jtbd review marker found" (second). Both subagent delegations re-PASSed cleanly after confirming `docs/retros/` IS on the shipped exclusion lists — marketplace-cache staleness, not a policy issue. Sibling-precedent: P222 closure iter retro write earlier today did NOT trigger the same gates — possibly because the session-start `/install-updates` ran successfully or the cache state shifted in the interim. | Record in retro only — no new ticket needed. The class is already covered: marketplace-cache staleness is a documented framework property (briefing Critical Points: "Plugin hooks run from the marketplace cache, not from source"). Recommend the user run `/install-updates` at loop end to refresh both architect-plugin and jtbd-plugin caches and verify the next `docs/retros/` write does not trigger the gates. If either gate re-fires AFTER a clean `/install-updates` refresh, escalate as P203-regression evidence-append. |

Both commit-time gates fired cleanly this iter: `wr-risk-scorer:pipeline` PASS commit=1/25 (Very Low; matched R002 doc-index-drift baseline with single-band reduction from visual-inspection control); `wr-risk-scorer:external-comms` PASS (no Confidential Information class matched against the docs-only commit message); `wr-voice-tone:external-comms` PASS (git-commit-message surface explicitly out of scope per VOICE-AND-TONE.md line 68). Single-commit landed via standard `git commit` (no `wr-risk-scorer-restage-commit` wrapper invocation needed because git mv + Edit + git add was straightforward; the P326 rename-source-rejection symptom from the P222 iter did NOT recur because the staging sequence was kept simple).

External-comms gate marker-derivation worked correctly this iter — no P353 sibling recurrence. The orchestrator-provided BYPASS_RISK_GATE=1 escape hatch was NOT needed; both PASS verdicts landed and the gate accepted them on the next commit attempt.

README inventory currency: clean (13 packages). No skill-inventory drift detected.

## Context Usage (Cheap Layer)

Per-iter context usage measurement skipped this iter — light docs-only iter that did not invoke `wr-retrospective:analyze-context`. Recommend the orchestrator run the deep-layer analyzer at loop end for cumulative tracking.

## Ask Hygiene (P135 Phase 5 / ADR-044)

No `AskUserQuestion` calls fired in this iter — orchestrator constraint explicitly forbid them ("NEVER call AskUserQuestion") and every framework-resolved decision (closure transition via ADR-079; commit-gate via wr-risk-scorer:pipeline + external-comms + voice-tone; ADR-079 ratification queued at orchestrator level via existing system-reminder #2 entry) was either mechanical or AFK-queued per ADR-013 Rule 6.

**Lazy count: 0**
**Direction count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## Verification Candidates

None — this iter did not exercise any `.verifying.md` ticket's fix. P227 closed as KE→Closed direct (per ADR-079 evidence-based-relevance-close-pass shape 3 duplicate-of-X + shape 2 work-shipped), bypassing the standard KE→VP→Closed path because the fix was already shipped in main four weeks before the ticket was filed.

## Topic File Rotation Candidates

Not measured this iter — Step 3 made zero topic-file edits, so the Tier 3 budget pass has nothing to act on.

## Codification Candidates

No codification candidates surfaced this iter. The smooth gate-pass sequence (pipeline → external-comms → voice-tone → commit) without BYPASS suggests the P353 marker-derivation failure mode is intermittent rather than systemic; observed-but-not-re-fired on this iter would be evidence-append-worthy to P353 IF the iter had attempted a re-derivation under conditions matching the failure mode, but the simple `git commit -m` retry pattern worked first-try with all three PASS verdicts in place. No new evidence to append.

The architect+JTBD gate misfire on `docs/retros/` despite the P203 exclusion is recorded in Pipeline Instability above. The class (marketplace-cache staleness) is documented framework property; no codification needed.

## Tickets Deferred

(none — every observation reached the framework-resolved path or was logged in the retro proper.)

## No Action Needed

- The closure transition itself — P227 transitioned cleanly via the ADR-079 KE→Closed direct path, mirroring the cohort of recent KE→Closed-as-Superseded cases earlier this week.
- The commit gate stack (pipeline + external-comms + voice-tone) — returned PASS on all three layers with commit=1/25, well within appetite; landed via standard `git commit -m` without BYPASS.

## Notes

- P227 is the **SEVENTH** KE→Closed-as-Superseded case this week (P216 / P292 / P217 / P218 / P222 / P225 / P227), all riding the unratified ADR-079 lifecycle extension. The pattern is operational, predictable, and self-documenting — but the lifecycle-extension authority (ADR-079) is itself unratified. Ratification drain remains queued at orchestrator level (system-reminder #2 at session start). The drain is now load-bearing for the entire weekly closure cadence.
- Distinction worth pinning for future ratifications of similar policy refinements: rollback-CAPABILITY (the system is architected to support rollback) is a design-class control that MAY reduce impact band per RISK-POLICY.md line 169 with explicit-rationale gating. rollback-READINESS (we'll be on-call to roll back if needed) is a post-release follow-up that MUST NOT reduce residual per the agent-prose in pipeline.md/plan.md/wip.md. The semantic gap was the substantive concern P227 raised; the resolution is that the policy already drew the line (line 169's explicit-rationale qualifier IS the gate keeping rollback-capability out of casual residual-reducer credit), and the agent-prose makes the prohibition on rollback-readiness explicit.
- Inbound-discovery #56 mirror entry (line 270 in docs/problems/README.md) was updated from `pending-pipeline-processing` to a structured `superseded — ...` annotation citing the supersession SHA + scope. This mirrors the convention established by the P224 / P225 closures earlier this session and maintains the cache's traceability without disturbing the lazy-empty discipline.
- Iter was light-touch: docs-only, three files staged, clean linear gate sequence at commit, no wrapper invocations, no retries. This is the desired baseline operational shape for KE→Closed-as-Superseded iters where the prior fix is already shipped.
- Architect+JTBD gate misfire on `docs/retros/` was the ONLY operational friction this iter — recoverable via two subagent round-trips; cache staleness, not a policy gap. Recommend `/install-updates` at loop end.
