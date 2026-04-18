---
"@windyroad/risk-scorer": patch
---

Risk scorer emits explicit STOP verdict above appetite.

- `pipeline.md`, `wip.md`, `plan.md`: Above-Appetite sections now contain an
  explicit STOP / PAUSE / FAIL directive and forbid "Proceed", "Continue",
  "You may ship", and similar nudge language when cumulative risk exceeds
  appetite. The only sanctioned above-appetite output is the Risk Report +
  `RISK_SCORES:` + structured `RISK_REMEDIATIONS:` block — matching the
  symmetrical Below-Appetite Output Rule (ADR-013 Rule 5)
- Doc-lint guard `risk-scorer-above-appetite-stop.bats` prevents regression
  across all three scoring modes
- Previously, the scorer could contradict itself (structured output: high
  risk; verbal verdict: proceed with release), causing the agent to attempt
  gated actions and waste tool calls when the hook gate correctly blocked them
