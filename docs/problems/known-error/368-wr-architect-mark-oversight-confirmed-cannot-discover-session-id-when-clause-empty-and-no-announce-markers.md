# Problem 368: wr-architect-mark-oversight-confirmed cannot discover session-id when CLAUDE_SESSION_ID empty AND no announce markers

**Status**: Known Error
**Reported**: 2026-06-17
**Priority**: 9 (Medium) — Impact: 3 × Likelihood: 3 = 9. Rated at review 2026-07-02: shim needs SID passthrough; one-line env fix.
**Origin**: internal
**Effort**: S. WSJF = (9 × 1.0) / 1 = 4.5.
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

### Root cause identified 2026-06-17 (retro on the same-day session)

**The actual root cause is NOT "no announce markers exist" — announce markers DO exist on disk; the helper script's `find` invocation cannot see them on macOS.**

Investigation evidence from the 2026-06-17 retro session:

1. `mark-oversight-confirmed.sh` enumerates candidate session IDs via:
   ```bash
   find "$MARKER_DIR" -maxdepth 1 -name '*-announced-*' -mmin "-${WINDOW_MINS}"
   ```
   where `MARKER_DIR=/tmp` (default).

2. On macOS, `/tmp` is a symlink to `private/tmp`:
   ```bash
   $ ls -la /tmp
   lrwxr-xr-x 1 root 11 Feb  5 16:13 /tmp -> private/tmp
   ```

3. `find /tmp -maxdepth 1 -name 'PATTERN'` (without trailing slash) does NOT traverse the symlink and returns ZERO results, even when matching files clearly exist:
   ```bash
   $ find /tmp -maxdepth 1 -name 'architect-announced-*'
   # (empty)
   $ ls /tmp/architect-announced-* | head -3
   /tmp/architect-announced-112badc1-875f-411f-92eb-0e0bd6eb7b52
   /tmp/architect-announced-ca5a4c11-a0ed-4c48-9212-9de60c063641
   $ find /tmp/ -maxdepth 1 -name 'architect-announced-*'  # trailing slash
   /tmp/architect-announced-e79c229a-8397-4ad7-936c-e82418a5ae38
   ...
   ```

4. Workaround that succeeded in the 2026-06-17 retro session: invoke the helper with `SESSION_MARKER_DIR=/tmp/` (trailing slash):
   ```bash
   SESSION_MARKER_DIR=/tmp/ wr-architect-mark-oversight-confirmed docs/decisions/082-...proposed.md
   ```
   This wrote 60 markers across all candidate session IDs the helper enumerated. The subsequent Edit succeeded.

**Real fix locus narrowed:** revise the helper's `find` invocation to be macOS-symlink-safe. Two viable changes (sibling fix options to the original a/b/c above):

- (d) Use trailing-slash form unconditionally: `find "${MARKER_DIR%/}/" -maxdepth 1 -name ...`.
- (e) Use `-L` (follow-symlinks) on the find invocation: `find -L "$MARKER_DIR" -maxdepth 1 -name ...`.

The hook side (`architect-oversight-marker-discipline.sh`) writes to `${SESSION_MARKER_DIR:-/tmp}/oversight-confirmed-...` — that write goes THROUGH the symlink fine via shell open(2) semantics, so only the helper's discovery path needs the symlink-safe form.

**Class generalisation:** this is a portable-shell hygiene issue any helper using `find /tmp -name ...` faces on macOS. Sibling helpers + hooks doing similar enumeration likely carry the same bug. Recommend a grep audit:
```bash
grep -rn 'find /tmp ' packages/*/scripts/ packages/*/hooks/ 2>/dev/null
grep -rn 'find "$MARKER_DIR"' packages/*/scripts/ packages/*/hooks/ 2>/dev/null
```

The original a/b/c options (caller-supplies-SID / fail-loudly-on-empty / session-agnostic-marker) remain valid design-improvement axes but are now optional — option (d) or (e) closes the immediate failure mode with a single-line change.

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Investigate root cause: confirmed 2026-06-17 in retro session — macOS /tmp symlink + find-without-trailing-slash; announce markers DO exist; find cannot see them.
- [ ] Audit sibling helpers + hooks for the same `find /tmp -name` pattern via the grep above.
- [ ] Apply fix (d) or (e) — single-line change, no architectural decision needed.
- [ ] Create reproduction test: bats fixture asserting `mark-oversight-confirmed` writes markers when announce markers exist under a `/tmp` symlink (use a temp-dir symlink-fixture instead of the real `/tmp`).
- [ ] Decide whether the original a/b/c options stay in scope for separate tickets or close as resolved-by (d)/(e).

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
