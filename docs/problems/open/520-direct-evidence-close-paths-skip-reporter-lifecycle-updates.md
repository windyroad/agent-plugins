# Problem 520: Direct evidence-close paths skip reporter lifecycle updates

**Status**: Open
**Reported**: 2026-08-24
**Priority**: 9 (Medium) — Impact: 3 (Moderate — a reporter receives no resolution comment when a direct review path closes the local ticket) × Likelihood: 3 (Possible — fires when a review bucket closes directly instead of using the transition executor)
**Origin**: internal
**Effort**: M
**WSJF**: 4.5 — (9 × 1.0) / 2
**JTBD**: JTBD-301, JTBD-006
**Persona**: plugin-user

## Description

The review workflow's evidence-backed bucket performs its own `git mv` from Verification Pending to Closed. Unlike the transition executor, that direct path does not dispatch the lifecycle-update skill, so a reporter may never receive the closing verdict even though the local ticket closes correctly.

The earlier quiet-period premise is retired: the published template no longer promises a timed close, and provenance-proven issues on this project's tracker close immediately after the gated comment. The remaining problem is dispatch reachability, not a missing timer.

## Symptoms

- The review bucket moves a ticket to Closed without invoking the lifecycle-update skill.
- The local ticket leaves the Verification Queue, so a later pass does not rediscover the missed notification.
- An inbound reporter sees no closing verdict; a foreign tracker sees no lifecycle comment.

## Workaround

After a direct review close, invoke `/wr-itil:update-upstream <NNN>` before committing the transition.

## Impact Assessment

- **Who is affected**: reporters whose tickets close through a direct review path.
- **Frequency**: once per reporter-linked ticket closed by that path.
- **Severity**: the fix lands but the reporter-facing audit trail remains incomplete.

## Root Cause Analysis

The lifecycle-update dispatch is embedded in the transition executor, while the review bucket duplicates the rename and commit mechanics without calling that dispatcher. The copied close path therefore omits the reporter side effect.

### Investigation Tasks

- [ ] Route direct review closes through the existing lifecycle-update dispatcher, or call it immediately after the rename.
- [ ] Preserve both-direction independence and above-appetite queue-and-continue behavior.
- [ ] Add behavioural coverage proving a direct evidence close reaches the reporter lifecycle update.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P519 (evidence-backed closure), P525 (owned-versus-foreign tracker authority), P450 (the evidence write path feeding the same queue)

## Related

- P519 (known-error) — evidence-based closure made the direct review path a primary queue exit.
- P525 (known-error) — establishes when the dispatched lifecycle path may mutate an issue.
- STORY-MAP-004 — "Close the loop with someone who reported a problem"; its final step requires this dispatch.
