---
"@windyroad/itil": patch
---

Run Codex backlog iterations in isolated Codex CLI processes

The Codex backlog drain can now use available Codex CLI capacity while keeping
each problem in its own governed process. Progress metadata and the final
iteration summary use separate structured output channels, and the existing
Claude Code workflow is unchanged.
