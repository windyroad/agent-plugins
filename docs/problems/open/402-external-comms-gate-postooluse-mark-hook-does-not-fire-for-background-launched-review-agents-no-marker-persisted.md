# Problem 402: external-comms gate — PostToolUse mark hook does not fire for background-launched (forced-async) review agents, so no marker is persisted to the live session dir despite PASS

**Status**: Open
**Reported**: 2026-07-01
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4 (Likely) = 12. **Rated at capture from in-session evidence (5/5 PASS, 0 markers), NOT deferred** — re-rating "at next /wr-itil:review-problems" would itself be the P375 bug (nothing self-fires review-problems). Impact 3: blocks every external-facing commit and forces habitual `BYPASS_RISK_GATE=1`, eroding a load-bearing leak gate (workaround exists). Likelihood 4: reproduces on every background-launched review this session.
**Origin**: internal
**Effort**: M — **fix direction corrected 2026-07-02** (see ## Corrected diagnosis): NOT a mark-hook persistence fix (the marker lands correctly under the live SID in `$TMPDIR`). Residual is the draft≠commit key mismatch (P356 class); likely re-scope/close after the one-shot end-to-end isolation test. Priority/Likelihood pending that test — the load-bearing-gate-bug framing (Impact 3 × Likelihood 4) is likely an overstatement now that the gate is shown to work when draft==commit. WSJF = (12 × 1.0) / 2 = 6.0 (to be re-rated).
**JTBD**: JTBD-001
**Persona**: developer

## Description

Confirmed broken (in-session evidence, 2026-07-01): **5 reviewer PASS verdicts in one session, zero markers written to the live session dir.** The external-comms leak-review gate keeps denying the commit even though the leak review genuinely passed every time.

Root cause as observed: **the PostToolUse mark hook isn't firing for background-launched review agents in this session.** Every legitimate mechanism that should persist the gate marker was tried and none worked, because each one is forced async (the review agent runs in the background and its PostToolUse mark hook either never fires in the parent's session context, or writes the marker under the background agent's own session dir rather than the live one):

1. **Direct `Agent` dispatch** of the leak-review agent — forced async; no marker persisted.
2. **Precomputed-key Option-2** path (the `compute_external_comms_key` / precomputed-SHA256 helper route, cf. P166/P198) — forced async; no marker persisted.
3. **Foreground skill-wrapper path** (`/wr-risk-scorer:external-comms` / `/wr-risk-scorer:assess-external-comms`) — also forced async; no marker persisted.

Net effect: the leak review passes (5/5 PASS), but the gate cannot see a marker, so it continues to deny. The only escape is `BYPASS_RISK_GATE=1` after a legitimate PASS — re-introducing the exact friction tax P353 was meant to retire.

## Corrected diagnosis (2026-07-02 — supersedes the "mark hook doesn't fire" claim above)

The original "zero markers / hook doesn't fire" evidence was a **`/tmp`-vs-`$TMPDIR` checking error**, not a hook bug. On macOS `$TMPDIR` is `/var/folders/.../T/`; both the mark hook AND the gate write/read `${TMPDIR:-/tmp}/claude-risk-<SID>/`. The Symptoms probe ("`/tmp/<external-comms-marker>-<LIVE_SESSION_ID>` absent") looked in `/tmp` — the wrong directory.

Verified 2026-07-02 in the correct location (`$TMPDIR`):

- The mark hook (`risk-score-mark.sh` external-comms branch) **DOES fire for background-launched agents** and writes `${TMPDIR}/claude-risk-<SID>/external-comms-risk-reviewed-<key>` **under the live session SID** — a real background probe this session wrote its marker under this session's own SID (`4dc555f3…`). Traced the `touch` succeeding; `_get_tool_output` correctly reads the harness `tool_response.content[].text` shape. There is **no SID mismatch and no firing failure**.
- The gate and mark hook share `lib/external-comms-key.sh`: `key = sha256(normalize(draft) + '\n' + surface)`. Keys match **iff the reviewed `<draft>` equals the commit message** the gate extracts (modulo documented frontmatter-strip / single-newline normalization).

**Real residual (NOT "hook doesn't fire", NOT multi-SID):** the gate denies when the reviewed draft ≠ the actual commit message — a **key mismatch**, the P356 class ("send the verbatim commit body incl. trailer to the reviewer"). This session's own bypass cycle was self-inflicted: reviewing draft D, then committing `D + a "BYPASS/PASS" note` → different key → deny → bypass → repeat.

**`Approach A` (bounded multi-SID marker write, named in the Effort line) is WITHDRAWN** — the marker already lands under the live SID.

### Controlled end-to-end test result (2026-07-02)

Ran the clean test: reviewed the exact commit message verbatim (single `-m`, draft byte-identical to commit incl. trailer — **key controlled**), confirmed the review returned PASS, then attempted the commit unchanged.

- [x] **Verbatim `draft == commit` review → gate STILL DENIED.** So the residual is **NOT** a key mismatch (the key was held identical) and **NOT** multi-SID.
- [x] **Root residual = PostToolUse:Agent mark firing/timing.** Checked `$TMPDIR/claude-risk-<live-SID>/` immediately after the PASS: the expected-key marker was **absent**, and no external-comms marker was written by this review within a 4-min window — yet an *earlier* review's marker (`0578761e…`) persists under the same live SID. So the mark hook **fires only sometimes / too late** for review-agent completions in this harness; when the marker hasn't landed by commit time, the gate correctly denies.
- [ ] Still open: WHY firing is inconsistent (backgrounded-agent completion not always emitting PostToolUse:Agent? a race between completion-notification and the mark hook? harness-specific). This is a **harness-interaction** question, not a plugin key/SID bug.

**Revised fix direction (supersedes Approach A entirely):** the marker mechanism (logic + SID + key) is sound; the gap is *reliable marking on review completion*. NOT a multi-SID marker write.

### ROOT CAUSE isolated (2026-07-02) — background vs synchronous agent dispatch

Mapped which past reviews actually wrote their marker (by key, in `$TMPDIR/claude-risk-<live-SID>/`):

| Review probe | Dispatch | Marker present? |
|---|---|---|
| probe1 | **background** (default `Agent`) | **ABSENT** |
| probe3 | **synchronous** (`run_in_background: false`) | **PRESENT** under the live SID |

**PostToolUse:Agent fires reliably for a SYNCHRONOUS agent and does NOT fire (in time / at all) for a background-launched one.** That is the whole bug: the external-comms reviewer is dispatched in the background by default, so its mark hook never runs before the commit → gate denies → habitual `BYPASS`. Every "no marker" symptom traces here (compounded by the original `/tmp`-vs-`$TMPDIR` mis-check).

**Fix (user-chosen option b — a reliable trigger):** dispatch the external-comms reviewer **synchronously** (`run_in_background: false`), so its PostToolUse:Agent mark hook fires in the live session and writes the marker before the commit. Enforcement surfaces: (1) the gate DENY message should instruct synchronous dispatch; (2) `/wr-risk-scorer:assess-external-comms` (+ voice-tone peer) should launch the reviewer synchronously; harness-specific but harmless where `run_in_background` is absent.

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
