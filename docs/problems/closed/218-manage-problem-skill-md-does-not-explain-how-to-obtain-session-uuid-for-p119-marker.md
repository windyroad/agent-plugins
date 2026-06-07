# Problem 218: manage-problem SKILL.md doesn't explain how to obtain the actual session UUID for the P119 marker

**Status**: Closed (Superseded)
**Reported**: 2026-05-15
**Closed**: 2026-06-08 (work-problems AFK iter — superseded by P260 Option C shim + SKILL.md prose rewrite; agents no longer look up the SID directly)
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Resolution

**Closed as Superseded 2026-06-08.** Both layers of the original concern are addressed by released fixes — the underlying SID-mismatch class (P260 Option C) and the SKILL.md prose surface (now directs agents to invoke a shim that internalises SID enumeration; agents never look up the SID directly).

**Substantive fixes already shipped**:

1. **P260 — bounded multi-UUID create-gate marker-write (ADR-050 Option C)** released in **`@windyroad/itil@0.35.14`** (release commit `bf1ebdd`, 2026-05-26). The mitigation does NOT depend on the agent picking "the right" single SID — `packages/itil/hooks/lib/session-id.sh::get_candidate_session_ids` enumerates every recent candidate (the `get_current_session_id` pick PLUS every `/tmp/<system>-announced-<UUID>` UUID within a 24h mtime window) and `packages/itil/hooks/lib/create-gate.sh::mark_step2_complete_candidates` writes the `/tmp/manage-problem-grep-<SID>` marker under each. Whichever SID the hook reads from the Write's stdin, a matching marker provably exists. Behavioural-bats coverage in `packages/itil/hooks/test/session-id.bats` (6 candidate-enumeration tests) + `packages/itil/hooks/test/manage-problem-enforce-create.bats` (concurrent-session end-to-end with pre-Option-C negative control).

2. **SKILL.md Step 2 prose rewritten to invoke a shim, NOT to look up the SID** (`packages/itil/skills/manage-problem/SKILL.md` lines 373-387). The current instruction is a single command:

   ```bash
   wr-itil-mark-create-gate
   ```

   `wr-itil-mark-create-gate` is the ADR-049 PATH shim (resolves `hooks/lib` siblings relative to the script per P317/RFC-009 adopter-safe pattern) that internalises `get_candidate_session_ids | mark_step2_complete_candidates`. The original P218 symptom — "SKILL.md uses `${CLAUDE_SESSION_ID:-default}` and the agent's marker doesn't match the hook's stdin SID" — is structurally impossible against the current prose: the agent does not pick a SID at all, and the helper enumerates every candidate.

3. **P218 Investigation Task #2** (*"Update SKILL.md Step 2 prose to document the canonical SID-derivation pattern"*) is satisfied — the prose documents the shim-internalised candidate-set write, plus a "Phase 5 (P260 / ADR-050 Option C)" explanatory paragraph (SKILL.md line 387) explaining why every candidate is needed under concurrent orchestrator+subprocess load.

**Why "no further work" instead of "still pending"**: P218 (2026-05-15) pre-dates P260 (2026-05-18) by 3 days and tracked the same SID-mismatch class from the SKILL.md-prose surface. P260 surfaced the deeper structural cause (per-machine runtime-sid file last-writer-wins under concurrency) and shipped the only structurally-sound fix (Option C: stop predicting, enumerate every candidate). The SKILL.md prose change naturally fell out of Option C's implementation — the shim replaced the inline `${SESSION_ID}` snippet. No residual P218-scoped work exists that P260 + the shim do not already cover.

No code change in this transition; KE→Closed direct per ADR-079 lifecycle extension (bypasses Verifying when no fix is released in this commit). Upstream issue https://github.com/windyroad/agent-plugins/issues/77 should be closed with the same resolution body. Reversible via `/wr-itil:transition-problem 218 known-error`.

## Description

`/wr-itil:manage-problem` Step 2 tells the agent to write the per-session create-gate marker at `/tmp/manage-problem-grep-${SESSION_ID}` so the P119 PreToolUse hook allows new ticket Writes. The SKILL.md offers a portable suggestion using `${CLAUDE_SESSION_ID}` but `CLAUDE_SESSION_ID` is not exported in agent contexts today. Agents commonly use the wrong SID and the marker doesn't match what the hook checks for.

**In-session reproduction this monorepo (2026-05-15)**: same bug surfaced — the `get_current_session_id` helper returns one SID while the PreToolUse hook's JSON-stdin SID is different (runtime-marker contents). Manual dual-touch unblocked the Write. See P197 / P198 commit messages.

## Workaround

Read the runtime-marker file (`/tmp/itil-runtime-sid-<user>-<hash>.current`) for the JSON-stdin SID the hook will use, and seed the marker under THAT SID (not the helper-fast-path SID).

## Impact Assessment

- **Severity**: Moderate — every new-ticket creation in non-standard sessions can hit this; recoverable with workaround.

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Update SKILL.md Step 2 prose to document the canonical SID-derivation pattern (read runtime-marker file from `runtime-sid.sh` helper).
- [ ] Possibly unify `get_current_session_id` to ALWAYS read from runtime-marker first (already does per P142 but the helper fallback can return a different SID).
- [ ] Behavioural test asserting marker landing under the SID the hook will use.

## Related

- **Reported Upstream**: https://github.com/windyroad/agent-plugins/issues/77
- **Pipeline classification**: safe-low-fix-risk; route=safe-and-valid.
- **Affected plugin**: @windyroad/itil.
- **Sibling**: P119 (create-gate hook); P142 (runtime-sid marker); P197 + P198 (in-session reproduction).
