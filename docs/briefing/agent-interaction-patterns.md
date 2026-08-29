# Agent Interaction Patterns

Cross-session learnings about the assistant's own interaction habits — framing-validation, re-stage traps, user-frustration signals, and the small rules that reduce wasted rounds.

> **Sibling brief**: gate-marker propagation, P119 / P122 / P124 helper bugs (P142 fix), and architect-agent gate visibility within AFK iteration subprocesses live in `agent-hook-gate-quirks.md` (split out 2026-05-03 per P145 MUST_SPLIT). Read alongside this file when debugging hook-deny chains.

- **A claim from a hook, a detector, a subagent, or a queue is NOT pre-verified — it is an assertion with a timestamp older than the artefact it describes.** Four instances on 2026-08-20, each one `Read` from falsification: a SessionStart queue entry claiming an ADR still said X (reconciled three weeks earlier, and the maintainer was asked to re-decide a settled question); `check-autocreate-rfc-scope.sh` reporting `under_scoped=7` relayed as a criterion "firing for real" (already ruled on 2026-07-03, and the detector cannot know that so it re-emits every retro); a reviewer's file count carried into an ADR 31 lines from the agent's own contradicting count; a hang-off pre-filter supplying an `open/` path for a `closed/` ticket. **Open the artefact before repeating what something else said about it.** (P434, third scope extension.) <!-- signal-score: 4 | last-classified: 2026-08-29 | first-written: 2026-08-21 -->
- **`test -d packages && grep -rl ... packages/` is a vacuous pass, not a guard.** The `&&` short-circuits: a missing root produces no output, which reads as "returns nothing" and passes — the exact failure the guard was added to prevent. Assert the root's existence as its OWN step, then plant a known-positive and assert it is FOUND, then assert the corpus is clean. A search that cannot find a planted match is broken regardless of what it reports. (2026-08-20, caught on ADR-119's Confirmation criterion.) <!-- signal-score: 0 | last-classified: 2026-08-29 | first-written: 2026-08-21 -->

## What Will Surprise You

> Older entries (3 archived 2026-05-31 + 1 × P302 decision-confirmation-prompts substance-first archived 2026-06-08) live in `agent-interaction-patterns-archive.md` for Tier 3 budget rotation. Load alongside this file for full history.

  <!-- signal-score: -2 | last-classified: 2026-08-29 | first-written: 2026-06-28 -->

  <!-- signal-score: -2 | last-classified: 2026-08-29 | first-written: 2026-06-11 -->

  <!-- signal-score: -2 | last-classified: 2026-08-29 | first-written: 2026-05-31 -->
