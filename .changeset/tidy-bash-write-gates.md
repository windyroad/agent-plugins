---
"@windyroad/architect": patch
"@windyroad/jtbd": patch
"@windyroad/style-guide": patch
"@windyroad/voice-tone": patch
"@windyroad/tdd": patch
---

Route literal Bash output redirections and tee targets through the existing edit gates and post-write hooks. Read-only commands remain silent. Dynamic targets, control structures, in-process writes, and unknown output content remain outside this partial fix.
