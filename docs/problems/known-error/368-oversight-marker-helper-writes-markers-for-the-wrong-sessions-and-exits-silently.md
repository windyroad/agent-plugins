# Problem 368: The oversight-marker helper writes markers for the wrong sessions and exits silently

**Status**: Known Error (auto-transitioned 2026-08-24 review — the ticket declares "Root cause identified 2026-06-17" with the `find` invocation named as the mechanism, and documents three workarounds; only the fix is outstanding)
**Reported**: 2026-06-17
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4 — **re-rated 2026-08-21 at the reopen**. The 2026-07-02 rating (9, Impact 3 × Likelihood 3, "one-line env fix") scoped only the cold path. Impact 3: the unguarded write loop hands every in-window session a standing pass to write `human-oversight: confirmed` on the artefact, which inverts the control ADR-110 exists to provide — a governance-integrity failure, not a friction one. Likelihood 4: no control on the warm path, adopter-observed 2026-08-12, and reproduced here at 3310 markers across 3099 session ids.
**Origin**: inbound-reported (adopter-repo P212)
**Effort**: M. WSJF = (12 × 1.0) / 2 = 6 — status multiplier is 1.0 at Open, not the 2.0 a Known Error carries. Re-rated 2026-08-21: the cold-path fix was S; the warm path needs a caller-resolution change plus the spray fix, and both touch the discipline hook's contract.
**WSJF**: 12 — (12 × 2.0) / 2 (re-rated 2026-08-24 review: Known Error multiplier 2.0 replaces the Open 1.0 on auto-transition; Severity and Effort unchanged)
**JTBD**: JTBD-001, JTBD-006
**Persona**: plugin-developer

## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-033 | STORY-033: Loud cold-path diagnostic for oversight-marker shims | draft |

## Fix Released — COLD PATH ONLY; does NOT close this ticket

- **Released**: 2026-07-03 in `@windyroad/architect@0.18.4` (+ `@windyroad/jtbd`)
- **Fix**: loud cold-path diagnostic for the oversight-marker shims — the shim now surfaces a clear diagnostic when it cannot discover the session-id (`CLAUDE_SESSION_ID` empty AND no announce markers) instead of silently no-opping (commit aa21ca10).
- Awaiting user verification.

## Description

`wr-architect-mark-oversight-confirmed` cannot write the oversight evidence marker when `CLAUDE_SESSION_ID` is unset AND no recent announce markers from the current session exist in `/tmp`.

Witnessed 2026-06-17 in the `/wr-architect:review-decisions` drain: the ADR-082 amendment from `human-oversight: unconfirmed` to `confirmed` was blocked by the `architect-oversight-marker-discipline.sh` PreToolUse hook because the helper script's candidate-SID enumeration returned empty. No announce markers from this session were present in `/tmp` (only prior-session UUIDs), and `$CLAUDE_SESSION_ID` was empty in the bash subshell context. The hook reads the live SID from its stdin JSON (Claude Code injects it) but the helper script cannot independently discover it.

**Workaround**: land amendment from an external terminal (per `feedback_land_gate_blocked_commit_externally.md` memory) OR wait for a fresh session whose SessionStart hooks fire announce markers in `/tmp`.

**Real fix locus**: `wr-architect-mark-oversight-confirmed` should either:
- (a) accept the SID via stdin/env passed by the calling skill (the skill knows its own context better than the helper can discover it),
- (b) fail loudly when no candidate SID can be discovered (currently exits 0 silently — the hook then denies with a directive that points back at the helper, creating a confusing loop), OR
- (c) the hook side should accept marker files under broader naming conventions (e.g. a session-agnostic marker keyed on path hash only, with the SID-binding moved to a different protection mechanism).

Sibling-class to P260 / ADR-050 Option C candidate-SID enumeration — same root cause (session-marker discoverability gap when SessionStart hooks haven't fired in the current Claude Code session).

## Reopened 2026-08-21 — the shipped fix guards only the cold path, and the warm path is worse

> **Status is Open, not Known Error, and that is the substantive call.** ADR-022 defines Known Error as root cause identified AND workaround documented. That held for the cold path. It does not hold for the warm path this reopen is about: the candidate fixes below are candidates, not a confirmed mechanism, and no workaround exists that does not defeat the control. Open is the honest state.
>
> It also takes the ticket out of the post-release K→V enumerator's line of fire — that enumerator globs `known-error/*.md` only. **The underlying defect is not fixed by this**: any Known Error reopened after its fix shipped is still auto-transitioned back to Verification Pending, because the body-grep is bypassed by the co-commit fallback that re-derives the changeset from git history. That guard is P512's task and adopters remain exposed until it lands.
>
> **Post-release K→V enumerator: SKIP this ticket.** It was reopened 2026-08-21, after the changeset cited below shipped. A released changeset in this body is history, not a pending verification. Auto-transitioning it back to Verification Pending would undo the reopen, zero its WSJF multiplier under ADR-022, and drop the warm-path control defeat out of the dev-work queue — with no supported route back, per P512.

**Adopter-reported, and independently reproduced here.** An adopter ticket ("Oversight-marker helper writes markers for the wrong sessions and exits silently", reported 2026-08-12) states the gap precisely: this is the loop P368 documents, but P368's fix guards only the zero-candidate cold path — the diagnostic sits inside the empty-candidates branch, so a non-empty-but-wrong candidate set stays silent and reads as success.

Verified against `packages/architect/scripts/mark-oversight-confirmed.sh` rather than accepted: the diagnostic block is at line 107 inside `if [ -z "$candidates" ]`, and the write loop at line 120 runs unguarded over whatever the glob returned. The source comment at line 100 claims the fix "replaces the prior SILENT no-op" — true for the cold path only.

**Their reproduction.** A session whose newest announce marker was 30 hours old, while 99 other sessions' markers were in-window. The helper wrote 99 markers for other sessions, none for the caller, exited 0, printed nothing. The subsequent `human-oversight: confirmed` Edit was then denied by `architect-oversight-marker-discipline`, whose deny text instructs the caller to run the shim that had just silently failed. Announce-marker mtime is never refreshed, so **any session outliving `SESSION_CANDIDATE_WINDOW_MINS` (default 1440) becomes invisible to its own tooling.**

### The warm path is a control defeat, not just a deadlock

Measured on this machine 2026-08-21:

```
/tmp oversight-confirmed-* markers:        3310
distinct session ids holding a marker:     3099
announce markers currently in-window:        62
```

The write loop is unconditional, so **every invocation writes one marker per in-window session** — about 62 on this machine right now. The marker is keyed `oversight-confirmed-<path-sha>-<sid>`, and the discipline hook admits a `confirmed` Edit when a marker exists for *its* session and that artefact. So a single legitimate ratification hands ~62 unrelated sessions a standing pass to write `human-oversight: confirmed` on that artefact, with no human having answered anything in any of them.

That inverts the control's purpose. ADR-110 exists so a ratification marker can only be written when someone actually ratified; this sprays the evidence across every session that happened to be alive. The deadlock the adopter hit is the visible half; the silent grant is the half nobody sees.

**Three markers were written from this session today** (ADR-119, JTBD-008, JTBD-009) via the explicit-`CLAUDE_SESSION_ID` fast path, which is why they succeeded — the env branch adds the true SID to the candidate list but does **not** suppress the glob, so those three calls also sprayed. The fast path masks the deadlock without fixing the spray.

### What this means for this ticket's status

The fix released for the cold path is real and stands. It does not close the defect. Moving back from Verification Pending to Known Error: closing on the released fix would have recorded a defect as verified while its dominant path is untouched — and the adopter's ticket, open since 2026-08-12, is the standing evidence.

### Candidate fixes, cheapest first (from the adopter's ticket, plus the spray)

1. **Refresh the announce marker's mtime on every hook fire**, so a live session never ages out of its own window. Smallest change; fixes the root cause of the deadlock.
2. **Have the discipline hook pass the true session id to the shim** — it already reads it from its own stdin payload, so the shim need not guess.
3. **Stop the spray regardless of 1 and 2**: write the marker for the resolved caller only, and make a non-empty-but-caller-absent candidate set a loud stderr diagnostic rather than a silent success. This is the half the adopter's ticket surfaces and the half that matters for ADR-110.

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
- [x] Audit sibling helpers + hooks for the same `find /tmp -name` pattern — done by **P380** (3 sites swept: architect + jtbd mark-oversight shims + itil session-id.sh).
- [x] Apply fix (d) or (e) — the macOS-symlink half shipped via **P380** (option (e) `find -L`, released 2026-06-27). This ticket's residuum is P368 option (b): the genuine cold path (no candidate SID at all) still exited 0 silently, producing the confusing deny loop. Applied 2026-07-03 — both `mark-oversight-confirmed.sh` shims now emit a loud stderr diagnostic on the cold path (exit stays 0). Vehicle: **RFC-038** / **STORY-033**.
- [x] Create reproduction test — symlink fixture shipped with P380; cold-path diagnostic bats added 2026-07-03 to `architect-oversight-marker-discipline.bats` + `jtbd-oversight-marker-discipline.bats` (RED→GREEN).
- [x] Decide whether a/b/c options stay in scope — option (b) implemented this iter; options (a) caller-supplies-SID and (c) session-agnostic marker closed out of scope (YAGNI — the failure mode is closed by (e)+(b); no witnessed need for the larger re-architecture). Recorded in RFC-038 § Scope "Out of scope".

## Fix Committed — superseded 2026-08-21; the named changeset shipped and no longer exists

Fix committed 2026-07-03 via **RFC-038** / **STORY-033** — both `mark-oversight-confirmed.sh` shims emit a loud stderr diagnostic on the no-candidate cold path instead of a silent `exit 0`, so the follow-on oversight-marker-discipline hook deny is self-explanatory. Exit code preserved (0). Behavioural cold-path bats added to both discipline suites (RED→GREEN; 14/14 architect, 12/12 jtbd, no regressions).

**Release vehicle** (cold path only): changeset `p368-oversight-shim-cold-path-diagnostic`, released 2026-07-03 (patch bump @windyroad/architect + @windyroad/jtbd). Stays Known Error until the changeset releases; the work-problems post-release Known Error → Verifying enumerator moves it (P380 precedent — release cadence owned by the orchestrator, not this iter).

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

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-038 | proposed | Loud cold-path diagnostic for oversight-marker shims when no session-id is discoverable |

