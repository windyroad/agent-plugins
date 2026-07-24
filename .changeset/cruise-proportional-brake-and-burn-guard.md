---
"@windyroad/cruise": patch
---

Brake harder and earlier on quota sprints. The over-pace sleep now grows in proportion to how far over the sustainable rate the burn is, so a genuine sprint reaches a strong brake within a call or two instead of ramping slowly. A new behind-the-line burn guard (`burn_guard_multiple`, default 4, `0` disables) brakes an early-week sprint that projects to exhaust the window well before its reset, even while banked surplus remains; it releases the instant the rate falls back. A stale Codex refresh lock is now reaped so a killed background refresh can no longer leave the quota cache silently un-refreshed.
