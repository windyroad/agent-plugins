---
"@windyroad/retrospective": minor
---

Extend run-retro's codification branch with an **improvement axis** for existing
skills, agents, hooks, ADRs, and guides (P051).

- Step 2 gains an improvement-shaped reflection category alongside the
  creation-shaped category introduced by P044/P050.
- Step 4b's single flat `AskUserQuestion` option list adds six improvement-axis
  options (`Skill — improvement stub`, `Agent — improvement stub`, `Hook —
  improvement stub`, `ADR — supersede or amend`, `Guide — improvement edit`,
  `Problem — edit existing ticket`). All 12 creation options from P050 retained.
- P016/P017 concern-boundary splitting reused for multi-concern improvements;
  ≥ 3 improvements per output prefers a coordinating ticket over N separate ones.
- Step 5 Codification Candidates table adds a `Kind` column (`create` /
  `improve`); non-interactive fallback records `Kind:` alongside `Shape:`.
- 5 structural bats assertions added to
  `run-retro-codification-candidates.bats`; full run-retro test surface 24/24
  green, full project suite 246/246 green.
