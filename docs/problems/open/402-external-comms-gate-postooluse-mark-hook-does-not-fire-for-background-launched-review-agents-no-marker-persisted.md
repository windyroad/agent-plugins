# Problem 402: external-comms gate — PostToolUse mark hook does not fire for background-launched (forced-async) review agents, so no marker is persisted to the live session dir despite PASS

**Status**: Open
**Reported**: 2026-07-01
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4 (Likely) = 12. **Rated at capture from in-session evidence (5/5 PASS, 0 markers), NOT deferred** — re-rating "at next /wr-itil:review-problems" would itself be the P375 bug (nothing self-fires review-problems). Impact 3: blocks every external-facing commit and forces habitual `BYPASS_RISK_GATE=1`, eroding a load-bearing leak gate (workaround exists). Likelihood 4: reproduces on every background-launched review this session.
**Origin**: internal
**Effort**: M — single-package fix to the external-comms mark-hook persistence path (a foreground/sync review path the PostToolUse hook can observe, OR a bounded multi-SID marker write per P260 Option-C). WSJF = (12 × 1.0) / 2 = 6.0.
**JTBD**: JTBD-001
**Persona**: developer

## Description

Confirmed broken (in-session evidence, 2026-07-01): **5 reviewer PASS verdicts in one session, zero markers written to the live session dir.** The external-comms leak-review gate keeps denying the commit even though the leak review genuinely passed every time.

Root cause as observed: **the PostToolUse mark hook isn't firing for background-launched review agents in this session.** Every legitimate mechanism that should persist the gate marker was tried and none worked, because each one is forced async (the review agent runs in the background and its PostToolUse mark hook either never fires in the parent's session context, or writes the marker under the background agent's own session dir rather than the live one):

1. **Direct `Agent` dispatch** of the leak-review agent — forced async; no marker persisted.
2. **Precomputed-key Option-2** path (the `compute_external_comms_key` / precomputed-SHA256 helper route, cf. P166/P198) — forced async; no marker persisted.
3. **Foreground skill-wrapper path** (`/wr-risk-scorer:external-comms` / `/wr-risk-scorer:assess-external-comms`) — also forced async; no marker persisted.

Net effect: the leak review passes (5/5 PASS), but the gate cannot see a marker, so it continues to deny. The only escape is `BYPASS_RISK_GATE=1` after a legitimate PASS — re-introducing the exact friction tax P353 was meant to retire.

## Symptoms

- Reviewer agent returns PASS; `/tmp/<external-comms-marker>-<LIVE_SESSION_ID>` (and its `.hash` sibling) absent in the live session dir.
- Probe (in-session): "risk marker for today's key? === ABSENT; any marker modified today? === (none)".
- Gate keeps issuing `permissionDecision: "deny"` on the commit despite repeated genuine PASS verdicts.
- All three persist mechanisms forced async; none write to the live session dir.

## Workaround

`BYPASS_RISK_GATE=1` after a legitimate PASS verdict (documented escape; the precise friction P353 aimed to remove). Confirm the PASS in the reviewer output before bypassing.

## Impact Assessment

- **Who is affected**: (deferred to investigation)
- **Frequency**: (deferred to investigation)
- **Severity**: (deferred to investigation)
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [ ] Confirm whether background/forced-async `Agent` dispatch fires the PostToolUse mark hook at all, and if so, under which session_id (background-agent SID vs parent live SID) the marker lands.
- [ ] Determine whether the fix is (a) a foreground/synchronous review path the mark hook can observe, or (b) a multi-SID marker-write (cf. P260 Option-C bounded multi-UUID write) so the marker lands under the live session's SID regardless of which context fired the hook.
- [ ] Create reproduction test

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P353, P111, P260

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)

- **P353** (`docs/problems/verifying/353-...md`) — external-comms hash-marker brittleness umbrella, *Fix Released / Verifying*. Its closed root cause was the *atomic verdict-write* helper (`_atomic_mark_with_hash`) — addresses "marker doesn't land because the write wasn't atomic". This ticket is a **distinct mechanism**: the mark hook **does not fire / lands under the wrong session dir** for background-launched (forced-async) review agents, so the atomic-write fix never executes in the live session. This evidence **contradicts P353's verification target** ("the next 3-filing AFK session should fire with 0 `BYPASS_RISK_GATE=1` uses") — surface at P353's Verifying → Closed gate.
- **P111** (`docs/problems/verifying/111-...md`) — subprocess tool calls do not *refresh* parent gate markers; its slide helper **explicitly never creates a marker**. So P111's fix does not cover the create/persist gap this ticket reports.
- **P260** (`docs/problems/verifying/260-...md`) — create-gate (`manage-problem-grep`) marker race between concurrent sessions via shared runtime-sid; Option-C bounded multi-UUID marker-write is a candidate fix shape for the "marker lands under wrong SID" facet here.
- **P166 / P198** — precomputed-key / `compute_external_comms_key` reviewer-agent double-invocation + no-shasum facets; the "precomputed-key Option-2" path named in the description above.
- **P276** — external-comms gate marker over-fires on PASS-class content edits (sibling marker-friction).
