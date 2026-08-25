# Problem 520: Nothing delivers the quiet-period follow-up we promise reporters

**Status**: Open
**Reported**: 2026-08-24
**Priority**: 9 (Medium) — Impact: 3 (Moderate — a published promise to an external reporter goes unkept; the reporter's issue sits open indefinitely with no party enumerating it) × Likelihood: 3 (Possible — fires once per inbound-reported ticket that reaches evidence-based closure)
**Origin**: internal
**Effort**: M
**WSJF**: 4.5 — (9 × 1.0) / 2
**JTBD**: JTBD-301, JTBD-006
**Persona**: plugin-user

## Description

`/wr-itil:update-upstream` told external reporters we would close their issue after their confirmation **or after a 14-day quiet period**. No quiet-period sweep exists — the JTBD reviewer searched every skill, script and hook during the P519 review and found no carrier.

P519 makes this worse rather than better. Under evidence-based closure the local ticket goes `.closed.md` while the upstream issue is deliberately left open (the P500 / JTBD-301 carve-out: our own test passing is not the reporter's confirmation). But a closed ticket has left the Verification Queue, so **nothing local enumerates it any more**. The `posted-comment-local-close-only` marker is written into the back-write path and nothing consumes it.

Net effect: we make a dated promise to someone outside the project, then drop the only handle that could have kept it.

P519 struck the promise from the two templates rather than shipping a sweep inside an already-large commit — promising a follow-up no machinery delivers is worse than not promising it. This ticket carries the sweep.

## Symptoms

- `update-upstream` Step 7b posts a lifecycle comment and stops, correctly leaving the reporter's issue open.
- The local ticket closes and leaves the Verification Queue.
- No skill, script, hook or cadence subsequently enumerates locally-closed tickets holding an open upstream reference.
- STORY-MAP-004 ("Close the loop with someone who reported a problem") cannot reach its last step.

## Workaround

None automated. A maintainer must manually recall which inbound-reported tickets were closed locally and check their upstream issues.

## Impact Assessment

- **Who is affected**: external reporters (JTBD-301 persona, for whom "reporting is incidental" — the burden of closing lands on the person least likely to return), and maintainers who lose the outbound audit trail.
- **Frequency**: once per inbound-reported ticket reaching evidence-based closure.
- **Severity**: a published commitment goes unkept; contradicts JTBD-301's ratified desired outcome that submitted reports are "eventually responded to with a verdict".

## Root Cause Analysis

The quiet-period close was specified in comment-template prose only. Per P375, a named re-entry point that nothing self-fires is not a cadence — it rots. This is that class: the promise named a future action with no trigger behind it.

### Investigation Tasks

- [ ] Decide the carrier: a Verification-Queue-equivalent table that survives local closure, or a `/wr-itil:review-problems` pass over `.closed.md` tickets carrying `closed-on-evidence` plus an open upstream ref
- [ ] Confirm the trigger is self-firing (P375 rot test: transitive reachability to a self-firing trigger), not a named re-entry point
- [ ] Define what the follow-up posts, and whether the quiet period may ever close the reporter's issue on our authority
- [ ] Restore the quiet-period sentence to the `update-upstream` templates once, and only once, the sweep exists
- [ ] Decide whether `/wr-itil:review-problems` Bucket 1 must dispatch the lifecycle comment, or route inbound-origin tickets to the transition path that does — a Bucket 1 close performs the `git mv` and posts NO comment at all, so the reporter never learns the verdict. Pre-existing (Bucket 2 shares the shape), but P519 promotes Bucket 1 from a rare path to the primary exit from a 153-ticket queue, so the frequency changes materially. Surfaced by the JTBD re-review 2026-08-24 as a consequence of the architect's correction that `review-problems` never dispatches `update-upstream`.
- [ ] Behavioural coverage per ADR-052

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P519 (struck the promise and created this ticket), P450 (the evidence write path feeding the same queue)

## Related

- P519 (known-error) — evidence-based closure; struck the unfulfillable promise from the templates at `packages/itil/skills/update-upstream/SKILL.md`.
- P375 (verifying) — named re-entry point vs self-firing cadence; this is an instance of that class.
- P048 — the 14-day quiet-period default the struck template prose cited.
- STORY-MAP-004 — "Close the loop with someone who reported a problem"; its final step is unreachable without this.
- ADR-024 / ADR-117 — upstream reporting contract and the comment-do-not-close carve-out.
