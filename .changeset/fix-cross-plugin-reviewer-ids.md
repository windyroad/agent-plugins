---
"@windyroad/architect": patch
"@windyroad/jtbd": patch
"@windyroad/style-guide": patch
"@windyroad/voice-tone": patch
---

Persist Codex reviewer results when a completion reports a runtime agent ID instead of the task name returned at spawn. The fallback requires one matching reviewer registration in the same parent session and checkout; ambiguous completions remain blocked.
