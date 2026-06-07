---
"@windyroad/itil": patch
---

P210: switch canonical AFK-fallback marker write-form from em-dash (`—`) to ASCII (` -- `) across the four upstream-report-flow SKILLs (`work-problems`, `manage-problem`, `transition-problem`, `transition-problems`). Consumers parsing the marker no longer need unicode-normalisation branches. The legacy em-dash variant remains matched by the already-noted check for backward compatibility with prior-session ticket bodies. Convention documented inline at the marker-write sites: ASCII-only in machine-parseable identifiers; em-dash permitted in pure narrative prose.
