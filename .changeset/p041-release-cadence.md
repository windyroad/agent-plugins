---
"@windyroad/itil": patch
---

work-problems: enforce inter-iteration release cadence (P041)

Adds Step 6.5 (Release-cadence check) to the work-problems AFK orchestrator
per ADR-018. After each successful iteration, the orchestrator now invokes
`wr-risk-scorer:assess-release` (or its pipeline subagent) and, if `push` or
`release` score is at or above appetite (4/25 per RISK-POLICY.md), drains
the queue with `npm run push:watch` then `npm run release:watch` before
starting the next iteration. The drain runs non-interactively per ADR-013
Rule 6 (policy-authorised when within appetite). On `release:watch`
failure, the loop stops and reports — no non-interactive retry.

Also adds a row to the Non-Interactive Decision Making table covering the
new behaviour, and a bats test asserting the SKILL.md references both
`assess-release` and `release:watch` (ADR-018 confirmation criterion).

Closes P041 pending user verification of the next AFK loop.
