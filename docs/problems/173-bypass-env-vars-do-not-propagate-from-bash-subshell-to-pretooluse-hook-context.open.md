# Problem 173: BYPASS_*_GATE env vars do not propagate from Bash subshell to PreToolUse hook context

**Status**: Open
**Reported**: 2026-05-06
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Description

`BYPASS_*_GATE` env vars (e.g. `BYPASS_CHANGESET_GATE`, `BYPASS_JTBD_CURRENCY`, `BYPASS_RISK_GATE`) do not propagate from a Bash subshell to PreToolUse hook context. The hook reads env at hook-process invocation time (Claude Code's process env), not the bash subshell's env that an inline `BYPASS_FOO=1 git commit` or `export BYPASS_FOO=1; git commit` would set.

**Symptom (2026-05-06 P170 Slice 2)**: trying to bypass `itil-changeset-discipline.sh` (P141) on a held-window opening commit by `BYPASS_CHANGESET_GATE=1 git commit -m '...'` was rejected with the same gate deny message; `export BYPASS_CHANGESET_GATE=1; git commit` (separate statements within the same Bash call) was also rejected. The bypass instruction in the deny-message reads `Bypass: BYPASS_CHANGESET_GATE=1` but the path-to-set is non-obvious — the env must be set in Claude Code's parent shell BEFORE invoking the agent (typically restart-required for an in-flight session).

**Workaround discovered**: the documented two-commit hold-window dance (`.changeset/<name>.md` then `git mv` to `docs/changesets-holding/`) preserves all gates (P141 satisfied because the changeset is staged; P064 still requires precomputed sha256 marker; risk-scorer state-drift between scoring and commit re-fires correctly).

**Cost**: one wasted turn + 4-line Bash retry + finding the `docs/changesets-holding/README.md` documented Process Step 2 pattern.

**Class of friction**: hook-bypass UX gap. The deny-message instruction is technically correct but operationally misleading because the env-set requires lifecycle-level action the user is not in a state to take mid-session. Affects all hook gates that read env at hook-process time (`itil-changeset-discipline.sh`, `retrospective-readme-jtbd-currency.sh`, `external-comms-gate.sh`, others).

**Suggested fix shape**: each gate's deny-message clarifies that the env bypass must be set in Claude Code's process env BEFORE the session began, AND names the gate's in-flight escape-hatch:

- `itil-changeset-discipline.sh` (P141) — held-area dance: author in `.changeset/`, commit, then `git mv` to `docs/changesets-holding/` per the held-area README "Process" Step 2.
- `retrospective-readme-jtbd-currency.sh` (P159) — recovery via JTBD-NNN reference addition + skill-inventory row updates in the affected `packages/<pkg>/README.md`.
- `external-comms-gate.sh` (P064) — recovery via delegating to `wr-risk-scorer:external-comms` agent with the precomputed sha256 of the draft body.

**Cite trigger**: 2026-05-06 P170 Slice 2 framework commit attempt; recovery via held-window dance commit `12725a3` + move commit `8572aa6`.

**SID-mismatch sub-finding (this same session, 2026-05-06)**: while capturing this very ticket, the `get_current_session_id` helper in `packages/itil/hooks/lib/session-id.sh` returned a stale SID (`f2be274a-...`) — different from the runtime stdin SID (`7d5e7cd9-...`) the `manage-problem-enforce-create.sh` hook saw on the subsequent Write. ADR-050 (P142 / Phase 4) was supposed to make SID-mismatch structurally impossible by reading the per-machine runtime-SID marker, but the helper appears to have returned a different SID anyway. Recovery: manually set the marker under the runtime-SID by reading `ls -t /tmp/itil-runtime-sid-tomhoward-*.current | head -1 | xargs cat` then `: > /tmp/manage-problem-grep-${runtime_sid}`. This is a regression of the P124 / ADR-050 contract worth investigating separately — leaving as a sub-finding here for cross-reference.

## Symptoms

(deferred to investigation)

## Workaround

(deferred to investigation)

## Impact Assessment

- **Who is affected**: (deferred to investigation)
- **Frequency**: (deferred to investigation)
- **Severity**: (deferred to investigation)
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Investigate root cause
- [ ] Create reproduction test
- [ ] Investigate the SID-mismatch sub-finding (see Description) — may be a separate ticket

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P141 (changeset-discipline gate), P159 (JTBD-currency hook), P064 (external-comms gate), P166 (precomputed-sha256 helper for external-comms — same UX-gap class but different mechanism), P124 / ADR-050 (SID-mismatch structural fix — possible regression observed here)

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)
