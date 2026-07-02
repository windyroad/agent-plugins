---
"@windyroad/architect": patch
"@windyroad/jtbd": patch
---

The `mark-oversight-confirmed` shims now print a clear diagnostic when they cannot discover a session id (no `CLAUDE_SESSION_ID` and no session announce markers), instead of exiting silently. The message names why no oversight marker was written and how to remedy it, so the follow-on oversight-marker-discipline hook deny is self-explanatory rather than a dead end. Exit code stays 0, so existing skill flows are unaffected (P368).
