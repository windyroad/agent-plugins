---
"@windyroad/risk-scorer": minor
"@windyroad/architect": minor
"@windyroad/jtbd": minor
---

Add on-demand assessment skills (P020)

New user-invocable skills per ADR-015:
- `wr-risk-scorer:assess-release` — pipeline risk score on demand; pre-satisfies the commit gate
- `wr-risk-scorer:assess-wip` — WIP risk nudge for the current uncommitted diff
- `wr-architect:review-design` — on-demand ADR compliance review
- `wr-jtbd:review-jobs` — on-demand persona/job alignment check

All four skills are discoverable via `/` autocomplete and delegate to existing
governance subagents. No hook gate changes; bypass marker is still written by
the PostToolUse hook after the pipeline subagent runs.
