---
"@windyroad/architect": patch
"@windyroad/itil": patch
"@windyroad/jtbd": patch
"@windyroad/tdd": patch
"@windyroad/risk-scorer": patch
"@windyroad/style-guide": patch
"@windyroad/voice-tone": patch
---

Add the quota-pace throttle (P160 / ADR-093 / RFC-046). Every plugin now ships a `quota-pace-throttle.sh` PreToolUse hook that, before each tool call, compares cumulative 5h/7d rate-limit usage against elapsed time and — when ahead of the proportional pace — sleeps a calculated catch-up (capped 60s per firing, 5pp weekly headroom). Behind pace it is a fast no-op (recent-check marker dedups the per-plugin firing). It never blocks, never prompts, and fails open when the `~/.claude/quota-state.json` cache (written by the statusline) is absent/malformed. This paces token burn evenly across ALL work — interactive and AFK — so an overnight loop lands at each quota reset with headroom instead of a mid-flight hard-stop. See `packages/shared/hooks/QUOTA-THROTTLE-SETUP.md` for the one-line statusline cache-writer adopters add.
