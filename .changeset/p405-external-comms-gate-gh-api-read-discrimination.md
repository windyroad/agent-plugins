---
"@windyroad/risk-scorer": patch
"@windyroad/voice-tone": patch
---

The external-comms gate now distinguishes read-only `gh api` polls from body-bearing draft writes. Previously any command containing `gh api ... security-advisories` or `gh api ... /comments` was treated as an outbound draft and blocked — including the read-only `--jq` discovery poll that `/wr-itil:review-problems` uses, which carries no outbound prose. A new `_gh_api_has_body` predicate gates those two surfaces only when a request-body flag (`-f`/`--field`, `-F`/`--raw-field`, `--input`) is present; read-only invocations skip the gate. Every inherently-write surface (`gh issue`/`gh pr` create/comment/edit, `npm publish`, changeset, commit message) stays gated unconditionally (P405).
