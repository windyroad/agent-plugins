# Problem 402: external-comms gate — PostToolUse mark hook does not fire for background-launched (forced-async) review agents, so no marker is persisted to the live session dir despite PASS

**Status**: Known Error
**Reported**: 2026-07-01
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4 (Likely) = 12. **Rated at capture from in-session evidence (5/5 PASS, 0 markers), NOT deferred** — re-rating "at next /wr-itil:review-problems" would itself be the P375 bug (nothing self-fires review-problems). Impact 3: blocks every external-facing commit and forces habitual `BYPASS_RISK_GATE=1`, eroding a load-bearing leak gate (workaround exists). Likelihood 4: reproduces on every background-launched review this session.
**Origin**: internal
**Effort**: M — **fix direction corrected 2026-07-02** (see ## Corrected diagnosis): NOT a mark-hook persistence fix (the marker lands correctly under the live SID in `$TMPDIR`). Residual is the draft≠commit key mismatch (P356 class); likely re-scope/close after the one-shot end-to-end isolation test. Priority/Likelihood pending that test — the load-bearing-gate-bug framing (Impact 3 × Likelihood 4) is likely an overstatement now that the gate is shown to work when draft==commit. WSJF = (12 × 1.0) / 2 = 6.0 (to be re-rated).
**JTBD**: JTBD-001
**Persona**: developer

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-041 | proposed | Dispatch marker-writing review agents synchronously so the mark hook fires before the gated action |

## Fix Released — SUPERSEDED by the 2026-08-20 reopen, see ## Reopened below

> This section describes a fix that did not close the failing case. It is retained verbatim as the record of what was shipped on 2026-07-03; it is **not** a current statement of this ticket's state. Lifecycle authority is the `**Status**` field, the `known-error/` directory, and the `## Reopened` section.

Fix implemented 2026-07-03 via **RFC-041** (user-chosen option b — codify synchronous dispatch of every marker-writing reviewer). The root cause is a harness-interaction limitation, not a plugin key/SID bug: the `PostToolUse:Agent` mark hook fires reliably **only** for a synchronously-dispatched review agent (`run_in_background: false`); a background-launched reviewer's mark hook does not fire in time, so no marker persists and the gate re-blocks despite a PASS/within-appetite verdict. Synchronous dispatch is the reliable trigger.

Codified at four surfaces (the `external-comms-gate.sh` DENY message already carried the instruction — shipped precedent):

1. `packages/risk-scorer/hooks/lib/risk-gate.sh` — the "No `<ACTION>` risk score found" DENY (commit/push/release marker-absent case) now instructs synchronous scorer dispatch, with behavioural coverage in `risk-gate.bats`.
2. `packages/risk-scorer/skills/pipeline/SKILL.md` — Agent-tool dispatch block sets `run_in_background: false`.
3. `packages/risk-scorer/skills/external-comms/SKILL.md` — same.
4. `packages/voice-tone/skills/assess-external-comms/SKILL.md` — same on the reviewer dispatch block.

Releases in the next `@windyroad/risk-scorer` + `@windyroad/voice-tone` version (orchestrator owns release cadence). **Awaiting user verification**: a subsequent filing/commit session should see gated commits proceed with **zero** `BYPASS_RISK_GATE` uses when the reviewer/scorer is dispatched synchronously.

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
- [ ] Re-word the gate's remediation text: `run_in_background: false` is not universally reachable (see the 2026-08-20 evidence below), so the message must name a path an agent in that harness can actually take.

### Evidence 2026-08-20 — the prescribed remediation is unreachable in some harnesses

The push gate blocked twice in one interactive session with:

> Dispatch the scorer SYNCHRONOUSLY (run_in_background: false): a background-launched scorer does not fire its PostToolUse:Agent mark hook.

The session's `Agent` tool exposed **no `run_in_background` parameter at all** — its contract is "Subagents run in the background; you'll be notified when one completes." Every `wr-risk-scorer:pipeline` dispatch therefore returned `Async agent launched successfully`, and the mark hook never fired. The session risk dir held only `state-hash` and `wip-reviewed`; no `commit`, `push`, or `release` file was ever written, exactly as this ticket describes.

Two consequences worth separating:

1. **The mechanism is confirmed** — background dispatch does not fire the mark hook, and no marker lands under any SID (the risk dir was inspected directly, not inferred). That closes the first investigation task's "if so, under which session_id" branch as moot for this harness: the hook does not fire, so there is no SID to attribute.
2. **The remediation text is a dead end where the parameter does not exist.** An agent that follows it re-dispatches, gets another background agent, and re-blocks — an unbounded loop. The scorer itself worked correctly both times (`commit=4 push=4 release=1`, then `commit=3 push=2 release=1`, both within the appetite of 5); only the marker plumbing failed. The session unblocked by hand-writing the files `risk-score-mark.sh` would have written, derived from the scorer's real verdict.

This strengthens option (b) in the second investigation task — a marker-write path that does not depend on the dispatching agent's ability to choose synchronous execution. Option (a) is not portable: it assumes a harness affordance that is not guaranteed.

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

## Session Evidence — 2026-07-03 (RFC-037 session)

Strong recurrence: ~10 changeset-bearing commits in the RFC-037/P404 session each hit this bug — the `wr-risk-scorer:external-comms` review (dispatched via a background `Agent`) returned `EXTERNAL_COMMS_RISK_VERDICT: PASS`, but the PostToolUse mark hook never fired, so both the `.changeset/*.md` Write and the follow-up `git commit` re-blocked. Every one was worked around with inline `BYPASS_RISK_GATE=1 git commit -F <msgfile>` (which reaches this commit gate) + a shell-heredoc changeset write (to sidestep the Write-tool gate). Confirms the root cause (background-launched review agent → no marker) and quantifies the cost (one BYPASS per changeset). Candidate durable fix: have the retro/commit flow prefer the synchronous `/wr-risk-scorer:assess-external-comms` skill over a background `Agent` review, OR make the mark hook fire on background-agent completion.

### Scope broadening — same bug hits the `wr-risk-scorer:pipeline` PUSH gate (2026-07-03, work-problems AFK loop)

The async-no-fire marker bug is NOT external-comms-specific — the `risk-score-mark.sh` **push** branch has the identical failure mode. In a `/wr-itil:work-problems` wrap this session, the orchestrator scored push risk by delegating to `wr-risk-scorer:pipeline` via a **background** `Agent` (returned `RISK_SCORES: commit=4 push=4 release=4`, within appetite), then ran `npm run push:watch` — which **re-blocked** with `Push blocked: No push risk score found` because the PostToolUse:Agent mark hook never wrote the `${TMPDIR}/claude-risk-<SID>/push` marker for the background agent. Re-dispatching the *same* pipeline agent **synchronously** (`run_in_background: false`) fired the mark hook, wrote a fresh `push` marker (observed under `$TMPDIR`), and push:watch then passed and pushed 9 commits CI-green. So the fix direction (prefer synchronous dispatch for any gate-marker-writing review agent) generalises across BOTH the external-comms gate and the pipeline commit/push gate — worth widening the fix scope + the DENY-message guidance to cover the pipeline gate. Compounding factor observed: `CLAUDE_SESSION_ID` was empty in the orchestrator Bash env (macOS `$TMPDIR` markers keyed on the SID), but the synchronous dispatch still resolved correctly, so async-vs-sync is the dominant variable, not the empty SID.

## Verified & Closed — SUPERSEDED, see ## Reopened below

- **Verified**: 2026-07-24 via transcript-evidence mining (/wr-itil:review-problems evidence scan across ~/.claude + ~/.codex).
- **Evidence**: synchronous external-comms reviewers -> marker persisted and gated commits proceeded with zero real BYPASS uses (BYPASS appears only as "removed" prose) (3cda89d3, 2026-07-05)
- **Recovery**: reversible via `/wr-itil:transition-problem 402 known-error` or `git revert`.

## Reopened — 2026-08-20 (Closed → Known Error)

**The 2026-07-24 verification was scoped too narrowly.** It confirmed that a *synchronously* dispatched reviewer persists its marker. That was never in doubt. It did not test the failing case — a background-launched reviewer — because RFC-041's fix did not change that case's behaviour. RFC-041 codified "dispatch synchronously" as prose at four SKILL surfaces and one DENY message; the underlying mechanism is unchanged, so the bug reproduces the moment any caller dispatches asynchronously, whether by choice or because the surrounding harness gives it no choice.

### Recurrence evidence

A 2026-08-20 sweep of ~4,200 Claude Code transcripts and ~16,100 Codex session files found the failure live **five and a half weeks after closure**. From `addressr` session `b782a61f`, 2026-08-10 — two full pipeline scores discarded on a single commit:

> Two prior runs of this exact staged set returned commit=4 push=4 release=4 &hellip; but both were launched into the background so their PostToolUse mark hook never fired and the commit gate cannot see them (P402).

The same session hand-invoked the sanctioned marker writer with the genuine verdict rather than re-running the scorer a third time. Across the sweep, **43** markers were asserted by hand after a genuine PASS — the honest measure of how often a review that really happened failed to be recorded.

### In-session reproduction — the reopen commit hit the bug it reopens

This is not transcript archaeology. The commit that carried this reopen reproduced the defect while being prepared, 2026-08-20:

1. The staged 5-file docs change was scored by dispatching `wr-risk-scorer:pipeline` via the Agent tool.
2. The scorer returned a complete Pipeline Risk Report — `RISK_SCORES: commit=4 push=4 release=1` against an appetite of 5, comfortably within appetite, with no remediations.
3. `${TMPDIR}/claude-risk-<this-session-SID>/` afterwards contained `state-hash` and `wip-reviewed` and **no `commit` marker**. The verdict existed; the gate could not see it.

The dispatching session had **no `run_in_background` parameter on its Agent tool at all** — every Agent call in that surface is asynchronous by construction. This is the point RFC-041's prose fix cannot reach: the caller did not choose the async path and had no synchronous path to choose. The instruction "dispatch the scorer SYNCHRONOUSLY (`run_in_background: false`)" in `risk-gate.sh` names a parameter that does not exist on every calling surface.

Recovery used: invoke the sanctioned marker writer directly with the scorer's genuine verdict — triggering a hook that did not fire, not fabricating its output. This is the same recovery the 2026-07-03 and 2026-08-10 sessions used, and it is why the hand-asserted-marker count is the honest measure of this bug's frequency.

#### The title's "does not fire" is NOT established — treat the mechanism as open

This ticket's title, and its 2026-07-01 description, both assert the hook *does not fire*. The 2026-08-20 reproduction turned up evidence that does not fit that claim, and it is recorded here rather than smoothed over.

`.risk-reports/` contains two files dated the same day as the two async scorer runs above, `2026-08-20T03-40-51-commit.md` and `2026-08-20T03-45-53-commit.md`, each **1 byte** — a bare newline. The only writer of that path is `risk-score-mark.sh`, at a point **after** its own guard:

```bash
SCORES_LINE=$(echo "$AGENT_OUTPUT" | grep -E '^RISK_SCORES:' | tail -1) || true
[ -n "$SCORES_LINE" ] || exit 1
...
echo "$AGENT_OUTPUT" > "$REPORT_PATH"   # ~50 lines later
```

An empty `$AGENT_OUTPUT` cannot satisfy that guard, so the guard should make an empty report unreachable. Two exist anyway. Either the hook ran with an output that passed the guard and was then lost before the report write, or those two files came from some path not yet identified. Their provenance is **not** conclusively tied to this session — the timestamps match, nothing stronger.

Note also that `state-hash` was present in this session's risk dir. That is *not* evidence the pipeline branch ran: `risk-hash-refresh.sh:21` writes the same file from a different hook.

**Consequence for whoever fixes this**: do not start from "the hook never fires". Establish first whether the hook fires with an empty payload, fires and dies between the report write and the marker writes, or genuinely never runs — the three have different fixes, and the evidence above is consistent with more than one.

- [ ] Instrument `risk-score-mark.sh` to record invocation, `$SUBAGENT`, and `$AGENT_OUTPUT` length on every entry, then reproduce with a background-launched scorer and read the trace
- [ ] Establish the provenance of the two 1-byte `.risk-reports/` files, and whether an empty report can be produced through the guarded path at all

### Why prose could not have fixed this

A documentation fix depends on every future caller reading it and having the choice. Neither holds:

1. **The instruction is not always reachable.** RFC-041 put the directive in SKILL bodies and a DENY message. A caller that dispatches a reviewer before hitting the DENY — the normal order — does not see it.
2. **The caller does not always have the choice.** In the session that captured this reopen, every `Agent` dispatch was forced asynchronous by the harness, with no `run_in_background` parameter exposed on the tool. Under that surface, "dispatch synchronously" is not advice a caller can follow.

### Verification condition (replaces the 2026-07-24 one)

The old condition — "a subsequent filing session should see gated commits proceed with zero `BYPASS_RISK_GATE` uses when the scorer is dispatched synchronously" — is unfalsifiable: it presupposes the synchronous path. Replace it with a test of the failing case:

- [ ] A **background-launched** marker-writing reviewer that returns a passing verdict results in a persisted marker, OR the gate surfaces an actionable diagnosis rather than a bare "no score found".

### Fix direction

Move the marker write off the transport side effect. The mark hook fires on `PostToolUse:Agent`, so its firing is a property of *how the reviewer was dispatched* rather than of *what the reviewer concluded*. Candidate shapes, in ascending order of cost:

- Fire the mark on an event that is emitted regardless of dispatch mode (`SubagentStop` is the natural candidate — but see P477, where the Codex path shows that event arriving without the parent's spawn state).
- Have the reviewer itself write its verdict to a file the gate reads, so persistence does not depend on any hook firing (P469 records that two reviewers currently lack the `Bash` tool this would need).
- Keep the hook, but make the gate's DENY name the async-dispatch cause explicitly when a recent verdict exists with no marker, so the caller diagnoses it in one step instead of re-scoring.

### Also correct: a diagnosis to not build on

A Codex session (`019f7561`, recurring 2026-07-18 to 2026-08-17) hitting the sibling failure concluded the hook expects `risk-scorer.pipeline` while Codex records `wr-risk-scorer:pipeline`. **That diagnosis is wrong.** `packages/risk-scorer/hooks/risk-score-mark.sh` line 39 matches with `grep -qE 'risk-scorer.pipeline'`, where `.` is a regex wildcard that matches the colon. The subagent identity is not the failure; the missing parent event is, which is what P477 already records.

### Related tickets from the same sweep

- **P502** — the marker shim's 24h candidate-SID window excludes long sessions, so it silently writes nothing.
- **P503** — edit gates bound to the `Edit|Write` matcher, so Bash-routed writes pass ungated and leave a stale hash.
- **P468**, **P418**, **P477** — the other three live paths by which a genuine PASS fails to produce a marker.
