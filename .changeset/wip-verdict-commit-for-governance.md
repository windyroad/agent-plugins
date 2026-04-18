---
"@windyroad/risk-scorer": patch
---

WIP verdict now emits `RISK_VERDICT: COMMIT` with a `RISK_COMMIT_REASON` when the WIP scorer detects completed governance work (closed problem tickets, accepted ADRs, transitioned states) that has not yet been committed (closes P024, implements ADR-016).

- `wr-risk-scorer:wip` agent emits the new verdict with an explicit false-positive safeguard: any file outside governance-artefact paths suppresses `COMMIT`.
- `wr-risk-scorer:assess-wip` skill Step 4 surfaces the verdict via `AskUserQuestion` with a "Not yet" defer option so users can defer without consequence.
- New `packages/risk-scorer/agents/test/risk-scorer-commit-verdict.bats` covers the four contract assertions from ADR-016.
