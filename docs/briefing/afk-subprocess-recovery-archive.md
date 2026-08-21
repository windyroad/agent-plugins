# AFK Subprocess Recovery — Archive

Date-stratified archive of `afk-subprocess-recovery.md` (Tier-3 budget rotation per P145/P247, split 2026-05-26). Oldest recovery-discipline entries; load alongside the primary file when full historical context is needed.

## What Will Surprise You (archived)

- **User can escalate from AFK-stop-condition-#2 to interactive AskUserQuestion by asking.** The orchestrator's default in AFK mode is an "Outstanding Design Questions" table (ADR-013 Rule 6 — the persona is away). When the user returns mid-session, they can reply "ask me the questions" and the questions are batched live (cap 4 per call, multiple batches OK) — far faster than asynchronous loop round-trips. (verifying P103)

- **When release risk is ABOVE appetite and the scorer emits a `RISK_REMEDIATIONS:` block, the orchestrator MUST auto-apply remediations incrementally — not escalate to `AskUserQuestion`.** The scorer suggests; the agent decides. Flow: extract `RISK_REMEDIATIONS`, read the suggestions, apply, re-score, drain if now within appetite — else emit the Outstanding Design Questions table per ADR-013 Rule 6. Extends "act on obvious decisions" into the above-appetite release-cadence surface. (verifying P103)

- **Iteration-worker subagents can call `ScheduleWakeup` and abandon the synchronous-completion contract** (return "waiting for the wake-up" instead of `ITERATION_SUMMARY`; a `.claude/scheduled_tasks.lock` appears). On a Step 6.75 dirty-for-unknown halt, inspect the uncommitted work first — it may be cosmetic (shippable; advance as recovery) or broken (`git restore` + reopen the slice). (verifying P083)

> Archived 2026-08-21 (P099 Tier 3 rotation, split-by-date safe default) to bring `afk-subprocess-recovery.md` back under budget after the P508 salvage witness landed. Still current — P083 is restated in `CLAUDE.md` and the `work-problems` SKILL iter-prompt, which are the surfaces that actually bind an iteration.
