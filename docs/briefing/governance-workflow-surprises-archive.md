# Governance Workflow — Surprises Archive

Entries rotated out of `governance-workflow-surprises.md` per the Tier 3 budget Branch B split-by-date discipline (P099/P145). Load alongside the live file when full historical context is needed.

## Archived 2026-07-05 (P345 iter retro)

- **Skill-creator eval subagents can hit rate limits mid-batch.** Spawning 6 parallel subagents risks 2-3 failing with "You've hit your limit". Run fewer in parallel, or grade what lands. <!-- signal-score: 1 | last-classified: 2026-05-25 | first-written: 2026-05-03 -->
- **Anthropic's official `skill-creator` skill ships a mature eval harness** (evals.json + dual-run with-skill/baseline + grader subagent + aggregate_benchmark + HTML viewer) — directly applicable to testing our SKILL.md documents. See P012. <!-- signal-score: 2 | last-classified: 2026-05-25 | first-written: 2026-05-03 -->
