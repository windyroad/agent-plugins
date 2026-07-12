---
"@windyroad/cruise": patch
---

Ship cruise's hooks executable. Both hooks — the PreToolUse throttle and the SessionStart statusline producer — were tracked at git mode 644, so Claude Code's direct invocation was refused with "Permission denied" on every firing and the throttle did no pacing. It failed open, so the plugin installed cleanly but was silently inert. They now ship at mode 755. A CI guard (`check:executable-modes`) asserts every plugin entrypoint is tracked executable so this cannot recur.
