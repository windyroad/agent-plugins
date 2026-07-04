---
"@windyroad/architect": patch
"@windyroad/itil": patch
"@windyroad/jtbd": patch
"@windyroad/tdd": patch
"@windyroad/risk-scorer": patch
"@windyroad/style-guide": patch
"@windyroad/voice-tone": patch
---

Add a plugin-staleness surfacer (RFC-036 / ADR-088). Each plugin now ships a `UserPromptSubmit` hook that, once per turn, compares the running session's plugin version against the highest version installed on disk and — when the session is behind — prints one advisory line telling you to restart to pick up the newer code. The check is network-free, warn-only (it never installs or restarts), stays silent when the session is current, and emits at most once per newly-detected version. This surfaces the case where a fix lands mid-session (via `/install-updates`, a release, or an AFK loop) but the running session keeps executing the old code.
