---
"@windyroad/itil": patch
---

P144: document gate-misfire recovery procedure in `manage-problem` Step 2 substep 7 (two-tier — announce-marker scrape + python3-via-Bash fallback) and add a conditional recovery hint to the `manage-problem-enforce-create.sh` deny message that fires only when `compgen -G '/tmp/manage-problem-grep-*'` matches at least one marker for SOME SID (the helper-bug signal). ADR-048 sanctions and scopes the procedure with explicit P142-auto-supersession criteria and an audit-trail-preservation test that rules out the P131 any-marker-anywhere anti-pattern.

The recovery surfaces a documented forward path for orchestrator sessions where the P124 helper returns a subprocess SID instead of the orchestrator SID — the canonical 2026-04-28 failure mode where the agent reached for the brute-force-marker anti-pattern (139 markers in one session). The two-tier procedure preserves audit-trail integrity (Step 2 grep DID run for THIS ticket creation) and explicitly forbids the brute-force pattern at both surfaces (durable in SKILL.md, just-in-time in hook deny hint). Auto-supersedes when P142 (P124 Phase 4) ships and the helper returns the runtime hook SID reliably; the SKILL.md sub-block carries an HTML supersession comment paired with a CI-enforced bats invariant so the cleanup becomes a CI-fail signal once P142's resolution ADR is `accepted`.
