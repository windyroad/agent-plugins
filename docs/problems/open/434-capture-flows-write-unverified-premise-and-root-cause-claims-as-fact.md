# Problem 434: Capture flows write unverified claims (premise + root-cause mechanism) as established fact

**Status**: Open
**Reported**: 2026-07-06
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4
**Origin**: inbound-reported (#202, #339)
**Effort**: M. WSJF = (12 × 1.0) / 2 = 6.0.
**JTBD**: JTBD-101
**Persona**: plugin-developer

## Description

`/wr-itil:capture-problem` (and the `manage-problem` new-problem path) commit tickets without (a) falsifying the reporter's *premise* against the local tree (#202: "component X is missing" when X is in fact exported → phantom ticket), and (b) marking unexecuted *root-cause mechanism* claims as hypotheses rather than fact (#339: a false mechanism replicated into multiple body locations nearly steered a fix at a non-existent problem). Both are the same capture-time truth-discipline defect: reporter/agent assertions land as fact with no verification step.

## Symptoms

- A ticket asserts a premise ("X missing") that a quick grep would falsify, and states an unexecuted root-cause mechanism as established fact — both surviving into the committed ticket and downstream fix planning.

## Impact Assessment

- **Who is affected**: maintainer + adopters; phantom tickets and misdirected fixes.
- **Frequency**: any capture where the premise/mechanism is asserted without a verification pass.
- **Severity**: High — wrong-premise tickets waste whole iters and can ship fixes at non-problems.

## Root Cause Analysis

### Investigation Tasks

- [ ] Add a Step 1.7 premise-triage to capture-problem: derive falsifiers → grep local tree → advisory (silent-proceed under AFK).
- [ ] Write unexecuted root-cause mechanism claims as "hypothesis — unverified" + attach a verification task, rather than as fact.

## Dependencies

- **Composes with**: (distinct from the capture-problem family P185 classification / P199 halt / P281 path / P383 persona-enum — none covers premise/claim verification).

## Related

- Inbound issues #202, #339.
