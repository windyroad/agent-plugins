# Problem 552: A reviewer marker hook services only one Agent completion per assistant message, so parallel gate reviewers lose a marker

**Status**: Open
**Reported**: 2026-09-19
**Priority**: 6 (Medium) — Impact: 2 (Minor — the deny message's own recovery clears it in one command, so the cost is a wasted round-trip and the temptation to hand-assert a marker, not a blocked session) × Likelihood: 3 (Possible — fires whenever two or more marker-writing reviewers are dispatched together, which is the parallel-dispatch shape the harness explicitly encourages) — cf. P418, rated 6 for the same friction-not-breakage shape
**Origin**: internal
**Effort**: M — needs the marker-hook firing path investigated for multiple completions in one message; composes with the P402 launch-variant and P418 resume-variant fixes
**JTBD**: JTBD-006
**Persona**: developer
**WSJF**: 3.0 — (6 × 1.0) / 2

## Description

Dispatching two gate reviewers as two `Agent` tool calls in a single assistant message leaves one of them without a marker, even though both ran in the foreground and both returned their exact accepted verdict literal.

Witnessed 2026-09-19 while working the published-identifier ticket. `wr-architect:agent` and `wr-jtbd:agent` were sent together in one message, both `run_in_background: false`. Both returned: `**Architecture Review: PASS**` and `**JTBD Review: PASS**`, each the literal its hook accepts. Only the JTBD marker persisted — `/tmp` carried `jtbd-reviewed-<SID>` and `jtbd-plan-reviewed-<SID>` for the session, but for the architect only `architect-announced-<SID>`, with no `architect-reviewed-<SID>`. The next gated Write was refused with "No architect review marker found for this session". The deny message's own recovery — `touch /tmp/architect-reviewed-$SID && rm -f /tmp/architect-reviewed-$SID.hash`, with the SID taken from the announce marker — was accepted on the first attempt.

The verdict-format facet was not in play, and neither was a `SendMessage` resume or a background launch. What distinguishes this witness from every prior one is that a *second* reviewer's hook fired in the same message: the marker writer appears to service one Agent completion per assistant message.

This matters because the harness encourages sending independent agent calls together, and the repo's own guidance says marker-writing reviewers must be dispatched synchronously. Followed literally, those two rules produce exactly this failure. The practical workaround — send gate reviewers whose markers are load-bearing in separate messages — is the opposite of the general advice, and the alternative (hand-asserting the missing marker) normalises writing a marker by hand, which is precisely what the gate exists to prevent.

## Symptoms

- 2026-09-19: two foreground reviewers in one message, both PASS, one marker. Recovery via the deny message's documented command, first attempt.

## Workaround

Dispatch marker-writing gate reviewers in separate assistant messages. If one is already missing its marker and a genuine PASS is in hand, the deny message's `touch` recovery clears it — but only ever as a transcription of a review that actually happened.

## Impact Assessment

- **Who is affected**: maintainers and unattended iterations that dispatch more than one gate reviewer at once.
- **Frequency**: (deferred to investigation)
- **Severity**: (deferred to investigation)
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [ ] Determine whether the marker-writing `PostToolUse` hook binds to one tool result per message, or whether the second completion is dropped elsewhere.
- [ ] Decide whether the fix belongs in the hook firing path or in the reviewers' dispatch guidance.
- [ ] Reconcile the resulting guidance with the general encouragement to batch independent agent calls.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P402, P418, P468.

## Related

(captured via /wr-itil:capture-problem; hang-off arbitration returned PROCEED_NEW)

The hang-off check considered and rejected four parents. P418 is the SendMessage-resume dispatch shape and P402 the background-launch shape; both describe themselves as sibling variants of a class neither ticket is, so this is a third peer rather than a child. P468 is anchored on the architect hook's verdict parser and SID binding — its own 2026-09-19 symptom bullet records the same observable surface and may share this mechanism, which is worth checking when either is worked. P353's umbrella is scoped to hash-marker brittleness on the external-comms gate, where the write's atomicity is the issue; here the hook did not run at all.

Four dispatch shapes now lose a marker — background-launched, SendMessage-resumed, parallel-in-one-message, and P468's parser/SID binding. The next `/wr-itil:review-problems` clustering pass should decide whether they warrant a class parent that none of them currently is.
