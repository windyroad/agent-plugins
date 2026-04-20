---
"@windyroad/itil": minor
---

Add `/wr-itil:report-upstream` skill — file a local problem ticket as a structured upstream issue or private security advisory with bidirectional cross-references. Implements the contract in ADR-024 (Cross-project problem-reporting contract).

The skill discovers upstream `.github/ISSUE_TEMPLATE/` via `gh api`, classifies the local ticket (bug / feature / question / security), picks the best-matching template (or falls through to a structured default when none exist), routes security-classified tickets via the upstream's `SECURITY.md` (GitHub Security Advisories, `security@` mailbox, or other declared channel — never auto-opens a public issue for a security-classified ticket), and back-writes a `## Reported Upstream` section + `## Related` line into the local ticket.

Three distinct AFK branches are encoded in the skill: public-issue path proceeds (voice-tone gate per ADR-028 may delegate-and-retry); declared-channel security path proceeds via `gh api .../security-advisories`; missing-`SECURITY.md` security path saves the drafted report and halts the orchestrator (loop-stopping event per ADR-024 Consequences). Above-appetite commit-gate uses the ADR-013 Rule 6 fail-safe.

Step-0 auto-delegation per ADR-027 is deliberately deferred — `report-upstream` is in ADR-027's "held for reassessment" set with the explicit note "narrow workflow; decided at implementation time". The skill's main-agent context is the right place to evaluate the security-path branch and surface the missing-SECURITY.md `AskUserQuestion`.

Includes a doc-lint bats test (Permitted Exception per ADR-005) covering all five ADR-024 Confirmation criterion 2 assertions plus the architect-required ADR-027 / ADR-028 / three-AFK-branch documentation. Closes P055 Part B; P055 Part A (intake scaffolding) shipped earlier in the same session.
