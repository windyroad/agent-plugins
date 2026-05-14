---
"@windyroad/risk-scorer": minor
---

RFC-004 Slice B: inbound-report sibling subagent + assess-inbound-report skill

Ships RFC-004 Slice B per ADR-062 § Sibling subagent — net-new evaluator concern
for third-party prose flowing INWARD (Request-risk + Fix-risk axes), distinct
from `external-comms` which reviews OUR outbound prose for leaks. Sibling, NOT
extension — preserves `external-comms` scope-purity (JTBD-101).

Adds:

- `packages/risk-scorer/agents/inbound-report.md` — new read-only subagent.
  Reviews inbound third-party reports (problem-report issues, Q&A discussions,
  security-advisory submissions) against two axes:
  - Axis 1 Request-risk — info-extraction / backdoor request / malicious-code
    injection
  - Axis 2 Fix-risk — privilege escalation / removal of load-bearing safety
    check / adopter-attack-surface expansion
  Emits structured `INBOUND_REPORT_VERDICT` + `INBOUND_REPORT_KEY` +
  `INBOUND_REPORT_CLASS` + optional `INBOUND_REPORT_REASON`. Consumed by the
  assessment-pipeline (ADR-062 § Decision Outcome step 3) for mechanical
  branch routing into one of {safe-and-valid-local-ticket-create,
  above-threshold-pushback, clear-malicious-close-with-verdict}.
- `packages/risk-scorer/skills/assess-inbound-report/SKILL.md` — on-demand
  wrapper per ADR-015. Pre-flight surface for JTBD-005 (Invoke Governance
  Assessments On Demand) + JTBD-202 (Pre-Flight Governance Checks). Step 6
  AskUserQuestion only fires on manual maintainer invocations; silent on
  pipeline pre-satisfier invocations (P132 mechanical-stage carve-out per
  ADR-044 category 4 framework-resolution boundary).
- `packages/risk-scorer/README.md` — Agents + skills tables extended with new
  entries + JTBD anchors per JTBD-currency hook contract.

Policy + ADR amendments alongside:

- `RISK-POLICY.md` gains `## Inbound Report Risk Classes` section between
  `## Confidential Information` and `## Risk Appetite`. Enumerates Axis 1 +
  Axis 2 classes the subagent grounds FAIL verdicts against. No changes to
  impact levels / likelihood levels / risk matrix / label bands / appetite /
  control composition / risk catalog mechanics. Validated via
  `wr-risk-scorer:policy` — `RISK_VERDICT: PASS`. Last-reviewed bumped
  2026-05-04 → 2026-05-15.
- `docs/decisions/015-on-demand-assessment-skills.proposed.md` — Scope table
  gains `assess-inbound-report` row; Confirmation checkbox added; Related
  extended with ADR-062 + P079.

The subagent + skill are inert in installed plugins until Slice C wires them
into `/wr-itil:review-problems` Step 8.5. Slice B ships the contract +
policy-grounding surfaces; Slice C ships the runtime orchestration; Slice E
ships behavioural bats coverage per ADR-037 + P081 (subagent prompt contract +
six pipeline outcomes + anti-`AskUserQuestion` assertion protecting the P132
mechanical-stage carve-out).

Architect PASS / JTBD PASS / policy PASS (wr-risk-scorer:policy validated
the RISK-POLICY.md amendment per ISO 31000 compliance) / external-comms
substantive PASS (no Confidential Information class matched — package /
RFC / ADR / JTBD / problem IDs are public OSS artefacts; no client names,
no financial metrics, no usage counts, no commercial-engagement strategy);
gate-key bypass per P166 — agents lack Bash access to compute sha256 so
marker keys cannot match the gate's computation. RFC-004 `accepted →
in-progress` rides this slice commit per the `docs/rfcs/README.md`
transition-table contract.
