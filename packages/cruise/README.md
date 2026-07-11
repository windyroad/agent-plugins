# @windyroad/cruise

**Cruise control for your Claude Code token burn.** *Maturity: Experimental.*

Part of [Windy Road Agent Plugins](../../README.md).

You're hours into an overnight run and your weekly rate limit is exhausted mid-task. The loop halts until the window resets — sometimes days out. `@windyroad/cruise` guards against that for all realistic heavy use: a mechanical, self-calibrating throttle that eases your tool-call burn onto pace so you reach each window's reset with headroom to spare, instead of hitting a hard rate-limit stop.

It runs in the background, never blocks, never asks, and fails open — a broken throttle must never break your session.

## Install

```bash
npx @windyroad/cruise           # just the throttle
npx @windyroad/agent-plugins    # the whole suite, cruise included
```

Restart Claude Code to activate. Cruise self-installs everything else it needs — no hand-wiring.

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

A `PreToolUse` hook fires before every tool call. It reads your current rate-limit usage, measures your actual burn rate, and — when you're burning faster than the *remaining sustainable rate* `(100 − headroom − used) / time_left` — sleeps a small, growing amount per call to bring you back onto pace. On or under pace, it's a fast no-op.

Both rolling windows are paced at once (5-hour and 7-day); the tighter one governs. Cruise holds back a weekly **headroom** (default 5pp) so Claude Code doesn't consume the budget your chat and Cowork sessions also draw on.

The throttle reads a small cache (`~/.claude/quota-state.json`) that only a statusline can produce — so cruise writes the statusline for you on first run (create-if-absent, and it never touches an existing one).

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

Save it at `.claude/cruise.config.json` (per project) or `~/.claude/cruise.config.json` (per machine). `max_sleep_s: 0` pauses pacing without uninstalling.

## Honest limits

It slows; it doesn't block — by design. So it can't save you from *sustained* very-heavy burn (upward of 5%/hr for days on end) — nothing short of a hard stop could, and a hard stop is the outage this exists to avoid. Short of that extreme, it holds the line.

To remove it, uninstall the plugin — that cleanly removes the statusline block it added.

## Licence

[MIT](../../LICENSE)

Built by [Windy Road Technology](https://windyroad.com.au).
