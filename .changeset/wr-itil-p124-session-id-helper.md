---
"@windyroad/itil": patch
---

manage-problem: Step 2 substep 7 now sources the new agent-side session-ID discovery helper (`packages/itil/hooks/lib/session-id.sh`) instead of the brittle `${CLAUDE_SESSION_ID:-default}` fallback that wrote the create-gate marker under the wrong UUID and triggered a Write deny on every first ticket of a session (P124).

`get_current_session_id` returns the canonical session UUID by reading `CLAUDE_SESSION_ID` if exported, else by scraping the most-reliable per-session announce marker (`/tmp/<system>-announced-<UUID>`, set on prompt 1 of every session per ADR-038 by architect / jtbd / tdd / style-guide / voice-tone / itil-assistant-gate / itil-correction-detect). It exits non-zero when no session can be discovered so callers can `&&`-chain the marker write and never land an empty-UUID `/tmp/manage-problem-grep-` file the hook will never match.

Selection order is fixed (architect first, then jtbd / tdd / itil-assistant-gate / itil-correction-detect / style-guide / voice-tone) so discovery is deterministic and reproducible across invocations. Announce markers are write-once-per-session per ADR-038 — no mtime sliding (unlike `-reviewed-` gate markers which `touch`-refresh on every gate check per ADR-009 + P111), so the helper sidesteps the multi-session `/tmp` mtime-fragility flagged in architect review.

The skill now calls the existing `mark_step2_complete` helper from `create-gate.sh` for the marker write itself — single source of truth for the marker-path convention.

6 behavioural bats assertions in `packages/itil/hooks/test/session-id.bats` pin the contract per ADR-037 + P081 (env-var fast path, env-var ignores markers, architect-marker scrape, jtbd-marker fallback, no-markers empty+non-zero exit, deterministic priority order). Helper is itil-local for now (only manage-problem needs agent-side SID discovery today); promote to `packages/shared/` per ADR-017 if a second skill adopts the pattern.

ADR-038 Related cross-references the new helper as the agent-side READ companion to its hook-side WRITE helpers.
