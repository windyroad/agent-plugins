---
"@windyroad/itil": patch
---

itil: governance skills auto-release when changesets are queued (P028)

Extends the terminal commit step of `manage-problem` and `manage-incident`
so non-AFK governance invocations drain the release queue automatically
after their own commit lands, rather than ending at `git commit` and
relying on the user to remember `npm run push:watch` and
`npm run release:watch`.

Mechanism (per new ADR-020):

- After commit, delegate to `wr-risk-scorer:assess-release` (subagent
  `wr-risk-scorer:pipeline` with Skill fallback per ADR-015).
- If `push` and `release` scores are both within appetite (≤ 4/25 per
  `RISK-POLICY.md`) AND `.changeset/` is non-empty, run
  `npm run push:watch` followed by `npm run release:watch`.
- Fail-safe identical to ADR-018: stop on `release:watch` failure, no
  retry. Above-appetite risk skips the drain and reports clearly.
- Skipped automatically when the skill is invoked inside an AFK
  orchestrator — those flows handle release cadence via ADR-018 Step 6.5
  and must not double-release.

Scope matches ADR-014 (manage-problem, manage-incident). The remaining
governance skills (`create-adr`, `run-retro`, `update-guide`,
`update-policy`) inherit ADR-020 automatically once they adopt ADR-014.

Splits the original P028 auto-install concern into P045 (deferred
pending Claude Code in-session plugin reload). Closes P028 pending user
verification.
