# AFK and Subprocess Iteration — Archive

Older entries archived from `afk-subprocess.md` per ADR-040 Tier 3 budget rotation (split-by-date, P145). Load alongside the parent file for full historical context.

## Archived 2026-06-08 — entries first-written 2026-05-17 / 2026-05-18

- **A gate-class hook released mid-AFK-loop is ineffective for the immediate-next iter** — the iter subprocess loads the pre-release cached plugin version (compounds with `claude plugin install` no-op-when-already-installed). Workaround: `/install-updates` between `release:watch` and next-iter dispatch. (verifying P232 / P233; closed P106 / P147) <!-- signal-score: +2 | last-classified: 2026-05-25 | first-written: 2026-05-17 -->

- **Orchestrator main-turn mid-loop `AskUserQuestion` between iters is forbidden per ADR-044**, even for next-iter target picking — WSJF + ticket-state + tie-break ladder have framework-resolved the selection; asking sub-contracts framework work back. The load-bearing fix is a Phase-2b structural hook (UserPromptSubmit/Stop detecting AskUserQuestion in mechanical-stage zones), beyond the per-skill refactor. (verifying P130 / P132) <!-- signal-score: +2 | last-classified: 2026-05-25 | first-written: 2026-05-17 -->

- **Subprocess dispatch via Bash `run_in_background=true` with `&` kills the subprocess on parent exit** (backgrounded shell HUPs undetached children → 0-byte JSON). Working pattern: put the ENTIRE dispatch+poll loop (`claude -p` + `while kill -0 $ITER_PID` poll + `wait` + cost echo) into ONE shell script run via `run_in_background=true` — the script lives long enough to keep the subprocess attached. <!-- signal-score: +2 | last-classified: 2026-05-25 | first-written: 2026-05-18 -->

## Archived 2026-06-08 — duplicate-of-hooks-and-gates.md entry

- **The runtime-SID create-gate marker (ADR-050) DOES race in the backgrounded work-problems shape** — orchestrator main-turn captures fire PreToolUse hooks concurrently with the iter subprocess; both clobber the per-project runtime-sid marker (last-writer-wins) ⇒ `get_current_session_id` returns the wrong SID ⇒ P119 Write deny. If you hit a P119 deny on a mid-loop ticket Write, it's this known race. Workaround: spam-write `/tmp/manage-problem-grep-<sid>` under recent `/tmp/<system>-announced-*` UUIDs + the runtime-sid value. ADR-050 amended-in-place 2026-05-26 (Option C bounded multi-UUID marker-write = mitigation); impl tracked at P260. <!-- signal-score: +2 | last-classified: 2026-05-26 | first-written: 2026-05-26 -->

## Archived 2026-06-10 — Tier 3 rotation (afk-subprocess.md OVER 5120 budget after P358 socket-closed bullet added)

- **Step 0 session-continuity detection has no freshness filter on `.afk-run-state/iter-*.json` is_error markers** — the dir is gitignored and accumulates per-session forever; an iter-4-p246.json with `is_error: true` written 2026-05-18 still fired the Step 0 halt/ask gate on 2026-05-30 (12 days later, P246 verified-closed in the meantime). Workaround: agent reads the marker's mtime + the related ticket's current state and silently proceeds when both signals point to stale-not-load-bearing. Captured as P333. (session 8 opener) <!-- signal-score: 0 | last-classified: 2026-05-30 | first-written: 2026-05-30 -->

## Rotated 2026-06-27 (Tier-3 split-by-date — score-0 dated entry from afk-subprocess.md, P314 iter)

- **`API Error: The socket connection was closed unexpectedly` is a THIRD subprocess failure class — `is_error: true` with no staged work, P261 salvage does not apply.** Distinct from P261 (stream-idle-timeout, staged work survives), P147 (SIGTERM stuck-before-emit, 0-byte JSON), and P121 (SIGTERM idle-timeout, subprocess had committed). The socket-closed exit produces a coherent `.afk-run-state/iter-*.json` (metadata + cumulative cost preserved per Step 5 Authority Hierarchy) but no staged or committed files. Observed 2x consecutively in 2026-06-10 work-problems session at 9 + 23 turns — both well under the SIGTERM 3600s threshold, so the idle-timeout mechanism did NOT fire (subprocess exited on its own). Orchestrator main-turn is unaffected; the failure path is specific to `claude -p` subprocess transport. No documented retry policy yet — see P358 for investigation. (new ticket P358 captured 2026-06-10) <!-- signal-score: 0 | last-classified: 2026-06-10 | first-written: 2026-06-10 -->
