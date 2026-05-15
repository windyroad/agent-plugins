---
"@windyroad/itil": patch
"@windyroad/risk-scorer": patch
---

RFC-004 Slice E: bats coverage for inbound-discovery + assessment-pipeline

Closes the R009 empirical-coverage gap for Slice B (`f635470`) + Slice C
(`368b8e6`) SKILL/agent prose. 85 assertions across 4 bats files —
structural-with-Permitted-Exception per ADR-005 / P011 / ADR-037 /
ADR-052 § Surface 2 for SKILL/agent-prose contracts; behavioural per
P081 for JSON file shapes.

Files added:

- `packages/itil/skills/review-problems/test/inbound-discovery-contract.bats`
  (28 tests) — Step 4.5 SKILL.md prose contract: section presence,
  ADR-062 substring anchors preserved (Confirmation criterion 1
  string-anchorable), sub-step structure, six pipeline outcomes
  enumerated, JTBD-301 acknowledgement on all four outcome paths, P070
  matched-local-ticket cross-reference comment, **load-bearing
  anti-AskUserQuestion assertion** at the branch decision (protects
  JTBD-001 + JTBD-006 against inverse-P078 drift per P132
  mechanical-stage carve-out / ADR-044 category 4), fail-soft, downstream
  non-obligation, AFK silent path, SLICE-C-FLAG-STUB marker.

- `packages/risk-scorer/agents/test/inbound-report-contract.bats`
  (27 tests) — inbound-report subagent prompt contract: frontmatter,
  sibling-not-extension framing, two-axis rubric, four classifications,
  structured verdict block, ADR-026 grounding, read-only invariant,
  P123 block-list scope carve-out, RISK-POLICY.md integration.

- `packages/risk-scorer/skills/assess-inbound-report/test/assess-inbound-report-contract.bats`
  (14 tests) — on-demand skill contract: frontmatter, subagent
  delegation, no marker self-writes, manual-vs-pipeline carve-out,
  JTBD-005 + JTBD-202 drivers, ADR-015 Scope-table row.

- `packages/itil/skills/review-problems/test/inbound-channels-cache-shape.bats`
  (16 tests — behavioural per P081) — JSON file shape contracts:
  upstream-channels.json + upstream-cache.json + inbound-discovery-log.md
  P131 path discipline.

All 85 assertions pass; broader test suite (205 tests across
review-problems + risk-scorer surfaces) green.

Full behavioural synthetic-channel fixture (running the pipeline
end-to-end with synthetic gh API responses and asserting six-outcome
routing) remains deferred to the P012 master harness ticket; in-skill
behavioural-replay is structurally limited per ADR-005 / P011 Permitted
Exception.

Slice E closes the R009 SKILL-prose-class empirical-coverage gap that
the pipeline scorer flagged on Slice B + Slice C ship.
