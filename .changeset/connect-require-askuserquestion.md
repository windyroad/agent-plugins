---
"@windyroad/connect": patch
---

Setup skill now requires AskUserQuestion tool (no plain-prompt fallback). If the tool is unavailable, the skill stops and asks the user to restart Claude Code.
