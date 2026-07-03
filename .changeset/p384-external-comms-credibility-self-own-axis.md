---
"@windyroad/risk-scorer": minor
---

external-comms agent: add an outbound credibility / self-own review axis

The `wr-risk-scorer:external-comms` agent now reviews outbound prose on two
composing axes instead of one. Alongside the existing confidential-information
leak axis it checks for credibility / self-own errors: asking the recipient for
something the sender already holds (`asks-for-already-held-info`), restating what
the recipient told us as if new (`restates-prior-as-new`), and plainly careless
mistakes like a wrong name, wrong company, or stale account claim
(`plainly-careless-error`). The axes are independent — a leak-clean draft can
still fail credibility, and a FAIL on either axis is a FAIL verdict.

The agent reads its class list from `RISK-POLICY.md` at runtime, so the credibility
axis activates wherever an `## Outbound Credibility / Self-Own` policy section is
present and stays dormant where it is absent. The PASS/FAIL verdict contract and
the marker-key derivation are unchanged.
