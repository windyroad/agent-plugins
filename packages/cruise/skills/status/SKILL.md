---
name: status
description: Show live Codex and Claude Code quota usage with Cruise pacing, current sleep, glide projection, and cache freshness. Use when the user asks how Cruise, quota pacing, or the throttle is doing.
allowed-tools: Bash(wr-cruise-status)
---

Run the Cruise status reporter and present its output to the user:

- On Claude Code, run `wr-cruise-status`.
- On Codex, resolve the installed plugin root from this `SKILL.md` path (two
  directories above it), then run
  `PATH="<plugin-root>/bin:$PATH" wr-cruise-status`.

The report shows each rolling window exposed by the active runtime: current usage vs the pace line, how far ahead/behind pace, the remaining sustainable burn rate, time-to-reset, current per-tool sleep, a glide projection, and cache freshness.

Surface the report faithfully. **If it warns the cache is STALE or absent, say so prominently** — that means the throttle is fail-open and not pacing, and the runtime quota producer needs repair.
