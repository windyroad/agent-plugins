---
"@windyroad/itil": patch
---

P124 Phase 2 — `packages/itil/hooks/lib/session-id.sh::get_current_session_id` is now zsh-portable. The Phase 1 implementation used `shopt -s nullglob` (a bash builtin) inside a subshell; under zsh — the agent's actual interactive shell on macOS — this errored with `command not found: shopt` and let the subshell glob expression fall through to a literal unmatched-pattern string, returning a wrong/stale UUID. Citation: ticket "Regression Evidence (2026-04-27)", main-turn P130 capture line 119: `get_current_session_id:33: command not found: shopt`. Recovery required brute-forcing 81 marker files for one ticket creation.

Phase 2 replaces the `shopt`-subshell with a portable `for f in "${marker_dir}/${system}-announced-"*; do [ -e "$f" ] || continue; marker="$f"; break; done` existence-check loop. Identical behaviour under bash, zsh, and POSIX dash. The fixed marker-system priority order (architect → jtbd → tdd → itil-assistant-gate → itil-correction-detect → style-guide → voice-tone) is preserved verbatim from Phase 1. The `&&` short-circuit empty-SID contract preserved (no `/tmp/manage-problem-grep-` empty-tail file ever created).

`packages/itil/hooks/test/session-id.bats` gains one new behavioural assertion per ADR-037 + P081: helper invoked under `zsh -c` returns the same UUID as under `bash -c`, exits 0, emits no `shopt: command not found` on stderr. Existing 6 Phase 1 assertions remain green; suite is now 7/7. Test skips cleanly if `zsh` is not on PATH.

Architect verdict (PASS, advisory): Phase 2 implements only the `shopt` portability fix; the ticket's "Fix Strategy (Phase 2)" section also named a glob-ordering ASCII→mtime fix, but that is intentionally not in Phase 2 scope — Phase 1's switch to `-announced-` markers + the system-priority discipline already supersedes the mtime-sort idea (see Phase 1 architect refinement on `-reviewed-` marker fragility under ADR-009 sliding TTL + P111).

JTBD alignment confirmed (jtbd-lead PASS): JTBD-001 (Enforce Governance Without Slowing Down) primary — eliminates the 81-marker brute-force recovery cost on first ticket creation per session. JTBD-006 (Progress the Backlog While I'm Away) composes — AFK loops creating tickets mid-iter no longer risk wedging on Step 2 deny.
