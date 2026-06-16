---
"@windyroad/architect": patch
---

Make the architect README-pairing commit gate reuse the shared command-detection helper instead of its own inline parser. The gate decides whether a Bash command is a real `git commit` invocation before it checks that a staged decision-record change is paired with its compendium update. The previous inline parser recognised a direct `git commit` and an environment-variable-prefixed one, but silently missed a commit prefixed with a directory change (`cd <path> && git commit`), so that shape slipped past the gate. The gate now delegates to the same helper the ITIL and retrospective gates use, which already handles directory-change and environment prefixes and is portable across the awk implementations shipped on Linux and macOS. Behaviour is otherwise unchanged: commands that merely mention the phrase "git commit" still pass, and `git commit-tree` is still treated as a different command.
