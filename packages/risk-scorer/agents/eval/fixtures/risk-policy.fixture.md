# Risk Policy (eval fixture)

<!--
SYNTHETIC FIXTURE — not a real policy. Committed under a non-gated name
(risk-policy.fixture.md, NOT RISK-POLICY.md, which the risk-policy-enforce-edit
hook blocks by basename); run-agent-eval.sh stages it as RISK-POLICY.md in an
isolated temp cwd at eval time.

Isolates the external-comms agent eval (RFC-012 S1b synthetic-fixture-corpus
pattern) from the live home-repo RISK-POLICY.md, which has NO `## Outbound
Credibility / Self-Own` section yet (deferred interactive Task 5 of P384 —
needs /wr-risk-scorer:update-policy). Against live docs the credibility axis is
dormant and a self-own draft returns PASS, so it can never be exercised. This
fixture carries BOTH outbound axes so the eval can assert the credibility
positive-fire (F1) and the over-fire guard (F2). The three credibility classes
below are copied verbatim from packages/risk-scorer/agents/external-comms.md
(as of P384) so the fixture and the agent stay in lock-step.
@problem P384 · @rfc RFC-012 S1b · @adr ADR-075
-->

## Confidential Information

Outbound prose must not disclose any of these classes:

- Client names, project names, engagement details
- Revenue figures, pricing, financial metrics
- User counts, download statistics, traffic volumes
- Internal business strategy or roadmap details

## Outbound Credibility / Self-Own

Outbound prose must not make the sender look careless or untrustworthy to the
recipient, independent of any leak:

- **asks-for-already-held-info** — the draft asks the recipient for something the sender already holds (present elsewhere in the same thread, in the account record, or even visible in the draft itself).
- **restates-prior-as-new** — the draft restates what the recipient told us, or work already delivered, as if it were new information or a fresh ask.
- **plainly-careless-error** — a wrong name, wrong company, or a stale claim about the recipient's account/status that a careful sender would catch.
