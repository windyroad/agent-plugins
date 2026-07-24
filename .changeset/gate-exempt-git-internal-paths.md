---
"@windyroad/architect": patch
"@windyroad/jtbd": patch
"@windyroad/voice-tone": patch
"@windyroad/style-guide": patch
"@windyroad/tdd": patch
---

Stop gating writes to VCS-internal `.git/` paths. The edit-enforcement hooks treat any write under the repository root as a project file, so a commit-message scratch file or other `.git/` plumbing was blocked pending governance review — the sibling case the earlier outside-the-repo exclusion did not cover, since `.git/` sits inside the root. Writes under `.git/` are now exempt across all five enforce-edit gates.
