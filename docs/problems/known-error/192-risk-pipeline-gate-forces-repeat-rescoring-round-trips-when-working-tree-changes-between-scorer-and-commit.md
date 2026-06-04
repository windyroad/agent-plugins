# Problem 192: Risk-pipeline gate forces repeat rescoring round-trips when the working tree changes between scorer invocation and `git commit`

**Status**: Known Error
**Reported**: 2026-05-15
**Priority**: 6 (Med) — Impact: 3 (Moderate — repeated subagent round-trips inflate session cost) x Likelihood: 2 (Possible — fires when iteratively staging + committing) (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Description

The commit-discipline hook (`packages/risk-scorer/hooks/risk-score-commit-gate.sh` and siblings) enforces that the working-tree state at commit time matches the state the most-recent `wr-risk-scorer:pipeline` agent scored. When ANY working-tree change happens between the scorer fire and `git commit`, the gate emits "Pipeline state drift: working tree changed since the last commit risk assessment" and forces a re-delegation to `wr-risk-scorer:pipeline` before the commit can proceed.

In the 2026-05-15 P038 fix session this fired **at least 3 times**:
1. Initial P038 commit attempt blocked by P159 JTBD currency drift; required README staging; pipeline rescore on the re-attempt.
2. P079 ADR-062 + P079 RCA commit: README change unstaged between pipeline-score and commit; required re-stage + pipeline rescore.
3. Slice A + D scaffold commit: working tree clean at scorer time, but the test-loop drift detection still required a fresh-state confirmation.

Each rescore round-trip is one full subagent invocation (~10-30 seconds + token cost). The drift detector's "any working-tree change invalidates the score" semantics is conservative — appropriate for source-code commits where a single staged file change could shift risk, but excessive for sequenced commits in the same session where the work-being-committed AND its risk profile are constant.

## Symptoms

- "Pipeline state drift: working tree changed since the last commit risk assessment" appears multiple times per session during incremental commit work.
- Each occurrence requires invoking `wr-risk-scorer:pipeline` and waiting for the structured verdict before `git commit` succeeds.
- The repeat-work pattern qualifies as Step 2b Repeat-work friction (≥3 applications in one session).

## Workaround

Two known workarounds:

1. **Stage everything before invoking pipeline-score** — then commit immediately. Forces a strict "score then commit" sequence; works but constrains iterative work patterns (where the user / agent realises a small additional fix mid-commit-flow).
2. **Score then commit immediately without any intervening edits** — works but doesn't survive natural mid-session corrections (e.g. fix a typo in a stage-already-included file).

## Impact Assessment

- **Who is affected**: solo-developer (JTBD-001) doing iterative commit work; AFK orchestrator (JTBD-006) running multi-commit iterations.
- **Frequency**: 3+ times per multi-commit session; scales linearly with commit-count.
- **Severity**: Moderate — token cost + latency, not correctness; the conservative drift detection IS protecting against real "risk score doesn't match what's about to commit" anomalies.
- **Analytics**: deferred to investigation.

## Root Cause Analysis

### Investigation Tasks

- [ ] Quantify rescore round-trip cost (turn count, agent invocations, observable latency) across a typical multi-commit session — establish a baseline before fixing.
- [ ] Investigate "incremental drift" detection: can the gate hash only the STAGED set (not the whole working tree) and rescore-only-on-staged-changes? Working-tree changes outside the staged set don't affect the commit's risk profile.
- [ ] Investigate "score-survives-additive-stages" rule: if the new staged set is a strict superset of the previously-scored set AND the additions are docs-only (or otherwise trivially-classifiable), allow the score to ride forward without a fresh agent invocation.
- [ ] Decide whether the conservative current behaviour is the correct default vs an opt-in "strict" mode.
- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems.

### Confirmed root cause (2026-06-04) — promoted to Known Error

Code-read RCA of `packages/risk-scorer/hooks/risk-score-commit-gate.sh` + `lib/pipeline-state.sh` + `risk-score-mark.sh` identifies **two distinct mechanisms**, of which the original ticket's "over-conservative full-tree hash" hypothesis is now only partly accurate:

1. **PRIMARY root cause — the within-appetite / risk-reducing bypass marker is SINGLE-USE.** `risk-score-commit-gate.sh` consumes the `reducing-commit` marker with `rm -f "${RDIR}/reducing-commit"` then `exit 0`. So each commit in a multi-commit session permits exactly ONE commit before the marker is gone; the next commit re-enters `check_risk_gate`, finds no marker, and forces a fresh `wr-risk-scorer:pipeline` round-trip — even when the work and its risk profile are unchanged. (Contrast: the `clean` marker is NOT removed, so clean-tree commits ride forward.) This is the dominant driver of the "3+ rescores per session" friction — observed again 2026-06-04: 5 commits this session each required a fresh scorer invocation purely to re-mint the consumed one-shot marker.

2. **SECONDARY — drift hash is already much narrower than the ticket assumed.** `pipeline-state.sh --hash-inputs` uses a `git stash create` conceptual-tree hash that is (a) **commit/push-stable** (P054 — tree SHA invariant over commit and push) and (b) **doc-excluded** via `_doc_exclusions` (docs/, `.changeset/` body, governance paths). So docs-only additive stages do NOT trip drift, and the "stage retro + README + ticket in sequence" case the ticket worried about is already handled. The residual drift trigger is narrow: a *source-file* (non-doc) working-tree change between score and commit. The changeset COUNT line is the one doc-adjacent input that can still shift the hash when a `.changeset/*.md` is added/removed.

**Net**: the friction is dominated by mechanism (1), not (2). The original "staged-set-only hash + additive-docs carve-out" fix proposal is largely already implemented for the hash; the unaddressed gap is the one-shot marker lifecycle.

### Fix Strategy (for the RFC phase — NOT yet implemented)

**Kind**: improve (marker lifecycle).

**Shape (candidate, needs RFC)**: make the within-appetite/reducing bypass **session-scoped with drift-revalidation** rather than strictly one-shot — i.e. the marker survives multiple commits within the TTL window AS LONG AS the pipeline-state hash still matches what was scored (re-mint only on genuine drift or TTL expiry or threshold change). This preserves the "score reflects what's committed" contract (drift still forces a rescore) while eliminating the re-mint-per-commit round-trip when the risk profile is constant. Decision point for the RFC: does the reducing-bypass need per-commit granularity (current) or is hash-stable-within-TTL sufficient? The `clean` marker's persist-until-drift semantics are the in-repo precedent for the latter. Composes with P107 (TTL extension) + P090 (hard-cap) + P326 (staged-index interaction — verify the re-stage requirement is/ isn't a separate marker-side effect).

### Preliminary Hypothesis (superseded by the confirmed root cause above)

The drift detector hashes the full working-tree fingerprint and invalidates the score on any change. This is over-conservative for the common case where:
- New files are staged additively (e.g. retro report + README update + ticket file all in sequence).
- The work is docs-only across the whole sequence.
- The risk profile is constant by inspection (the same person doing the same work).

A staged-set-only hash + a "score survives additive docs-only stages" carve-out would eliminate most of the friction without compromising the drift-detection contract for source-code commits.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P107 (gate marker TTL extension), P090 (gate marker hard-cap), P173 (BYPASS env vars don't propagate — same gate-context family)

## Related

- `packages/risk-scorer/hooks/risk-score-commit-gate.sh` — the gate emitting the drift error.
- `packages/risk-scorer/hooks/risk-hash-refresh.sh` — the hash-refresh hook the drift detector consults.
- `packages/risk-scorer/hooks/lib/pipeline-state.sh` — the pipeline-state hashing implementation.
- ADR-009 — gate marker lifecycle; the drift detector composes with the marker lifecycle.
- Captured by `/wr-retrospective:run-retro` Step 4b Stage 1 + user direction "don't defer the stage 1 ticketing" (2026-05-15).
