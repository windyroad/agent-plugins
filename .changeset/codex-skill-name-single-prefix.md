---
"@windyroad/itil": patch
"@windyroad/architect": patch
"@windyroad/risk-scorer": patch
---

Codex skill names carry one plugin prefix, not two

Codex namespaces every skill by the plugin it came from. These plugins were also
putting that prefix in each skill's own name, so it landed twice — the skill list
advertised `wr-itil:wr-itil:work-problems`, which is not a string you can type.

The Codex build now emits the bare skill name and lets the runtime add the prefix
once. Nothing changes for Claude Code, and the human-readable names on skill cards
are untouched.
