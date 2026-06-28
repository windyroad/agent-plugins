---
"@windyroad/itil": patch
---

Fix the problem-ticket reverse-trace section refresh aborting on macOS (BSD awk). `update-problem-references-section.sh` passed the rendered multi-line section into `awk -v section=...` when inserting before a `## Fix Released` heading; BSD awk rejects embedded newlines in a `-v` assignment and aborts, silently dropping the `## RFCs` / `## Stories` / `## Story Maps` refresh. The insert now passes the section via a temp file read with `getline`, matching the portable idiom already used in `effort-tally.sh`. (P392)
