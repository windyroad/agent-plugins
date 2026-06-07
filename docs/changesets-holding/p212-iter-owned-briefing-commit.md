---
"@windyroad/itil": patch
---

fix(itil): work-problems iter owns BRIEFING commit instead of orchestrator hand-off (closes P212)

`packages/itil/skills/work-problems/SKILL.md` Step 5 retro-on-exit clause #4 replaces the factually-wrong "run-retro commits its own work per ADR-014" assertion with the correct contract: run-retro is explicitly out-of-scope per ADR-014's Scope section, so the iter subprocess (not run-retro, not the orchestrator main turn) is responsible for committing any `docs/BRIEFING.md` / `docs/briefing/*.md` edits run-retro makes — staged + scored via `wr-risk-scorer:pipeline` + committed as `chore(briefing): refresh from iter retro (P<NNN>)`. Step 6.75's dirty-state classification table is amended in parallel: dirty BRIEFING-at-iter-exit is now a bug class, not an expected hand-off the orchestrator absorbs.

Same number of commits per iter — the audit trail is preserved. The second `wr-risk-scorer:pipeline` invocation MOVES from expensive orchestrator-main-turn context to cheaper iter-subprocess context, eliminating the per-iter main-turn cost the ticket flagged. SKILL-prose only — no changes to run-retro SKILL.md, no changes to manage-problem, no ADR amendment.
