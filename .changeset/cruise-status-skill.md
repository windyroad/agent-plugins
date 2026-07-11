---
"@windyroad/cruise": minor
---

Add `/wr-cruise:status` — see what the throttle is doing.

An on-demand telemetry report for quota pacing: per rolling window (5-hour and 7-day) it shows your usage against the pace line, how far ahead or behind you are, the remaining sustainable burn rate, and time to reset; the exact sleep the throttle is injecting per tool call right now; a glide projection; and a cache-health check that flags a stale or absent quota cache — which means the throttle is silently doing nothing.
