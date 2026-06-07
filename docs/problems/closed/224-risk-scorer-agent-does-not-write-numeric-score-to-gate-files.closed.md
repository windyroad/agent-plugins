# Problem 224: Risk-scorer agent does not write numeric score to gate files

**Status**: Closed (Superseded)
**Reported**: 2026-05-15
**Closed**: 2026-06-08 (work-problems AFK iter — superseded by ADR-015 § PostToolUse-Agent hook contract; the agent-emit + hook-parse + hook-write pipeline is fully wired)
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Resolution

**Closed as Superseded 2026-06-08.** The reported gap — "agent produces reports but numeric scores never land in the gate files" — is structurally impossible against the current pipeline. The end-to-end wire is:

- **Agent emits the structured score block.** `packages/risk-scorer/agents/pipeline.md` line 19 mandates: *"Your report MUST end with a structured `RISK_SCORES` block. This is how the hook knows what to write: `RISK_SCORES: commit=N push=N release=N`."* Line 14 reinforces: *"Do NOT write score files yourself. A PostToolUse hook reads your output and writes files deterministically."*
- **Hook parses the score line.** `packages/risk-scorer/hooks/risk-score-mark.sh` lines 41-45 greps `^RISK_SCORES:` from the agent output and extracts the `commit=`, `push=`, `release=` integers.
- **Hook writes the gate files.** Lines 51-53 write each integer to `${RDIR}/commit`, `${RDIR}/push`, `${RDIR}/release` (where `${RDIR}` is `${TMPDIR:-/tmp}/claude-risk-${SESSION_ID}/` per `gate-helpers.sh::_risk_dir`) and touches the `-born` sibling markers (P090 Band B TTL hard-cap). The original ticket's `/tmp/risk-{commit,push,release}-{SESSION_ID}` path shape has moved to a session-scoped subdirectory under the same root.
- **ADR-015 § PostToolUse-Agent hook contract** (lines 112, 118-119) documents the explicit pipeline: *"the `PostToolUse:Agent` hook (`risk-score-mark.sh`) reads the structured `RISK_SCORES` / `RISK_BYPASS` output and writes the bypass marker files … exactly as it does when the pipeline mode is triggered by a commit attempt"* — citing the chain `pipeline agent outputs: RISK_SCORES: commit=N push=N release=N → risk-score-mark.sh PostToolUse hook writes the marker files`.

**Investigation Task #2** (*"Extend the agent's emit-shape to write numeric scores back to gate files OR have the PostToolUse mark-reviewed hook parse the agent's score block and write it"*) is satisfied — the second branch (hook parses score block, writes gate files) is the implemented design and has been in production since the ADR-015 hook contract landed. Verified in-session: every scorer verdict this AFK loop has emitted the canonical `RISK_SCORES:` line and the gates have proceeded against the hook-written numeric values.

**Investigation Task #1** (Priority/Effort re-rate at next `/wr-itil:review-problems`) is moot at closure — Closed tickets are excluded from WSJF ranking.

**Why "no further work"**: P224 (2026-05-15) pre-dates the ADR-015 PostToolUse-Agent hook contract being load-bearing. The original ticket described the pre-contract state where the hook pre-created placeholder files with no parsing path. The current implementation matches the second of the two options the ticket itself proposed.

No code change in this transition; KE→Closed direct per ADR-079 lifecycle extension (bypasses Verifying when no fix is released in this commit; ADR-079 is unratified-proposed but same-session-pinned across 5 closures this week — flagged for upcoming `/wr-architect:review-decisions` drain per architect verdict). Upstream issue https://github.com/windyroad/agent-plugins/issues/59 should be closed with the same resolution body. Reversible via `/wr-itil:transition-problem 224 known-error`.

## Description

The risk-scorer agent produces correct risk reports (saved to `.risk-reports/`) but does not write the numeric score to the gate files (`/tmp/risk-commit-{SESSION_ID}`, `/tmp/risk-push-{SESSION_ID}`, `/tmp/risk-release-{SESSION_ID}`). The hooks pre-create these files with the placeholder; the agent's score never lands.

## Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Extend the agent's emit-shape to write numeric scores back to gate files OR have the PostToolUse mark-reviewed hook parse the agent's score block and write it.

## Related

- **Reported Upstream**: https://github.com/windyroad/agent-plugins/issues/59
- **Pipeline classification**: safe-low-fix-risk; route=safe-and-valid.
- **Affected plugin**: @windyroad/risk-scorer.
