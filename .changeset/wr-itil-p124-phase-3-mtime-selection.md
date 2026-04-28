---
"@windyroad/itil": patch
---

P124 Phase 3 — `packages/itil/hooks/lib/session-id.sh::get_current_session_id` within-system selection changed from first-glob-match (alphabetical) to most-recent-mtime (`ls -t | head -1`). Phase 2's portability fix (the for-loop existence check that replaced bash-only `shopt -s nullglob`) is preserved; Phase 3 layers mtime selection on top of it.

Why Phase 2 alone wasn't enough: glob expansion under both bash and zsh enumerates matches in ASCII-alphabetical order by default. Phase 2's "first match wins" inner loop returned the alphabetically-first present marker. On a developer machine accumulating one `${system}-announced-${SID}` marker per past session in /tmp (observed 103 stale architect markers in a single regression run on 2026-04-28), the alphabetically-first UUID was a stale prior-session UUID. Helper returned a wrong SID; the create-gate hook (P119) read the live SID from its stdin JSON and denied the Write; recovery required brute-touching `manage-problem-grep-` for every known SID (81–103 markers per recovery in evidence).

Phase 3 fix: within-system selection switches to most-recent-mtime via `ls -t "${marker_dir}/${system}-announced-"* 2>/dev/null | head -1`. `-announced-` markers per ADR-038 are write-once-per-session (no `touch`-refresh, no sliding TTL — unlike `-reviewed-` markers governed by ADR-009 + P111), so mtime IS the announcing session's first-prompt timestamp. Newest mtime within a single system's `-announced-` glob unambiguously identifies the live session. The outer system priority loop (architect → jtbd → tdd → itil-assistant-gate → itil-correction-detect → style-guide → voice-tone) is preserved verbatim.

`packages/itil/hooks/test/session-id.bats` gains one new behavioural assertion per ADR-037 + P081: write three architect-announced markers with controlled mtimes (`sleep 1` between writes) where the alphabetically-first UUID has the OLDEST mtime; assert helper returns the newest-mtime UUID, not the alphabetical-first. Phase 2's existing 7 assertions remain green; suite is now 8/8.
