# @windyroad/cruise

**Cruise control for your Claude Code and Codex token burn.** *Maturity: Experimental.*

Part of [Windy Road Agent Plugins](../../README.md).

You're hours into an overnight run and your weekly rate limit is exhausted mid-task. The loop halts until the window resets — sometimes days out. `@windyroad/cruise` guards against that for all realistic heavy use: a mechanical, self-calibrating throttle that eases your tool-call burn onto pace so you reach each window's reset with headroom to spare, instead of hitting a hard rate-limit stop.

It runs in the background, never blocks, never asks, and fails open — a broken throttle must never break your session.

## Install

```bash
npx @windyroad/cruise
npx @windyroad/cruise --runtime codex
```

Claude Code remains the default. Use `--runtime codex` or `--runtime both`, then restart the selected runtime. Cruise reads Claude quota from its statusline payload and Codex quota from the authenticated local app-server.

## See it working

```bash
/wr-cruise:status
```

An on-demand report of what the throttle is doing: usage against the pace line per window, how far ahead or behind you are, the sleep it's injecting right now, a glide projection, and a health check that reports whether pacing has stalled.

```
  5-hour window  [##----------|-------]  used 10%  ·  pace 62%  ·  52pp behind
  7-day window   [|-------------------]  used  3%  ·  pace  3%  ·  0pp behind
  Throttle now:   idle (0s) — on or under pace, full speed
```

## How it works

A `PreToolUse` hook fires before every tool call. It reads your current rate-limit usage, measures your actual burn rate, and — when you're burning faster than the *remaining sustainable rate* `(100 − headroom − used) / time_left` — sleeps a small, growing amount per call to bring you back onto pace. When usage is ahead of pace but the platform's integer percentage has not changed enough to measure a rate, Cruise keeps a minimum 10-second brake instead of mistaking unresolved data for safe burn. Behind pace, or at a positively measured sustainable rate, it's a fast no-op.

Every rate-limit window exposed by the runtime is paced; the tighter one governs. Claude currently exposes 5-hour and 7-day windows. Codex windows are discovered from app-server and retain their reported durations. Cruise holds back **headroom** (default 5pp on the long window) for other account surfaces.

The throttle reads a small runtime-owned cache. Claude uses `~/.claude/quota-state.json` produced by its statusline; Codex uses `~/.codex/quota-state.json` produced from `account/rateLimits/read`. Producers write atomically and the throttle fails open when data is unavailable.

## Configure

Optional. Knobs resolve project → machine → built-in defaults, with env vars overriding all:

```json
{
  "headroom_7d_pp": 5,
  "headroom_5h_pp": 0,
  "max_sleep_s": 600,
  "cache_path": "~/.claude/quota-state.json"
}
```

Save it under the active runtime: `.claude/cruise.config.json` or `~/.claude/cruise.config.json` for Claude; `.codex/cruise.config.json` or `~/.codex/cruise.config.json` for Codex. `max_sleep_s: 0` pauses pacing without uninstalling.

## Honest limits

It slows; it doesn't block — by design. So it can't save you from *sustained* very-heavy burn (upward of 5%/hr for days on end) — nothing short of a hard stop could, and a hard stop is the outage this exists to avoid. Short of that extreme, it holds the line.

To remove it, uninstall the plugin — that cleanly removes the statusline block it added.

## Licence

[MIT](../../LICENSE)

Built by [Windy Road Technology](https://windyroad.com.au).
