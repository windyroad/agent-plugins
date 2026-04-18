---
"@windyroad/retrospective": patch
---

retrospective: run-retro recommends new skills for recurring workflows (P044)

The run-retro skill previously routed every observed friction into either
BRIEFING.md notes or problem tickets. It had no branch for the third valid
output: codifying a recurring multi-step workflow as a new skill.

Changes to `packages/retrospective/skills/run-retro/SKILL.md`:

- Step 2 gains a skill-candidate reflection category: "What recurring
  workflow did I (or the assistant) perform that would be better as a
  skill?" with criteria (multiple invocations, deterministic sequence,
  cross-project reuse) and examples distinguishing skill candidates from
  problem tickets and BRIEFING notes.
- New Step 4b (Recommend new skills) walks each candidate through an
  `AskUserQuestion` per ADR-013 Rule 1 with three options: create a new
  skill (record suggested name, scope, triggers, prior uses), track as a
  problem ticket, or skip. Non-interactive fallback per ADR-013 Rule 6:
  record candidates as "flagged — not actioned" so they remain visible.
- Step 5 summary gains a "Skill Candidates" slot so recommendations
  appear alongside BRIEFING changes and problem tickets in the session
  audit.

Scaffolding itself is deferred — the skill records candidates only.

Adds `packages/retrospective/skills/run-retro/test/run-retro-skill-candidates.bats`
(10 assertions) covering Step 2 category, Step 4b branch, ADR-013
compliance, Rule 6 fallback, and Step 5 summary slot.

Closes P044 pending user verification.
