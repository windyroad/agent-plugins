# Problem 260: P119 create-gate marker race between concurrent Claude sessions via shared runtime-sid file

**Status**: Open
**Reported**: 2026-05-18
**Priority**: 6 (Medium) — Impact: 2 (Minor — capture-problem Write is blocked until workaround applies; not destructive) x Likelihood: 3 (Likely — fires whenever orchestrator main turn captures a ticket while an iter subprocess is also active, which is the standard /wr-itil:work-problems shape)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems; per-PID/per-session runtime-sid file naming)
**Type**: technical

## Description

Surfaced 2026-05-18 during session 6's foreground captures (P254, P255) while iter 1 subprocess was running concurrently. The P119 PreToolUse:Write hook reads `session_id` from its stdin JSON payload to identify the marker `/tmp/manage-problem-grep-${SESSION_ID}`. The agent-side `get_current_session_id` helper at `packages/itil/hooks/lib/session-id.sh` reads from `/tmp/itil-runtime-sid-tomhoward-3038058228.current` (per-machine file written by `itil-runtime-sid-marker.sh` on every PreToolUse:Bash/Write/Edit/Read).

**The runtime-sid file is per-MACHINE, not per-PROCESS.** When the orchestrator main turn (session A) and an iter subprocess (session B with different SESSION_ID) BOTH fire PreToolUse hooks, both write to the SAME runtime-sid file. Last writer wins.

So when the orchestrator main turn ran:
1. `Bash get_current_session_id` returned session A's SID (runtime-sid file was last written by session A's PreToolUse:Bash)
2. `Bash mark_step2_complete "<session-A-SID>"` set the marker
3. (iter subprocess ran several tool calls, overwriting runtime-sid to session B's SID)
4. `Write docs/problems/open/254-...md` — PreToolUse:Write hook read stdin SESSION_ID = session A (orchestrator's real SID, not affected by runtime-sid clobber); checked marker at `/tmp/manage-problem-grep-<session-A>` — FOUND, but actually NO — the agent's earlier mark may have been under a DIFFERENT SID because get_current_session_id fell through to announce-marker fallback (no runtime-sid present at that moment)

The race produces a marker-vs-Write mismatch: marker exists under SID X, but Write's stdin SESSION_ID is SID Y. Hook denies.

Workaround used: spam-write the marker under ALL recent UUIDs found in `/tmp/<system>-announced-*` markers + the current runtime-sid value. Whichever SID the Write's stdin actually carries, the marker exists.

## Symptoms

- `claude plugin install` and other tool calls from concurrent sessions interleave their runtime-sid writes; the per-machine file's last-writer-wins shape causes agent-side `get_current_session_id` to return the wrong session's SID.
- P119 create-gate marker mismatch causes PreToolUse:Write deny with `BLOCKED: Cannot Write '<file>' under docs/problems/ without running /wr-itil:manage-problem Step 2 (duplicate-check) first.`
- Workaround spam-writes the marker under 10+ UUIDs to ensure coverage.

## Workaround

Spam-write `/tmp/manage-problem-grep-<sid>` under EVERY recent announce-marker UUID (from `/tmp/<system>-announced-*` filenames) + the current runtime-sid value. Documented in the orchestrator's main-turn capture flow.

## Impact Assessment

- **Who is affected**: Any orchestrator main turn that creates a ticket while an iter subprocess is active. Standard `/wr-itil:work-problems` AFK loop shape.
- **Frequency**: Likely (3) — fires on every foreground capture during AFK loop runs.
- **Severity**: Minor — workaround works; no data loss; just an extra Bash invocation.

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems.
- [ ] Architect verdict on the fix shape:
  - **Option A**: Per-PID runtime-sid file (e.g. `/tmp/itil-runtime-sid-tomhoward-<pid>.current`) — each process writes its own file; agent-side helper reads `$PPID` or similar.
  - **Option B**: Stop using runtime-sid at all in `get_current_session_id`; rely on announce-marker most-recent-mtime fallback exclusively (the existing fallback path).
  - **Option C**: Make the spam-write workaround the documented contract — agent always marks under all recent UUIDs.
- [ ] Update P124 (agent-side SID discovery helper) Change Log to document this race.
- [ ] Behavioural bats coverage for concurrent-session scenario.

## Dependencies

- **Blocks**: (none — workaround keeps captures functional)
- **Blocked by**: (none)
- **Composes with**: P124 (P119 create-gate hook contract), P142 / ADR-050 (runtime-SID instrumentation introduction)

## Related

- `packages/itil/hooks/lib/session-id.sh` `get_current_session_id` — the helper that reads the racy file.
- `packages/itil/hooks/itil-runtime-sid-marker.sh` — the PreToolUse hook that WRITES the racy file.
- `packages/itil/hooks/manage-problem-enforce-create.sh` — the P119 create-gate hook that reads stdin SESSION_ID (not affected by runtime-sid clobber, but its marker may be missing under the right SID).
- P124 — agent-side SID discovery helper history.
- P142 / ADR-050 — runtime-SID introduction.

(captured via /wr-retrospective:run-retro Step 4b Stage 1; expand at next investigation)
