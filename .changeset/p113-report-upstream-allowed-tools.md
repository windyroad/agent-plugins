---
"@windyroad/itil": patch
---

P113: declare `Skill, Agent` in `wr-itil:report-upstream` allowed-tools

The `report-upstream` skill body (`packages/itil/skills/report-upstream/SKILL.md` Step 9 / line 330) invokes the `wr-risk-scorer:pipeline` subagent (requires the `Agent` tool) and falls back to `/wr-risk-scorer:assess-release` per ADR-015 (requires the `Skill` tool). Neither was declared in the SKILL.md frontmatter `allowed-tools` field. `report-upstream` was the only itil skill that declared `AskUserQuestion` without also declaring `Skill` — and the only itil skill missing from Claude Code's TUI slash-command autocomplete despite being present in the agent-side skill enumerator.

Candidate mechanism (to confirm post-release per the verification path on P113): Claude Code's TUI autocomplete appears to validate declared-vs-used tools in skill frontmatter and silently drop skills whose bodies invoke tools not declared in `allowed-tools`, while the server-side enumerator (which populates the agent's available-skills list) is more lenient. If the hypothesis holds, adding `Skill, Agent` restores `/wr-itil:report-upstream` to the autocomplete surface without changing runtime behaviour. If the hypothesis is wrong, P113 reopens for upstream escalation to Anthropic.

Closes P113 → Verification Pending.
