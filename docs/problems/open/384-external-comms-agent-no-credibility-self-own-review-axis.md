# Problem 384: wr-risk-scorer:external-comms agent has no credibility / self-own review axis

**Status**: Open
**Reported**: 2026-06-26
**Priority**: 9 (Medium) — Impact: 3 x Likelihood: 3
**Origin**: inbound-reported (#283)
**Effort**: M
**JTBD**: JTBD-101
**Persona**: plugin-developer

## Description

The `wr-risk-scorer:external-comms` agent reviews outbound prose for confidential-information leaks, but has no axis for credibility / self-own failures: asking the recipient for something the sender already holds, restating what the recipient told us as if new, or careless errors (wrong name, wrong company, stale claims about their account). For a trust-ramp product these are real reputational costs, distinct from and sometimes higher-stakes than a minor leak.

## Symptoms

- A leak-clean outbound message with a self-own error (asks for already-held info, restates prior-as-new, wrong name/company) passes the gate.

## Workaround

Manual operator review of outbound prose for credibility errors.

## Impact Assessment

- **Who is affected**: operators using external-comms gating on outbound customer/prospect prose, including prose the assistant drafts on their behalf.
- **Frequency**: any outbound message with a credibility error.
- **Severity**: reputational cost on a trust-ramp product; orthogonal to the existing leak axis.

## Root Cause Analysis

### Investigation Tasks

- [ ] Add a credibility / self-own review axis to `packages/risk-scorer/agents/external-comms.md` and emit it in the verdict
- [ ] Candidate flags: `asks-for-already-held-info`, `restates-prior-as-new`, `plainly-careless-error`
- [ ] Axis composes with (does not replace) the existing confidential-leak axis — a message can be leak-clean and still fail this check
- [ ] Paired promptfoo eval per ADR-075 / RFC-012 (R009 prose-surface floor)
- [ ] Check whether RISK-POLICY.md needs a corresponding credibility / self-own section to ground the verdict (ADR-026)

## Dependencies

- **Blocks**: scoring of operator-authored credibility/self-own policy sections
- **Blocked by**: (none)
- **Composes with**: P283 external-comms agent family; P381/P324 (R009 prose-surface eval coverage)

## Related

- **Upstream**: windyroad/agent-plugins#283 — an adopter has authored the matching policy locally (a credibility / self-own section covering outbound customer/prospect prose); the agent needs the corresponding review axis to score it.
- `packages/risk-scorer/agents/external-comms.md` — the locus.
- **RISK-POLICY.md** `## Confidential Information` — current outbound axis; credibility axis would sit alongside.
