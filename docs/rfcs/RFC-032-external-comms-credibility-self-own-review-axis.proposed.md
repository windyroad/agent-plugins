---
status: proposed
rfc-id: external-comms-credibility-self-own-review-axis
reported: 2026-06-27
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P384]
adrs: []
jtbd: []
stories: []
---

# RFC-032: External-comms credibility / self-own review axis

**Status**: proposed
**Reported**: 2026-06-27
**Problems**: P384
**ADRs**: (none)
**JTBD**: (none)

## Summary

Add an outbound credibility / self-own review axis to the `wr-risk-scorer:external-comms` agent (`packages/risk-scorer/agents/external-comms.md`), grounded in a new `## Outbound Credibility / Self-Own` section in `RISK-POLICY.md`. The axis composes with — it does not replace — the existing confidential-leak axis: a draft must clear both. Candidate self-own flags: `asks-for-already-held-info`, `restates-prior-as-new`, `plainly-careless-error`.

## Driving problem trace

- **P384** — the external-comms agent reviews outbound prose only for confidential-information leaks; a leak-clean message with a self-own error (asks for already-held info, restates prior-as-new, wrong name/company/stale claim) passes the gate. For a trust-ramp product these are real reputational costs orthogonal to the leak axis.

## Scope

(deferred — populate at /wr-itil:manage-rfc accepted transition)

## Tasks

- [ ] (deferred — populate at /wr-itil:manage-rfc accepted transition)

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook)

## Related

(captured via /wr-itil:capture-rfc; expand at next /wr-itil:manage-rfc invocation)
