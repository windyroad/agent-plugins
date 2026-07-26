# Problem 400: architect-mark-reviewed PostToolUse never fires on a SendMessage resume of an architect agent

**Status**: Verification Pending
**Reported**: 2026-06-28
**Priority**: 9 (Medium) — Impact: 3 × Likelihood: 3 = 9. Rated at review 2026-07-02: SendMessage-resume mark hook doesn't fire; event-binding fix.
**Origin**: internal
**Effort**: S. WSJF = (9 × 1.0) / 1 = 4.5.
**JTBD**: JTBD-001
**Persona**: developer (re-anchored from plugin-developer 2026-07-03 per wr-jtbd:agent — JTBD-001 is a developer-persona job; AFK auto-capture default was provisional)

## Description

The architect edit-gate marker is written by `architect-mark-reviewed.sh`, a `PostToolUse:Agent` hook keyed on a fresh `Agent` tool call whose subagent is `*architect*`. When an architect review returns `ISSUES FOUND` (no marker written), the natural recovery is to resolve the issues and **resume the same architect agent via `SendMessage`** to upgrade the verdict to PASS. But `SendMessage`-resume is NOT an `Agent` tool call, so the `PostToolUse:Agent` hook never fires — even when the resumed agent renders a clean `**Architecture Review: PASS**` heading, the gate marker is never written and the edit stays blocked.

Recovery requires either (a) a fresh `Agent` re-spawn of `wr-architect:agent` whose output leads with `**Architecture Review: PASS**` (fires the PostToolUse → writes marker+hash), or (b) the sanctioned manual marker assertion after a genuine PASS: `touch /tmp/architect-reviewed-$SID && rm -f /tmp/architect-reviewed-$SID.hash` (marker-present + no-hash → `architect-gate.sh` allows and skips the drift re-check).

Observed 2026-06-28 in the P399 (full-RFC fix-time authoring) iter: first architect verdict was `ISSUES FOUND` (no marker); issues resolved; the same agent was `SendMessage`-resumed and rendered `**Architecture Review: PASS**`, but the `docs/decisions/073-*.md` edit stayed blocked because the marker was never written. Resolved via path (b).

## Symptoms

- After resolving architect-flagged issues and `SendMessage`-resuming the architect to a clean PASS, Edit/Write to the gated file is still denied with "No architect review marker found for this session".
- The briefing entry in `docs/briefing/agent-hook-gate-quirks.md` previously advised "re-invoke OR SendMessage asking for a PASS heading" — the SendMessage half is wrong (now corrected in that file).
- **(New evidence 2026-07-26, P424 iter — a SECOND trigger, distinct from SendMessage-resume, that this ticket's fix does not cover.)** Recovery path (a) above says a fresh `Agent` re-spawn "whose output leads with `**Architecture Review: PASS**`" fires the PostToolUse and writes the marker. A fresh spawn was used, the verdict was a genuine unqualified PASS ("Nothing further blocks. Land it."), and the marker was still never written — because the agent rendered its verdict as a markdown h2, `## Architecture Review: PASS`, rather than the bold form the grep expects. The subsequent `docs/rfcs/` Write denied with the same "No architect review marker found for this session" reason. So the mark hook is brittle to the architect agent's own heading format, and nothing pins that agent to emit the bold form: rounds 1 and 2 of the same iteration also led with `##`, they just happened to be ISSUES FOUND verdicts where the missing marker was correct. Resolved via path (b), the manual assertion. Two notes for whoever fixes this: the deny message itself prescribes path (b), so the recovery is discoverable; and the SID for path (b) is NOT reliably the newest `architect-announced-*` basename — that resolved to a stale session here, and the correct SID had to be recovered from the newest `~/.claude/projects/<slug>/*.jsonl` transcript filename and confirmed by grepping it for in-session content. Whether this is one defect with two triggers (mark-hook fires on too narrow a signal) or two, the verdict-format half is untested by this ticket's fix.

## Workaround

Manual marker assertion after a genuine PASS: `touch /tmp/architect-reviewed-$SID && rm -f /tmp/architect-reviewed-$SID.hash` (SID = newest `architect-plan-reviewed-*` / `architect-announced-*` basename), OR fresh-spawn a new architect agent.

## Impact Assessment

- **Who is affected**: plugin-developer (anyone using the architect edit-gate, especially AFK iters that resume an architect to upgrade an ISSUES→PASS verdict).
- **Frequency**: every verdict-upgrade-via-SendMessage flow (the natural recovery after an ISSUES FOUND verdict).
- **Severity**: friction, not a functional break — the manual marker assertion is a reliable recovery, but it is undocumented in the gate's own deny message and easy to mistake for the multi-decision-file deadlock.

## Root Cause Analysis

`architect-mark-reviewed.sh` line 18 gates on `TOOL_NAME = "Agent"`. A `SendMessage`-resume of an existing agent does not surface as a fresh `Agent` PostToolUse event, so the marker-write code path is never reached. The hook's verdict-grep (P181) is a separate, compounding precision issue — but even a perfect verdict-grep cannot help when the hook does not run at all.

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Investigate whether a PostToolUse (or other) hook surface fires on SendMessage-resume completion of an architect agent — if so, wire architect-mark-reviewed to also fire there (fix candidate a). **Finding (2026-07-03)**: no confirmed SendMessage-resume completion hook surface exists that also carries reliable subagent identity (`_get_subagent_type` is empty on a SendMessage tool call — the hook cannot tell the resumed agent is an architect, and keying the marker-write on any SendMessage whose reply contains the PASS heading would mis-fire for non-architect agents, exceeding the Low risk appetite). Fix candidate (a) rejected on that basis; took candidate (b).
- [x] Else: document in the architect gate flow + the deny message that verdict upgrades must be a fresh Agent spawn or the manual marker assertion, never a SendMessage resume (fix candidate b). Done: `architect-gate.sh` no-marker deny reason now carries the SendMessage-resume caveat + manual marker-assertion recovery; the briefing (`docs/briefing/agent-hook-gate-quirks.md`) already documented it.
- [x] Create reproduction test — behavioural bats `architect-gate.bats` "ARCHITECT_GATE_REASON documents SendMessage-resume recovery when no marker" asserts the deny reason carries the caveat + recovery.

## Fix Strategy

**Kind**: improve. **Shape**: hook (or guide). Either extend `packages/architect/hooks/architect-mark-reviewed.sh` to fire on a SendMessage-resume completion surface (if Claude Code exposes one), or — if no such surface exists — amend the architect gate flow + deny message (`architect-gate.sh::ARCHITECT_GATE_REASON`) to state that an ISSUES→PASS verdict upgrade requires a fresh Agent spawn or the manual marker assertion, NOT a SendMessage resume. Evidence: P399 iter 2026-06-28 (this ticket's Description).

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P181 (architect-mark-reviewed verdict-grep fragility — same hook, orthogonal locus: verdict-parsing vs event-binding), P353 (hash-marker brittleness umbrella — a distinct fourth sub-cause: hook-never-invoked), P215 (gate-drift recovery path — distinct: marker never written vs removed by drift), P303 (architect-gate deadlock — shares the manual `touch+rm .hash` workaround but a different root cause).

## Related

Captured via /wr-itil:capture-problem during the P399 iter retro (2026-06-28). Hang-off-check arbiter verdict: PROCEED_NEW — the event-binding root cause (PostToolUse:Agent not firing on SendMessage-resume) is named by none of P181/P353/P215/P303, all of which concern what the hook does *when it fires*. `/wr-itil:review-problems` may cluster this with the P353 umbrella later if a class-level event-binding facet emerges.

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-021 | proposed | P215 — architect-gate deny-reason recovery directive |

## Fix Released

Fix candidate (b) implemented 2026-07-03: `packages/architect/hooks/lib/architect-gate.sh` no-marker `ARCHITECT_GATE_REASON` now documents the SendMessage-resume recovery path (a verdict upgrade after an ISSUES FOUND review must be a FRESH `Agent` spawn — a `SendMessage` resume does not fire the `PostToolUse:Agent` marker hook — or the manual `touch /tmp/architect-reviewed-$SID && rm -f $SID.hash` assertion). Traced to RFC-021 (existing architect-gate deny-reason recovery-directive vehicle) per ADR-073 I13 sub-case (a). Behavioural bats coverage added. Committed on `main`; ships in the next `@windyroad/architect` release (orchestrator-owned cadence per this AFK loop — not yet released). Awaiting live verification that a blocked edit's deny message shows the SendMessage-resume guidance.
