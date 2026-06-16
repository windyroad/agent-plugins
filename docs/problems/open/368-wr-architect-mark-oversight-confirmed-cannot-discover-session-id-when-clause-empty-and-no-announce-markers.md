# Problem 368: wr-architect-mark-oversight-confirmed cannot discover session-id when CLAUDE_SESSION_ID empty AND no announce markers

**Status**: Open
**Reported**: 2026-06-17
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-001, JTBD-006
**Persona**: plugin-developer

## Description

`wr-architect-mark-oversight-confirmed` cannot write the oversight evidence marker when `CLAUDE_SESSION_ID` is unset AND no recent announce markers from the current session exist in `/tmp`.

Witnessed 2026-06-17 in the `/wr-architect:review-decisions` drain: the ADR-082 amendment from `human-oversight: unconfirmed` to `confirmed` was blocked by the `architect-oversight-marker-discipline.sh` PreToolUse hook because the helper script's candidate-SID enumeration returned empty. No announce markers from this session were present in `/tmp` (only prior-session UUIDs), and `$CLAUDE_SESSION_ID` was empty in the bash subshell context. The hook reads the live SID from its stdin JSON (Claude Code injects it) but the helper script cannot independently discover it.

**Workaround**: land amendment from an external terminal (per `feedback_land_gate_blocked_commit_externally.md` memory) OR wait for a fresh session whose SessionStart hooks fire announce markers in `/tmp`.

**Real fix locus**: `wr-architect-mark-oversight-confirmed` should either:
- (a) accept the SID via stdin/env passed by the calling skill (the skill knows its own context better than the helper can discover it),
- (b) fail loudly when no candidate SID can be discovered (currently exits 0 silently — the hook then denies with a directive that points back at the helper, creating a confusing loop), OR
- (c) the hook side should accept marker files under broader naming conventions (e.g. a session-agnostic marker keyed on path hash only, with the SID-binding moved to a different protection mechanism).

Sibling-class to P260 / ADR-050 Option C candidate-SID enumeration — same root cause (session-marker discoverability gap when SessionStart hooks haven't fired in the current Claude Code session).

## Symptoms

(deferred to investigation)

- The amendment Edit/Write is denied with "no substance-confirm evidence marker exists for this ADR in this session (P348 / ADR-066)".
- Running `wr-architect-mark-oversight-confirmed <path>` exits 0 with no observable file written to `/tmp/oversight-confirmed-*`.
- Retrying the Edit still denied — the marker write was a silent no-op.

## Workaround

- Land the amendment from an external terminal where the session-id can be observed.
- OR wait for a fresh Claude Code session — its SessionStart hooks fire announce markers; the helper then succeeds.
- OR override with `BYPASS_RISK_GATE=1` — but that bypasses the risk-scorer gate, not the architect-oversight-marker-discipline gate (different hook, different bypass token if any).

## Impact Assessment

- **Who is affected**: any agent attempting to confirm an ADR's substance via `/wr-architect:review-decisions` mid-session when the session has not emitted announce markers. Real-world: this exact case fired 2026-06-17 immediately after ADR-082 capture in the same session.
- **Frequency**: every session that creates AND drains ADRs in the same session. Captures normally fire announce markers; the gap is sessions where neither create-adr nor capture-adr nor any other announce-firing skill ran before review-decisions.
- **Severity**: medium — workaround exists (external terminal / fresh session) but the drain is the canonical confirm surface; this defeats it.
- **Analytics**: not measured.

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Investigate root cause: confirm the helper-script + hook contract; map where `$CLAUDE_SESSION_ID` is expected to come from (env var? stdin JSON? other?)
- [ ] Pick fix locus (a / b / c above) — direction-setting per ADR-074
- [ ] Create reproduction test: fresh-session scenario where no announce markers exist + capture/drain ADR in one turn

## Dependencies

- **Blocks**: in-session ADR confirmations via `/wr-architect:review-decisions` when announce-marker preconditions don't hold (e.g. the 2026-06-17 ADR-082 drain).
- **Blocked by**: (none — direction-setting fix shape needs user pick)
- **Composes with**: P260 (candidate-SID enumeration sibling), ADR-050 Option C, P348 (substance-confirm marker contract), feedback_land_gate_blocked_commit_externally.md (workaround precedent).

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)
- P260 — sibling-class candidate-SID enumeration
- ADR-050 — Option C multi-SID candidate writing
- P348 — substance-confirm marker contract (ADR-066 amendment)
- ADR-082 — the ADR whose drain witnessed this gap
- ADR-066 — human-oversight marker mechanism
