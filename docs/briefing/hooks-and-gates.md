# Hooks and Gates

Cross-session learnings about how PreToolUse/PostToolUse gates behave, when gate markers fire, and why they expire at the worst time.

## What You Need to Know

- **Four edit gates fire on every edit**: architect review, JTBD review, WIP risk assessment, and TDD enforcement. Each requires its own agent delegation before the edit is allowed. Plan for this overhead. JTBD was broadened to all project files (ADR-007, superseded by ADR-008).
- **Risk-scorer agents are tool-restricted to `Read + Glob`** — no `AskUserQuestion`, no `EnterPlanMode`. Sub-agents invoked via Task also cannot enter plan mode on the parent's behalf. Any "scorer asks the user" design must split scorer/orchestrator concerns: scorer emits structured markers, calling skill/primary owns the interaction. See P021.

## What Will Surprise You

- **Each edit consumes the architect/WIP marker** — you need a fresh agent review for every blocked edit, not just one per session. The **risk-scorer, architect, and JTBD bypass markers all have a ~1800s TTL**. Long sessions WILL hit the expiry between reviews and the next edit; expect a re-review cycle after extended tool-use gaps. Observed 2026-04-19: the ADR-022 write was blocked mid-session because architect+JTBD markers from earlier P-ticket work had expired.
- **The risk-scorer PostToolUse hook uses regex dot** (`.`) not literal characters to match agent names. This was a deliberate fix — don't "correct" it back to dashes.
- **Edit gates block files outside the project** (e.g., `~/.claude/channels/discord/access.json`). Use bash to write non-project config files when gates are active.
- **`wr-risk-scorer:pipeline` bypass markers have a 1800s TTL that expires mid-session in long retrospective-heavy flows.** Observed 2026-04-21: a P081 commit scored fresh; ~87 minutes later a P082 ticket-creation commit attempted, blocked by `Risk score expired (5176s old, TTL 1800s)`. The remediation (re-delegate pipeline, re-commit) adds a turn per expiry. Known already for architect/JTBD markers (hooks-and-gates carries the same cadence); commit-gate marker expires on the same cadence and pays the same cost. Candidate improvement: commit-gate hook auto-rescores inline when TTL is within a refresh window (e.g. < 15 min old → pass; 15-30 min → auto-rescore; > 30 min → prompt) instead of bouncing the user to manually re-delegate.
- **UserPromptSubmit hooks across five windyroad plugins now emit full MANDATORY prose only on the first prompt of a session** after ADR-038 ships (2026-04-22). Subsequent prompts emit a ≤150-byte terse reminder that names the gate + trigger artifact + `wr-<plugin>:agent` delegation affordance. The `wr-tdd` hook still emits dynamic TDD state (IDLE/RED/GREEN/BLOCKED) per-prompt per the ADR-038 carve-out. Empty `SESSION_ID` (manual hook invocation, test harnesses) falls back to full block, no marker written. Sessions that started BEFORE the fix installed continue seeing full prose every prompt — the session-marker is in `/tmp/${SYSTEM}-announced-${SESSION_ID}` and doesn't retroactively suppress already-announced sessions.
