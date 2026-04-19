---
"@windyroad/itil": minor
---

Surface outstanding design questions at work-problems stop-condition #2 (P053).

- Step 2 branches on stop-condition: #2 now routes to a new Step 2.5 before
  emitting `ALL_DONE`; #1 and #3 keep the direct-emit behaviour.
- Step 2.5 extracts user-answerable questions from skipped tickets. In
  interactive invocations, batches up to 4 into one `AskUserQuestion` call
  per ADR-013 Rule 1 (Anthropic's documented per-call cap). In
  non-interactive / AFK invocations (the JTBD-006 persona default), emits
  an `### Outstanding Design Questions` table in the post-stop summary
  per ADR-013 Rule 6 fail-safe.
- Step 4 classifier gains a skip-reason taxonomy column:
  `user-answerable` / `architect-design` / `upstream-blocked`. Step 2.5
  selects the user-answerable subset to surface.
- Output Format template includes an `### Outstanding Design Questions`
  section (Ticket / Question / Context), emitted only when
  stop-condition #2 fires with ≥1 user-answerable skip.
- Non-Interactive Decision Making table documents the AFK-default path.
- 7 structural bats assertions added in
  `work-problems-stop-condition-questions.bats`; full project suite
  253/253 green (+7).
