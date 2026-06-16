---
"@windyroad/risk-scorer": patch
"@windyroad/voice-tone": patch
---

Stop the external-comms gate from blocking git commit messages in private and internal repositories. A commit message only reaches an external audience once it lands in a public repository's history, pull request list, release notes, or changelog. In a private or internal repository there is no external reader, so the review prompt fired on every commit as a false positive. The gate now checks repository visibility on the commit-message surface and passes silently when the repository is not public, or when visibility cannot be determined. The credential and production-URL leak scan still runs in every repository, so secrets are still caught before they enter git history. Other surfaces (issues, pull requests, npm publish, changeset bodies) are unchanged.
