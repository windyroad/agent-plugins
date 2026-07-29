---
"@windyroad/architect": patch
"@windyroad/cruise": patch
"@windyroad/risk-scorer": patch
---

Codex and ChatGPT skill pickers now show readable titles instead of raw invocation names — `WR Risk Scorer: Assess WIP` rather than `wr-risk-scorer:assess-wip` — plus a one-line description per skill. `WR` is short for Windy Road. Only the label changes: machine invocation names stay lowercase and untouched, so existing scripts and hooks keep working, and nothing about Claude Code usage moves.

For `@windyroad/risk-scorer` this also fixes a packaging fault. The pre-publish transform rebuilt `skills/` from an allowlist, which dropped the new per-skill metadata from the tarball, so without this the labels would never have reached an adopter's install.
