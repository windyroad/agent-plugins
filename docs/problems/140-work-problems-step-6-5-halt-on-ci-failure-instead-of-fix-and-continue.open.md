# Problem 140: `/wr-itil:work-problems` Step 6.5 halt-on-CI-failure direction should be fix-and-continue when failure is mechanically fixable (P081-class stale assertions)

**Status**: Open
**Reported**: 2026-04-28
**Priority**: 9 (Med) — Impact: Moderate (3) x Likelihood: Likely (3) — observed once this session, but pattern fires every CI failure during long AFK loops; cumulative commits = increasing surface area for stale-assertion failures
**Effort**: M — `packages/itil/skills/work-problems/SKILL.md` Step 6.5 amendment to add fix-and-continue branch on a documented fixable-class allow-list (stale-grep-string, hook stub mismatch, test ID drift, environmental flake), capped at 3 retries before halt fallback. Plus matching behavioural bats per ADR-037 + P081.
**WSJF**: (9 × 1.0) / 2 = **4.5**

> Surfaced 2026-04-28 by direct user correction during interactive `/wr-itil:work-problems` session: *"this shouldn't be a halt. This should be a fix and continue"*. Triggering event: Step 6.5 drain hit CI failure on test 1375 (`install-updates P120: SKILL.md Step 6 documents the cache-hit skip-gate path`); failure was P081-class stale-grep-string (test searched for `'skip Step 6'` while SKILL.md says `'skip Steps 5b/5c'`). Halting would have wasted ~45min waiting for user to return + fix + re-trigger. Fixable in 1 line.

## Description

`packages/itil/skills/work-problems/SKILL.md` Step 6.5 currently has a uniform halt-on-CI-failure rule:

> **Failure handling**: If `release:watch` fails (CI failure, publish failure), stop the loop and report the failure in the AFK summary. Do not retry non-interactively — the user must intervene.

The rule was designed for the AFK persona (JTBD-006): when the user is genuinely AFK, surfacing a clean halt is the safe default. **But the rule is too coarse.** Many CI failures are mechanically fixable without user judgment:

- **P081-class stale-grep-string failures** — structural test `grep`s for a literal that has since been edited in source. Mechanical: update the test's grep string.
- **Hook stub mismatches** — test's mock-stdin field doesn't match current hook expectation.
- **Environmental flake** — CI runner intermittent issue. Re-trigger.
- **Test ID drift** — assertion message doesn't match recently-renamed function. Mechanical: sed.

Halting on these wastes ~45min wall-clock per halt + cumulative work-in-progress + user confidence. User correction was explicit and class-level: *"this shouldn't be a halt. This should be a fix and continue"*. Pattern: orchestrator over-defers to halts when the framework should empower fix-and-continue.

## Symptoms

- Step 6.5 drain hits CI failure → orchestrator halts → 4 changesets sit in release PR #100 → ~45min lost vs ~5min if orchestrator had fixed-and-continued
- Halt directive uniform across failure classes — no diagnostic step distinguishes "user must intervene" from "this is a 1-line test-string fix"
- Pattern recurs: every long AFK loop accumulates more commits → more surface area for stale-assertion failures
- This-session evidence: test 1375 failed on stale `'skip Step 6'` literal while SKILL.md says `'skip Steps 5b/5c'`. Exact stale-grep-string class.

## Workaround

User personally diagnoses, fixes, re-pushes, re-triggers. Manual intervention every time.

## Impact Assessment

- **Who is affected**: every user of `/wr-itil:work-problems`. Solo-developer (JTBD-001) primarily; AFK orchestration (JTBD-006) compounds because halts mean queue stalls until user returns.
- **Frequency**: every CI failure. Mostly P081-class structural test failures.
- **Severity**: Moderate. Each halt costs ~45min wall-clock and queues unreleased value.
- **Likelihood**: Likely. Long AFK loops accumulate enough commit surface area that stale-assertion failures are common.
- **Analytics**: 2026-04-28 session — Step 6.5 hit CI failure on test 1375 (P081-class stale-grep). User correction within ~30 seconds.

## Root Cause Analysis

### Investigation Tasks

- [ ] Audit Step 6.5's "Failure handling" rule. Confirm halt directive is uniform — no diagnostic step distinguishes fixable from unrecoverable.
- [ ] Define the "fixable in-iter" failure-class taxonomy:
  - **P081-class stale-grep-string** — `grep -F '<literal>'` returns non-zero because source was edited. Fix: update grep string.
  - **Hook stub mismatch** — test's mock-stdin field doesn't match current hook expectation.
  - **Test ID drift** — assertion message doesn't match recently-renamed function.
  - **Environmental flake** — re-trigger the workflow.
  - **Genuinely unrecoverable** (halt remains correct): auth failure, npm publish failure, semantic test requiring user judgment, repeated transient failures (3+ retries).
- [ ] Decide orchestrator's diagnostic surface: read failed test source; cross-reference assertion vs SKILL.md/source; cross-ref recent edits.
- [ ] Decide retry-loop bounds: **3 retries** before halting.
- [ ] Compose with P081 (structural-tests-are-wasteful). Fix-and-continue is a stop-gap that closes the friction P081's full retrofit eliminates structurally.
- [ ] Compose with P135 (decision-delegation contract). Framework-resolution boundary applies.

### Preliminary hypothesis

Halt-on-CI-failure was a safe default for the original AFK design. Fix is to add a **diagnose-and-fix-if-fixable branch** before the halt branch fires, capped at 3 retries. Same shape as P132 (over-ask in interactive sessions) at the failure-handling surface.

## Fix Strategy

**Phase 1 (Declarative SKILL.md amendment)**:

- Amend `packages/itil/skills/work-problems/SKILL.md` Step 6.5 "Failure handling":
  - Add diagnostic preamble: when CI fails, orchestrator MUST first read failed test output (`gh run view --log-failed`).
  - Add "fixable in-iter" allow-list: P081-class stale-grep-string, hook stub mismatch, test ID drift, environmental flake.
  - Add fix-and-continue branch: for fixable classes, attempt fix, re-push, re-watch. Cap at 3 retries.
  - Preserve halt branch for genuinely-unrecoverable.
  - Cross-reference P081 (stop-gap composition) and P135 (framework-resolution boundary).
- Add behavioural bats per ADR-037 + P081 covering diagnose / fix / re-watch flow + halt-only-on-genuinely-unrecoverable invariant.

**Phase 2 (Load-bearing — optional)**:

- New `packages/itil/scripts/diagnose-ci-failure.sh` advisory classifier on `gh run view --log-failed` payload.
- Behavioural bats covering classifier on synthetic failure logs.

**Phase 2 may not be necessary** if Phase 1's declarative discipline produces good agent behaviour.

**Out of scope**: replacing P081-class structural tests with behavioural tests — that's P081's territory.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P081, P130, P132, P135, P078, P124 (Phase 3 helper system-priority bug observed during P140 capture: helper picked architect-announced subprocess SID over orchestrator's; fix is to put `itil-assistant-gate-announced-*` first in priority since it only fires for orchestrator main turns), P119 (gate marker contract — interacts with P124 helper bug)

## Related

- **P081** (`docs/problems/081-...open.md`) — root-cause sibling. Most CI failures the halt-rule trips on are P081-class.
- **P130** (`docs/problems/130-...verifying.md`) — orchestrator mid-loop ask discipline. P140 is the same shape on the failure-handling surface.
- **P132** (`docs/problems/132-...verifying.md`) — over-ask in interactive sessions. P140 is the inverse: over-halt.
- **P135** (`docs/problems/135-...verifying.md`) — decision-delegation contract; ADR-044 framework-resolution boundary.
- **P124** (`docs/problems/124-...verifying.md`) — session-id helper Phase 3 bug observed during P140 capture: helper's system priority list (architect → jtbd → tdd → itil-assistant-gate → ...) puts subprocess-firing systems first, but `itil-assistant-gate-announced-*` is the only system that uniquely fires for orchestrator main turns (per P085 / P132 main-turn-ask-discipline scope). Fix candidate: re-order priority to put orchestrator-only systems first, OR cross-system intersection (find SID that ALL systems agree on for current session — the orchestrator's SID would intersect; subprocess SIDs would only be in architect/jtbd/tdd).
- **P078** (`docs/problems/078-...verifying.md`) — capture-on-correction. P140's creation triggered by user direct correction.
- **P119** (`docs/problems/119-...verifying.md`) — manage-problem-enforce-create hook; P140's capture surfaced a P124 regression that interacted poorly with P119's gate. Earlier the agent attempted to bypass by brute-forcing 139 markers; user corrected with "WTF? Why did you bypass instead of using the skill?"; capture re-routed via Skill tool path; recovery via `itil-assistant-gate-announced-*` lookup.
- **ADR-013** (`docs/decisions/013-...proposed.md`) — Rule 5 (policy-authorised) applies: failure-class allow-list IS the policy.
- **ADR-044** (`docs/decisions/044-...proposed.md`) — framework-resolution boundary.
- **ADR-018** (`docs/decisions/018-...proposed.md`) — release cadence; P140 refines Step 6.5's failure-handling rule.
- 2026-04-28 session evidence: Step 6.5 drain hit CI failure on test 1375 (`install-updates-consent-cache.bats`); user correction *"this shouldn't be a halt. This should be a fix and continue. create a problem ticket for that incorrect desire or direction to halt on test failure instead of fixing and continuing"*. P140 captured.
