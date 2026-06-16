---
"@windyroad/voice-tone": patch
"@windyroad/risk-scorer": patch
---

External-comms gate: voice-tone skips commit messages

The voice-tone external-comms gate used to fire on `git commit -m` and require a subagent review. The voice-and-tone policy already excludes commit messages, so every review passed without doing any work and wasted a round-trip. The gate now reads a per-package `EXTERNAL_COMMS_SKIP_SURFACES` setting and silently passes any surface a policy disclaims. Voice-tone skips commit messages; risk-scorer still scans them for leaked credentials. (P360)
