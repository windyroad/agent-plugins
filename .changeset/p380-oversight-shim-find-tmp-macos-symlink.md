---
"@windyroad/architect": patch
"@windyroad/jtbd": patch
"@windyroad/itil": patch
---

Fix candidate-session-SID enumeration on macOS, where `/tmp` is a symlink to `/private/tmp` (P380). The `find "$MARKER_DIR" -maxdepth 1 -name '*-announced-*'` invocation runs in `find`'s default `-P` mode, which refuses to descend a start-point that is itself a symlink — so on macOS the enumeration silently returned zero candidates and the substance-confirm marker write produced zero markers (silent cold-path exit 0). The downstream `*-oversight-marker-discipline.sh` PreToolUse hook then blocked the `human-oversight: confirmed` edit, surfacing a misleading "you didn't run mark-oversight-confirmed" error when the shim did run.

The fix adds the `-L` (follow-symlink) flag to the three affected enumerations — `packages/architect/scripts/mark-oversight-confirmed.sh`, `packages/jtbd/scripts/mark-oversight-confirmed.sh`, and `packages/itil/hooks/lib/session-id.sh` (`get_candidate_session_ids`, the ADR-050 multi-SID enumeration). `-L` is a no-op on Linux (real `/tmp`) and resolves `/tmp`→`/private/tmp` on macOS. Behavioural bats fixtures point `SESSION_MARKER_DIR` at a symlinked marker dir (reproducing the macOS `/tmp` shape on any platform) and are red without the flag, green with it.
