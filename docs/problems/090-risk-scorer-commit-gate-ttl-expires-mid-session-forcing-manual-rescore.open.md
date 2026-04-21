# Problem 090: risk-scorer commit-gate bypass-marker TTL (1800s) expires mid-session, forcing a manual rescore round-trip on every long-flow commit

**Status**: Open
**Reported**: 2026-04-22 (user-initiated — elevating from BRIEFING line 61 candidate to ticketed problem after P089/P087 session citations)
**Priority**: 9 (Medium) — Impact: Moderate (3) x Likelihood: Likely (3)
**Effort**: M — amend `packages/risk-scorer/hooks/risk-score-commit-gate.sh` (and the sibling push-gate / release-gate hooks if they share TTL mechanics) to implement a **three-band TTL policy** instead of the current binary "fresh / expired" check: (a) < 15 min → pass silently; (b) 15-30 min → auto-invoke `wr-risk-scorer:pipeline` inline and either pass-if-unchanged or halt-and-report-if-changed; (c) > 30 min → halt with the existing "delegate to risk-scorer" message. Bats contract assertion for each band. Architect review on the auto-rescore-in-band semantics (may need an ADR note under ADR-009's marker-TTL lifecycle or ADR-015's on-demand-assessment contract).
**WSJF**: 4.5 — (9 × 1.0) / 2 — Medium severity (friction on every long-flow commit; no loss of work, no incorrect scoring — just redundant round-trip); moderate effort. Sits alongside P067 / P076 class tickets.

## Description

The risk-scorer commit-gate hook (`packages/risk-scorer/hooks/risk-score-commit-gate.sh` via ADR-009's marker-TTL lifecycle) blocks `git commit` when the most recent `wr-risk-scorer:pipeline` bypass marker is older than 1800s (30 minutes). This matches the architect/JTBD marker TTL (BRIEFING line 35), and the symmetry is intentional — it prevents stale risk assessments from approving commits against changed working trees.

In **long-flow sessions** the TTL expires mid-work even when the working-tree state hasn't meaningfully changed. The user hits an extra turn of:

1. `git commit -m "..."` → hook blocks with `Push blocked: Push risk score expired (<N>s old, TTL 1800s). Delegate to risk-scorer to rescore.` (or the commit-gate equivalent).
2. Delegate to `wr-risk-scorer:pipeline` via the Agent tool.
3. Receive identical (or trivially-different) `RISK_SCORES: commit=X push=Y release=Z` line.
4. Retry `git commit` — now passes.

This is pure round-trip friction. On a long session with multiple commits spaced > 30 min apart, the user pays the full 3-step dance every time. No scoring decision actually changes in the common case — the working-tree delta is tiny or nil.

## Symptoms

Two citations this session (2026-04-21 AFK-iter-7 + post-retro):

1. **Post-@windyroad/itil@0.14.0 release, BRIEFING update commit** (2026-04-21 ~20:00): hook fired with `Pipeline state drift: working tree changed since the last commit risk assessment. Delegate to wr-risk-scorer:pipeline (subagent_type: 'wr-risk-scorer:pipeline') to rescore against the current state.` — despite the staged diff being a trivial BRIEFING.md edit (3 lines added). Manual rescore returned the same risk band; commit proceeded.

2. **Final retro-wrap push-watch** (2026-04-22 ~00:20): hook fired with `Push blocked: Push risk score expired (2826s old, TTL 1800s). Delegate to risk-scorer to rescore.` while draining two docs-only ticket commits. Manual rescore; push proceeded.

Prior citation in BRIEFING line 61: 87-minute gap between P081-commit and P082-ticket-creation commit produced `Risk score expired (5176s old, TTL 1800s)` — similarly stale-but-unchanged state.

## Workaround

Delegate to `wr-risk-scorer:pipeline` via Agent tool → read `RISK_SCORES:` line → retry commit. Adds 2-3 turns per long-flow commit. Observable.

## Impact Assessment

- **Who is affected**:
  - **Solo-developer persona (JTBD-001 Enforce Governance Without Slowing Down)** — "without slowing down" axis. Every mid-session long-gap commit pays the 3-step dance even when the working tree is unchanged. Directly degrades the JTBD-001 "reviews complete in under 60 seconds" outcome — the rescore round-trip adds 20-40s every time the gate fires stale.
  - **AFK orchestrator (JTBD-006 Progress the Backlog While I'm Away)** — Step 6.5 release-cadence delegation already handles this for the pipeline-drain path, but inter-iteration commits by the subprocess can also hit this. The subprocess's inline rescore handles it but costs tokens every iteration.
- **Frequency**: every commit where `now - marker_mtime > 1800s`. In long sessions (> 30 min between commits) this is essentially every other commit. Compounds across sessions.
- **Severity**: Medium. No work lost, no wrong scores, no incorrect commits — just persistent per-commit overhead that adopters can't opt into or tune.

## Root Cause Analysis

### Structural

The commit-gate hook implements a **binary TTL** — fresh (within window) or expired (bounce). There's no gradient between "definitely still valid" and "worth re-checking just in case". ADR-009 codified the TTL primitive for marker-lifecycle tracking but didn't distinguish "scoring-input drift" (working tree actually changed) from "wall-clock drift" (clock ticked past TTL but working tree identical).

Today's hook computes `state_hash = hash(git diff --cached)` at marker-write time and compares against `current_state_hash = hash(git diff --cached)` at marker-check time. If they don't match, "Pipeline state drift". But if they DO match (user left session open for 31 min, tree unchanged), the hook still bounces on the wall-clock age alone — the state-hash comparison isn't consulted once the clock has expired.

That's the root cause: wall-clock age gates first; state-hash comparison gates second. Reversing the order (or adding a middle band) would short-circuit the common case.

### Candidate fix (from BRIEFING line 61)

**Three-band TTL policy:**

- **< 15 min since last score** → pass silently. Fresh.
- **15-30 min** → auto-invoke `wr-risk-scorer:pipeline` inline from the hook (policy-authorised per ADR-013 Rule 6 since it's a re-read of the same state, not a new decision) and:
  - If the new `RISK_SCORES:` matches the marker's recorded scores AND working tree hash matches → pass silently. The "rescore" was confirmatory.
  - If scores or hash diverged → halt with the existing message; user must reconcile.
- **> 30 min** → halt with the existing "delegate to risk-scorer" message. User wakes up to a stale-session gate; explicit rescore is the right bar.

The 15-min threshold mirrors the prompt-cache TTL (5-min ephemeral + 15-min extended) and the Claude Code subagent session cache. Above 15 min, the cost to re-check is low (cached context is warm if the last rescore is recent).

### Alternative: stateful-recency on the state-hash

Instead of wall-clock bands, key the TTL entirely on state-hash invariance — if `hash(git diff --cached)` matches the marker's recorded hash, the marker stays valid regardless of age. Wall-clock only starts the countdown once the state hash changes. This is strictly more efficient but requires a marker-shape change (record the scoring-input hash alongside the score). Candidate for an architect review at implementation.

Recommended: **three-band policy as the forward-compatible step**; the pure state-hash approach is a deeper refactor tracked as a follow-up if the three-band version's 15-30 min middle band still produces friction.

## Related

- **ADR-009** (marker-TTL lifecycle primitive) — parent ADR the three-band policy amends.
- **ADR-013** (structured user interaction) — Rule 6 authorises the auto-rescore in the middle band as a policy-authorised re-read (not a new decision).
- **ADR-015** (on-demand assessment skills) — `wr-risk-scorer:pipeline` contract this fix invokes in the middle band.
- **P083** (iteration-worker ScheduleWakeup contract) — adjacent hook-protocol concern flagged earlier this session; same class of friction but different trigger.
- **BRIEFING line 35** (architect/WIP/TDD marker ~1800s TTL) — same TTL mechanism on the edit-gate side; the three-band policy would apply there too as a follow-up but is not in scope for this ticket.
- **BRIEFING line 61** — prior in-session capture that proposed the three-band candidate; this ticket elevates that candidate to a tracked problem.
- `packages/risk-scorer/hooks/risk-score-commit-gate.sh` — primary implementation target.
- `packages/risk-scorer/hooks/test/` — bats contract assertion location.
- `packages/risk-scorer/skills/assess-release/SKILL.md` — the skill used to rescore (ADR-015 fallback path).

### Investigation Tasks

- [ ] Architect review on the three-band policy vs the stateful-recency alternative (ADR-009 amendment scope).
- [ ] Decide whether the three-band policy also applies to the architect/JTBD PreToolUse markers (symmetric fix) or stays risk-scorer-only.
- [ ] Implement `packages/risk-scorer/hooks/risk-score-commit-gate.sh` three-band logic. Same for sibling push/release gates if they share TTL.
- [ ] Bats contract assertions for each of the three bands (fresh / auto-rescore / halt).
- [ ] Changeset: @windyroad/risk-scorer minor bump.
