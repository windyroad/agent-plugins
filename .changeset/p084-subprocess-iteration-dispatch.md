---
"@windyroad/itil": minor
---

P084 fix: `/wr-itil:work-problems` Step 5 dispatches iterations via a `claude -p` subprocess instead of Agent-tool-spawned `general-purpose` subagents.

**Why:** Agent-tool-spawned subagents do NOT have the Agent tool in their own surface (platform restriction; three-source evidence — ToolSearch probe, Claude Code docs, empirical runtime error). Without Agent, the iteration worker could not satisfy architect + JTBD PreToolUse edit-gate markers (only settable via Agent-tool PostToolUse hook) nor the risk-scorer commit gate. Every AFK iteration on a gate-covered path (`packages/`, ADRs, SKILL.md edits, hook edits) silently halted. The subprocess variant is a full main Claude Code session with Agent available, so governance reviews run at full depth and gate markers set natively.

**Dispatch command:** `claude -p --permission-mode bypassPermissions --output-format json <iteration-prompt>`.

**No per-iteration budget cap.** Per user direction, the AFK loop's natural stop condition is quota exhaustion, not an arbitrary dollar cap. A cap would halt iterations before quota is actually exhausted, leaving remaining backlog unprocessed. Quota-exhaust surfaces as a non-zero `claude -p` exit and the orchestrator halts cleanly per Step 6.75's exit-code handling.

**What stays the same:** the `ITERATION_SUMMARY` return-summary contract is preserved verbatim (orchestrator extracts from the JSON `.result` field instead of the Agent-tool return value). Step 0 preflight (ADR-019), Step 6.5 release-cadence drain (ADR-018), and Step 6.75 inter-iteration verification (P036) all remain in the orchestrator's main turn unchanged. Every non-Step-5 block in the skill is untouched.

**Adopter-tunable:** adopters with narrower permission scopes may substitute `--permission-mode acceptEdits` / `auto` / `dontAsk` for `bypassPermissions`. Adopters who genuinely need a per-iteration cap (multi-tenant billing, etc.) can add `--max-budget-usd` in their own fork — not the default.

See `docs/decisions/032-governance-skill-invocation-patterns.proposed.md` for the full subprocess-boundary sub-pattern contract (amendment dated 2026-04-21) and `docs/problems/084-work-problems-iteration-worker-has-no-agent-tool-so-architect-jtbd-gates-block.open.md` for the full diagnosis + probe evidence.
