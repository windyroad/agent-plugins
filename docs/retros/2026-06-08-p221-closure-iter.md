# Retro — 2026-06-08 P221 closure iter (work-problems AFK)

Single AFK iter from `/wr-itil:work-problems` orchestrator. Outcome: P221 closed as superseded by P208. One commit landed: `7a58069`.

## Iteration summary

- **Ticket**: P221 (work-problems Step 6.5 lacks baseline CI health check before drain — safe-high-fix-risk, sibling P208/#86, upstream-mirror of #62)
- **Action**: worked → closed (superseded)
- **Commit**: `7a58069 chore(itil): close P221 as superseded by P208 — CI-health gate now inherited via push-gate`
- **Risk scores**: `commit=2 push=1 release=1` (within appetite, reducing bypass per ticket-closure criterion)
- **Released?**: No (orchestrator constraint — no push/release)
- **Files touched**: `docs/problems/{known-error→closed}/221-*.md` (rename + closure body), `docs/problems/README.md` (WSJF row removed, Closed table row added, Last reviewed rotated), `docs/problems/README-history.md` (P223 fragment appended)

## What was decided and why

Investigation confirmed that P208's sibling fix (commit `fe51ed4` 2026-06-06 `fix(risk-scorer): P208 push/release gate consults CI status before scoring`) **structurally subsumes P221**. The push-gate hook now intercepts the literal shell commands that Step 6.5's Drain action invokes:

- `packages/risk-scorer/hooks/git-push-gate.sh` line 36 regex matches `npm run push:watch`; line 54 calls `check_ci_status`.
- `packages/risk-scorer/hooks/git-push-gate.sh` line 90 regex matches `npm run release:watch`; line 109 calls `check_ci_status`.
- `packages/itil/skills/work-problems/SKILL.md` lines 805-806: Drain action runs `npm run push:watch` then conditionally `npm run release:watch` — the exact strings the push-gate intercepts.
- `packages/risk-scorer/hooks/lib/risk-gate.sh` lines 156-300: `check_ci_status` queries `gh run list --branch <current> --limit 1` and denies on `conclusion ∈ {failure, cancelled, timed_out, action_required, startup_failure}` or `status ∈ {queued, in_progress, pending, requested, waiting}`. Fail-CLOSED on gh exit non-zero / parse error (lines 213 + 252) per the safe-high-fix-risk classifier in P208's commit body.
- `packages/risk-scorer/hooks/test/ci-status-gate.bats` (16 behavioural tests) covers the contract for both `push:watch` and `release:watch` integration.

This matches **every** Investigation Task in P221's ticket body:
- Task #3 ("baseline CI-health check that halts drain on `conclusion: failure` / `conclusion: cancelled`") → satisfied verbatim by the conclusion-denial list.
- Task #2 ("design the gate to fail-CLOSED on API/auth/pending") → satisfied by the gh-error + parse-error fail-CLOSED branches.
- Task #2 ("coordinate with sibling P208/#86 push-gate hardening") → satisfied by the fix landing on the push-gate surface (which IS P208).
- The safe-high-fix-risk over-blocking concern (transient CI flake) → handled by the one-shot `${RDIR}/ci-bypass-${ACTION}` marker + empty-CI-history natural-allow.
- The JTBD-201 hotfix-path concern → handled by ordering `incident-release` short-circuit BEFORE the CI check at lines 98-101.

P221 is the **9th KE→Closed-direct** closure this week (sibling P216 / P217 / P218 / P222 / P223 / P224 / P225 / P227) — continues to accumulate ADR-079 Phase 2 ADR-supersession-shape load-bearing evidence for the upcoming `/wr-architect:review-decisions` ratification per outstanding-question queue #2.

## Pipeline Instability (Step 2b)

| Signal | Category | Citations | Decision |
|--------|----------|-----------|----------|
| External-comms gate denied initial `git commit` even though both PASS verdicts (risk-scorer + voice-tone) had not yet been emitted — but the gate's error message was clearly directive (named the subagent_type + the `<draft>` wrap contract) and the recovery was one round-trip per verdict | Hook-protocol friction (expected behaviour, not friction per se) | First `git commit` attempt returned `BLOCKED (external-comms gate / risk evaluator): git-commit-message draft has not been reviewed by wr-risk-scorer:external-comms`; the agent delegated to `wr-risk-scorer:external-comms` then `wr-voice-tone:external-comms` (verdict shape: PASS + PASS); commit re-attempted successfully | matches existing P353 (substance-aware hash + atomic verdict-write — Verifying since 2026-06-06) family; this iter the gate behaved correctly (denied on missing marker; passed after both verdicts landed). No `BYPASS_RISK_GATE=1` needed. P353 sibling-recurrence note in outstanding-question queue #7 does NOT need additional evidence from this iter — the gate fired correctly here |

README inventory currency: clean (13 packages; 0 drift instances per `wr-retrospective-check-readme-jtbd-currency`).

## Verification Candidates (Step 4a)

None this iter — same-session verifying exclusion applies; no prior-session `.verifying.md` ticket evidence was exercised by this iter's tool-call history (the iter scope was bounded to P221 closure-as-superseded, which exercised no `.verifying.md` fix paths).

## Topic File Rotation Candidates (Step 3)

Step 3 Tier 3 budget pass found 4 OVER files (none MUST_SPLIT — all between 1.0× and 2.0× the 5120-byte threshold):

| Topic file | Bytes | Threshold | Proposed rotation | Decision |
|------------|-------|-----------|-------------------|----------|
| `docs/briefing/afk-subprocess.md` | 6564 | 5120 | split-by-date (safe default) | deferred — known backlog ticket P195 (Briefing Tier 3 rotation repeat-deferral) owns the multi-file rotation pass; iter-mode AFK retro defers to interactive retro / explicit rotation surface |
| `docs/briefing/agent-interaction-patterns.md` | 5994 | 5120 | split-by-date (safe default) | deferred — same P195 backlog item |
| `docs/briefing/governance-workflow.md` | 5839 | 5120 | split-by-date (safe default) | deferred — same P195 backlog item |
| `docs/briefing/releases-and-ci.md` | 7091 | 5120 | split-by-date (safe default) | deferred — same P195 backlog item |

P195 acknowledges the recurring-defer anti-pattern (P145 sibling); the appropriate fix is the dedicated rotation pass on the WSJF queue, not 4-file rotations inline in every closure iter (would balloon iter scope every loop and burn the AFK budget on non-iter-ticket work).

## Briefing Changes (Step 3)

Scanned 0 candidate observations from this iter's bounded scope; 0 accepted. The iter's tool-call history (read SKILL, scan push-gate, write ticket body, write README rows, commit) produced no cross-session-novel observations not already captured in the briefing tree. Closure-as-superseded mechanics are well-codified in the manage-problem SKILL and the README's prior 8 Closed-section rows establish the precedent.

## Signal-vs-Noise Pass (Step 1.5)

Not run this iter (iter-mode skip per ADR-013 Rule 5 — signal-scoring on briefing entries requires cross-session signal accumulation; single-ticket iter context is too narrow to score noise reliably). Persistence deferred to next interactive retro per the documented iter-mode pattern (P217 / P222 / P223 / P227 closures earlier today followed the same pattern).

## Context Usage Cheap Layer (Step 2c)

`wr-retrospective-measure-context-budget` exit=0:

| Bucket | Bytes | Note |
|--------|-------|------|
| problems | 4,708,982 | largest; problem-ticket corpus continues to dominate per P282 / P195 backlog |
| decisions | 1,867,805 | second-largest; ADR corpus |
| skills | 1,149,728 | third-largest |
| hooks | 493,926 | fourth |
| memory | 408,850 | fifth |
| briefing | 98,947 | sixth |
| jtbd | 55,461 | seventh |
| project-claude-md | 4,277 | eighth |
| framework-injected | not-measured | reason: framework-injected-no-on-disk-source |
| THRESHOLD | 10,240 | configured ceiling |

Top-5 offenders unchanged from prior iter snapshots (P229, P223 retros earlier today). Per ADR-026: no prior-snapshot delta column computed (no `<!-- context-snapshot:` trailer present in last `docs/retros/*-context-analysis.md`; not estimated — no prior data sentinel applies). Deep analysis recommended cadence: `/wr-retrospective:analyze-context` if any bucket grows ≥ +20% from prior measurement; routine advisory, not blocking.

## Codification Candidates (Step 4b)

No Stage 1 mechanical-auto-ticket observations from this iter — pipeline-instability surface was clean (the external-comms gate fired correctly; voice-tone deferred-tool-schema flow surfaced no friction; risk-scorer pipeline scored within appetite first-pass). No new codification candidates.

## Tickets Deferred

None — no Stage 1 fallback fired.

## Ask Hygiene (Step 2d)

This iter: **zero** `AskUserQuestion` calls (orchestrator constraint: `NEVER call AskUserQuestion`). Cross-session trend lazy-count contribution from this iter: 0.

Trail recorded at `docs/retros/2026-06-08-p221-iter-ask-hygiene.md`.
