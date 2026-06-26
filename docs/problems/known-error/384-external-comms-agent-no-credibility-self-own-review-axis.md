# Problem 384: wr-risk-scorer:external-comms agent has no credibility / self-own review axis

**Status**: Known Error
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

**Confirmed root cause**: the `external-comms` agent's job statement, review process, and grounding section named only the `## Confidential Information` (leak) axis. The agent reads its class list *from* RISK-POLICY.md at runtime (it does not hardcode classes), so the gap is two-part: (1) the agent prose carried no instruction to review a credibility/self-own axis, and (2) RISK-POLICY.md has no `## Outbound Credibility / Self-Own` section for such an axis to cite per ADR-026 grounding. A leak-clean draft with a self-own error therefore passed silently.

**Reproduction (conceptual)**: a `gh-issue-comment` draft that asks the recipient for an account email it already quotes two lines above is leak-clean (no Confidential Information class matches) and so returns PASS today — the credibility axis now FAILs it with an `asks-for-already-held-info` citation.

### Investigation Tasks

- [x] Add a credibility / self-own review axis to `packages/risk-scorer/agents/external-comms.md` and emit it in the verdict — **done**: "two composing axes" framing in the job statement + a dedicated review-process step (step 4) + grounding example. Verdict contract unchanged (a credibility FAIL emits the existing `EXTERNAL_COMMS_RISK_VERDICT: FAIL` + `EXTERNAL_COMMS_RISK_REASON` naming the axis), so `risk-score-mark.sh` and the marker-key derivation are untouched — architect-confirmed ADR-028-compliant.
- [x] Candidate flags: `asks-for-already-held-info`, `restates-prior-as-new`, `plainly-careless-error` — **done**, all three named in the agent.
- [x] Axis composes with (does not replace) the existing confidential-leak axis — **done**: agent states the axes are independent and a FAIL on either is a FAIL; a leak-clean draft can still FAIL credibility.
- [ ] **Deferred (R009 prose-surface floor / held cohort)**: paired promptfoo eval per ADR-075 / RFC-012 asserting a leak-clean self-own draft FAILs citing the new class. Agent-prose verdicts have no behavioural harness (P324 / R029); a structural grep test is disavowed (ADR-052 / P290). Same eval-coverage class held for siblings (P381 / P383 / P199) — expect the changeset to be held until the eval lands.
- [ ] **Deferred (interactive)**: add the `## Outbound Credibility / Self-Own` section to the home-repo RISK-POLICY.md to ground + dogfood the verdict (ADR-026). Direct RISK-POLICY.md edits are blocked by the policy edit-gate, which mandates `/wr-risk-scorer:update-policy`; that skill mandates AskUserQuestion (step 6), so it cannot run in an AFK iter. The agent degrades gracefully meanwhile: where the section is absent the credibility axis is dormant (no home-repo regression); an adopter who authored the section locally (the #283 case) gets scoring immediately.

## Fix Strategy

Traced by **RFC-032** (External-comms credibility / self-own review axis). The agent-prose axis is the primary, adopter-portable deliverable (it activates for any RISK-POLICY.md carrying the credibility section). The home-repo policy section + paired promptfoo eval are deferred per the two unticked tasks above.

## Dependencies

- **Blocks**: scoring of operator-authored credibility/self-own policy sections
- **Blocked by**: (none)
- **Composes with**: P283 external-comms agent family; P381/P324 (R009 prose-surface eval coverage)

## Related

- **Upstream**: windyroad/agent-plugins#283 — an adopter has authored the matching policy locally (a credibility / self-own section covering outbound customer/prospect prose); the agent needs the corresponding review axis to score it.
- `packages/risk-scorer/agents/external-comms.md` — the locus.
- **RISK-POLICY.md** `## Confidential Information` — current outbound axis; credibility axis would sit alongside.

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-032 | proposed | External-comms credibility / self-own review axis |
