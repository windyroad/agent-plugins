# Problem 214: work-problems Step 5 exit-code rule does not handle is_error:true transient API failures (529 Overloaded)

**Status**: Verification Pending
**Reported**: 2026-05-15
**Fix Released**: pending @windyroad/itil patch release (changeset `.changeset/p214-step-5-is-error-transient-halt.md`)
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Description

`work-problems` SKILL.md Step 5 says "Non-zero exit → halt the loop" but does not cover `claude -p` returning exit 0 with `is_error: true, total_cost_usd: 0` on transient API failures (e.g. 529 Overloaded). Without an orchestrator-side `is_error` check, the loop silently treats the failure as success and tries to parse a missing ITERATION_SUMMARY block. Iteration counts get corrupted; the loop may continue dispatching subprocesses that all fail the same way.

## Workaround

Manually halt the loop on observation. AFK promise broken — the loop runs through API failures without surfacing.

## Impact Assessment

- **Severity**: High — silent failure corrupts AFK loop state; transient errors compound.

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Extend Step 5 exit-code rule: orchestrator parses `is_error` from the `claude -p --output-format json` stdout. If `is_error: true`, halt the loop with the transient-error advisory (rate-limit / overload / auth-expired). (Phase 1 — landed via SKILL.md Step 5 ordered-check amendment + ADR-032 P214 class-taxonomy extension; commit pending.)
- [ ] Phase 2 — add a retry policy for known-transient classes (529 Overloaded → exponential backoff, max 3 retries; 401 auth-expired → halt-with-prompt). Deferred to a separate iter per the narrow-scope P214 Phase 1 split.
- [x] Behavioural test asserting is_error:true detected + appropriate routing. (Phase 1 — `packages/itil/skills/work-problems/test/work-problems-step-5-is-error-transient-halt.bats`, 11 cases / 6 behavioural + 5 doc-lint.)

## Resolution (Phase 1 — Verifying)

**Fix Strategy**: P261's `is_error: true` carve-out already routed `is_error: true` + nothing-staged to HALT via its ELSE branch, but the prose framed `is_error: true` as the stream-timeout class only and the check-order (exit-code → `is_error` → `ITERATION_SUMMARY`) was left implicit. P214 Phase 1 makes both EXPLICIT and adds a class-appropriate advisory string for the transient-API-error HALT path. No retry policy in Phase 1 — Phase 2 will add exponential backoff per the deferred Investigation Task above.

**Artefacts**:
- `packages/itil/skills/work-problems/SKILL.md` Step 5 exit-code semantics — ordered check (3 numbered steps) + `is_error: true` class taxonomy (SALVAGE = stream-timeout per P261; HALT = transient-API-error per P214) + class-substring-matched advisory map (529 → overloaded; 429 → rate-limited; 401 → auth-expired; else → generic).
- `docs/decisions/032-governance-skill-invocation-patterns.proposed.md` § P261 amendment — extended with the P214 class-taxonomy note + cross-references to the HALT-branch fixture.
- `packages/itil/skills/work-problems/test/work-problems-step-5-is-error-transient-halt.bats` — 11 cases (6 behavioural: 3 transient classes + ordered-check invariant + non-zero-exit precedence + SALVAGE-branch deferral; 5 doc-lint structural per ADR-052 Permitted Exception).
- `.changeset/p214-step-5-is-error-transient-halt.md` — @windyroad/itil patch.

**Verification path**: existing P261 stream-timeout-salvage fixture stays 13/13 green (no regression on the SALVAGE branch). New P214 fixture 11/11 green. After the next `@windyroad/itil` release lands, observe a subsequent AFK loop iter that hits a 529 Overloaded / 429 / 401 to confirm the orchestrator halts with the advisory rather than silently parsing missing `ITERATION_SUMMARY`. Auto-close per ADR-079 when a witnessing iter is observed.

## Related

- **Reported Upstream**: https://github.com/windyroad/agent-plugins/issues/81
- **Pipeline classification**: JTBD-aligned (JTBD-006); safe-low-fix-risk; route=safe-and-valid.
- **Affected plugin**: @windyroad/itil.
- **Sibling**: P261 (`is_error: true` stream-timeout SALVAGE carve-out — the SALVAGE branch this HALT branch sits beside in the class taxonomy).
