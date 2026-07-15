# Problem 418: Reviewer-agent marker hooks do not fire on SendMessage-resumed agents — ISSUES FOUND cannot be continued to a marker-writing PASS, forcing a full fresh re-review

**Status**: Open
**Reported**: 2026-07-05
**Priority**: 6 (Medium) — Impact: 2 (Minor — forces a full fresh re-review; friction not breakage) × Likelihood: 3 (Possible — recurs whenever an ISSUES-FOUND review is continued via SendMessage) — re-rated 2026-07-15 /wr-itil:review-problems
**Origin**: internal
**Effort**: M — marker-hook firing path for resumed agents (composes with the P402 launch-variant fix)
**WSJF**: 3.0 — (6 × 1.0) / 2
**JTBD**: JTBD-006
**Persona**: developer

## Description

Reviewer-agent marker hooks do not fire on SendMessage-resumed agents — a gate reviewer that returns ISSUES FOUND cannot be continued to a PASS via SendMessage; the resumed completion arrives as a background task-notification, no PostToolUse mark hook fires, no marker persists, and the edit gate re-blocks, forcing a full fresh synchronous re-review.

Observed 2026-07-05 P324 iter: architect pass 1 (synchronous Agent call, ISSUES FOUND — no marker, correct) was resumed via SendMessage with both issues resolved and re-verdicted PASS, but the PASS arrived as a task-notification and wrote no `/tmp/architect-reviewed-$SID` marker; the ci.yml Edit re-blocked; a fresh synchronous Agent call (pass 3, ~73k subagent tokens) was required to persist the marker.

Sibling of P402 (background-LAUNCHED review agents never fire mark hooks — fix was run_in_background:false guidance); this is the RESUME variant: even an initially-synchronous agent, once resumed via SendMessage, completes as background. Fix directions to evaluate: (a) document the fold-resolutions-and-fresh-dispatch pattern in the gate hooks' deny message + briefing; (b) extend the mark-hook surface to task-notification completions if the hook contract allows; (c) have reviewers emit conditional-PASS verdicts that the marker grep accepts when issues are plan-level companion actions.

## Symptoms

(deferred to investigation)

## Workaround

Fold the issue resolutions into an updated proposal and dispatch a FRESH synchronous Agent call (run_in_background:false) for the re-verdict — do not SendMessage-resume a gate reviewer expecting the marker. (Applied successfully in the observing session: pass-3 fresh dispatch persisted the marker and unblocked the edit.)

## Impact Assessment

- **Who is affected**: maintainers + AFK iterations — every gate review that returns ISSUES FOUND and is continued via SendMessage wastes the resume (~10-70k subagent tokens) and still pays a full fresh re-review.
- **Frequency**: (deferred to investigation)
- **Severity**: (deferred to investigation)
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Investigate root cause (where the PostToolUse mark hooks bind: Agent tool result only vs task-notification completions)
- [ ] Create reproduction test

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P402 (background-launched review agents never fire mark hooks — the LAUNCH variant of the same class; this ticket is the RESUME variant)

## Related

- captured via /wr-itil:capture-problem during the 2026-07-05 P324 AFK iter retro (run-retro Step 2b pipeline-instability scan, subagent-delegation friction category).
- Duplicate grep (3-keyword title-only) matched 22 filenames on the broad keyword `marker`; nearest sibling by substance is P402 (verifying) — the launch-variant ticket named above. Hang-off dispatch skipped (no ADR/RFC/skill-path/file-path signals in description per the sub-step 2b grammar).
