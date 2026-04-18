---
"@windyroad/itil": minor
---

Add `wr-itil:work-problems` AFK batch orchestrator skill and document a commit-gate fallback in `wr-itil:manage-problem` (JTBD-006).

- **New skill** `wr-itil:work-problems` — loops through ITIL problem tickets by WSJF priority, delegating each iteration to `wr-itil:manage-problem` non-interactively. Stops gracefully when nothing remains actionable. Emits `ALL_DONE` sentinel for external detection. Deterministic Step 4 classification rules (skip known-errors with Fix Released; work everything else).
- **Fix** `wr-itil:manage-problem` commit gate now documents a two-path delegation (closes P035). Primary: delegate to `wr-risk-scorer:pipeline` subagent-type via the Agent tool. Fallback: invoke `/wr-risk-scorer:assess-release` via the Skill tool when the subagent-type is unavailable (e.g., when `manage-problem` is itself running inside a spawned subagent). Per ADR-015 both produce equivalent bypass markers. Non-interactive fail-safe preserved for the risk-above-appetite branch only — silent-skip for delegation-unavailable is no longer sanctioned.
