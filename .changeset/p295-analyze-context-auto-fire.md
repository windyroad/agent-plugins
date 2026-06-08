---
"@windyroad/retrospective": minor
---

ADR-043 Amendment 2026-06-08 (P295): the deep context-analysis layer (`/wr-retrospective:analyze-context`) now auto-fires from `run-retro` Step 2c (cheap layer) when the combined whichever-comes-first trigger holds — calendar-elapse >14 days since the most recent `docs/retros/*-context-analysis.md` OR delta >20% in any bucket since the prior snapshot. Once-per-day guard via `docs/retros/<TODAY>-context-analysis.md` presence prevents re-fire. Identical behaviour in interactive and AFK modes (the deep layer is silent — never invokes `AskUserQuestion`; it writes a committed report).

Settles the on-demand-only gap from the user-pinned principle: "if there is no automatic cadence, it does not happen."

- Both `run-retro/SKILL.md` and `analyze-context/SKILL.md` flipped (3 prose sites + frontmatter description) to reflect the auto-fire contract; the supersession-guard bats assertions enforce that the prior "Never auto-fires" prose does not regress.
- Adopters running `/wr-retrospective:run-retro` get the auto-fire on the first retro after upgrade when the trigger holds; no manual invocation needed.
