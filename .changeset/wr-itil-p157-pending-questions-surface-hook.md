---
"@windyroad/itil": minor
---

P157: ship `itil-pending-questions-surface.sh` SessionStart hook — auto-surface accumulated `outstanding_questions` from `.afk-run-state/outstanding-questions.jsonl` at session start when user returns interactive

Closes the queue-file lifecycle gap — accumulated `outstanding_questions` entries from `.afk-run-state/outstanding-questions.jsonl` (written between iters by `/wr-itil:work-problems` per the P135 Phase 3 schema + ADR-044 6-class taxonomy) now surface deterministically on session start when the user returns from an AFK loop that halted before its Step 2.5 / Step 2.5b emit point (manual stop, quota exhaustion, network failure).

Third and final ADR-032 child of P014 (master tracker) — sibling to P155 (`/wr-itil:capture-problem`) and P156 (`/wr-architect:capture-adr`) shipped earlier in the same AFK loop.

**What ships**

- New SessionStart hook `packages/itil/hooks/itil-pending-questions-surface.sh` — parses JSONL queue via `jq -e .` (malformed lines silently skipped per defensive SessionStart-must-not-block-startup contract); dedupes on `(rank, category, ticket_id, question)` tuple; ranks per ADR-044 6-class taxonomy precedence (deviation-approval > direction > one-time-override > silent-framework > taste > correction-followup); emits markdown directive listing entries plus an explicit cleanup directive for the agent to rewrite the queue file with resolved entries removed after each `AskUserQuestion` batch; emits a batching note when entry count > 4 citing the ADR-013 Rule 1 `<=4 per call` cap. Silent-on-no-content per ADR-040 Mechanism step 1 (missing / empty / whitespace-only / all-malformed → exit 0 with zero stdout).
- Wired into `packages/itil/hooks/hooks.json` as a second SessionStart entry with matcher `"startup"` (mirrors `wr-retrospective` `session-start-briefing.sh` ADR-040 Option A precedent — Option B's `UserPromptSubmit` + once-per-session marker rejected on the same reasoning: SessionStart is the semantically correct event for boot-time artefact surfaces).
- AFK-iter cross-context-leak prevention via `WR_SUPPRESS_PENDING_QUESTIONS=1` env-var self-suppress (architect's implementation choice (a) of the two ADR-032 line 127 enumerations — simpler than orchestrator-side queue drain/restore, idempotent, no state to restore on crash). The `/wr-itil:work-problems` Step 5 dispatch block exports the env var immediately before each `claude -p` subprocess spawn so the orchestrator-session queue does not leak into iter subprocess contexts.
- ADR-032 amended with new section `### Pending-questions-surface variant — JSONL queue at SessionStart (P157 amendment, 2026-05-03)` between the P156 amendment and Scope. Disambiguates the two pending-questions surfaces (markdown variant `pending-questions-surface.sh` UserPromptSubmit per ADR-032 line 169 for paused-background-subagent-state tokens; JSONL variant `itil-pending-questions-surface.sh` SessionStart for AFK-loop-accumulated queue), names ADR-040 Option A precedent + ADR-044 6-class precedence, documents the two-hook split + the env-var self-suppress contract; variant-selection precedence pinned (SessionStart-JSONL is LEAD post-P157 for AFK-loop direction-question surfacing across session boundaries; markdown UserPromptSubmit remains LEAD for paused-subagent-state tokens).
- 19 behavioural bats `packages/itil/hooks/test/itil-pending-questions-surface.bats` per ADR-052 — silent-on-no-content × 3, surfacing × 2, full 6-class precedence ranking × 2, dedup × 2, batching × 2, cleanup directive × 1, env-var self-suppress × 2, hooks.json wiring × 1, work-problems Step 5 export ordering × 1, malformed-JSON skip × 2, exists × 1. 19/19 green.

**Empirical evidence**

This very session sat 16 hours with 9 accumulated entries that only surfaced because the user explicitly asked. With this hook those entries surface deterministically on the next session start. End-to-end dogfood against the real 9-entry queue ranks 1× deviation-approval (P154) first, 6× direction (BRIEFING_TIER3 / P014 / P156×3 / P160) next, 2× silent-framework (P154×2) last; batching note fires (9 > 4); cleanup directive present.

**Verdicts**

Architect: PASS-WITH-NOTES (8 actionable items folded in — ADR-040 cited over ADR-045 for SessionStart-specific silent-on-no-content; env-var self-suppress per implementation choice (a); ADR-032 amendment over new ADR; explicit cleanup directive in additionalContext text; work-problems Step 5 export of the env var alongside the hook ship; behavioural bats includes WR_SUPPRESS_PENDING_QUESTIONS=1 case; ADR-040 plain-stdout shape over additionalContext-keyed JSON; cross-reference ADR-040 Mechanism step 1 not ADR-045 Pattern 1).

JTBD: PASS — JTBD-006 primary (Progress the Backlog While I'm Away — closes "queued for my return, not guessed at" desired-outcome gap by making the queue surface deterministically on return rather than only when Step 2.5 fires); JTBD-001 secondary (direction-class observations resolve before user begins foreground work, preserving 60-second-flow promise); JTBD-101 tertiary (extends the suite via reusable SessionStart-JSONL pattern).

Closes the ADR-032 child trio. P014 master-tracker now has all three children fix-released this AFK loop.

Closes P157
