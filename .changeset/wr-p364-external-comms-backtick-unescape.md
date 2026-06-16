---
"@windyroad/risk-scorer": patch
"@windyroad/voice-tone": patch
---

Fix the external-comms gate so a reviewed outbound body that contains markdown code spans unlocks the post. The gate read the body from the raw shell command text, where backticks inside double quotes are backslash-escaped to survive bash parsing, while the post-review marker was keyed on the plain reviewed draft. The two keys differed, so an approved draft re-blocked indefinitely. The gate now reverses bash double-quote escaping on the extracted body, restoring the match. Single-quoted and heredoc bodies are left untouched.
