---
"@windyroad/retrospective": minor
---

run-retro: generalise codification branch from skills to 12 shapes (P050)

- **Step 2** superseded from "recurring workflow ... as a skill" to "recurring pattern ... better codified", with a shape sub-list naming 12 shapes (skill, agent, hook, settings, script, CI step, ADR, JTBD, guide, problem, test fixture, memory). "Skill" is retained as one worked example so the P044 muscle memory survives.
- **Step 4b** now uses a single `AskUserQuestion` with flat shape-prefixed options (`Skill — create stub`, `Agent — create stub`, `Hook — create stub`, `ADR — invoke create-adr`, `JTBD — invoke update-guide`, ...). Dedicated codification skills are routed to rather than duplicated (`wr-architect:create-adr`, `wr-jtbd:update-guide`, `wr-voice-tone:update-guide`, `wr-style-guide:update-guide`, `wr-risk-scorer:update-policy`, `wr-itil:manage-problem`). Fallback to a two-question flow is documented for Claude Code versions where option-count limits bite.
- **Step 4b non-interactive fallback (ADR-013 Rule 6)** extended: records each candidate as `flagged — not actioned (non-interactive)` with the identified Shape in the Step 5 summary.
- **Step 5 summary** uses a unified "Codification Candidates" table with `Shape | Suggested name | Scope | Triggers | Decision` columns. Empty-table-omit rule retained.
- **Backward compatibility**: `run-retro-skill-candidates.bats` assertions updated in place to accept either P044 phrasing or P050 phrasing. "Skill" remains a worked example in Step 2's shape list.
- New parallel bats `run-retro-codification-candidates.bats` — 9 assertions covering the generalised surface. All 19 run-retro assertions GREEN.

Deferred: P051 (improvement-axis sibling) — the shape taxonomy established here is the base for P051's extension.
