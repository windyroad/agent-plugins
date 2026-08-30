---
"@windyroad/itil": patch
---

Make `/wr-itil:work-problems` iteration dispatch compatible with macOS Bash 3.2. The loop no longer nests a heredoc inside command substitution or depends on `mapfile`, and it passes every resolved governance `--plugin-dir` argument to the iteration subprocess.
