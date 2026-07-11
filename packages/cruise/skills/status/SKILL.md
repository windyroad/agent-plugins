---
name: wr-cruise:status
description: Show live @windyroad/cruise quota-pacing telemetry — per-window usage vs the pace line, how far ahead/behind, the per-call sleep the throttle is injecting right now, a glide projection, and whether the quota cache is fresh (a stale/absent cache means the throttle is silently doing nothing). Use when the user asks how cruise / quota pacing / the throttle is doing, whether it's throttling, how much headroom is left, or when a rate-limit window resets.
allowed-tools: Bash(wr-cruise-status)
---

Run the cruise status reporter and present its output to the user:

```bash
wr-cruise-status
```

The report shows, per rolling window (5-hour and 7-day): current usage vs the pace line (an ASCII bar with a `|` at where usage *should* be), how far ahead/behind pace, the remaining sustainable burn rate, and time-to-reset; the sleep the throttle is currently injecting per tool call (0s when idle); a glide projection from the measured burn; and the config in effect plus cache freshness.

Surface the report faithfully. **If it warns the cache is STALE or absent, say so prominently** — that means the throttle is fail-open and NOT pacing (the "installed but inert" failure this plugin exists to prevent), and the fix is to install/repair the statusline producer or run a Pro/Max session.
