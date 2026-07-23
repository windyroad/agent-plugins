# @windyroad/cruise

## 0.4.5

### Patch Changes

- d3a5279: Pace Codex managed-workspace monthly credit limits when app-server returns an `individualLimit` instead of standard rate-limit windows.

## 0.4.4

### Patch Changes

- c715096: Persist the Codex binary used during installation so quota refresh survives runtime restarts and restricted PATHs. Cruise now also discovers the native Codex app bundle and reports a private, sanitized producer failure when quota state cannot be refreshed.

## 0.4.3

### Patch Changes

- b5b8168: Stage the published package outside its scoped npm path before registering the Codex marketplace, so Codex does not misinterpret `@windyroad` as a Git ref.

## 0.4.2

### Patch Changes

- 9712fea: Detect Codex hooks from Codex-specific payload fields so a non-null transcript path cannot make the throttle read Claude quota state.

## 0.4.1

### Patch Changes

- 936a2ec: Use Codex hook payload identity for quota state and begin braking immediately when a fresh session is already over pace.

## 0.4.0

### Minor Changes

- aeff8b2: Add Codex quota pacing using authenticated app-server rate-limit windows while preserving the existing Claude Code statusline integration.

## 0.3.5

### Patch Changes

- 0d76a48: Recover from throttling instantly when you fall behind pace. A per-call sleep that ramped up while you were over pace used to unwind one call at a time — so a session that had banked surplus stayed slow for minutes after it was already behind pace, and the status command itself sat waiting on the throttle. Now the moment a window is behind its pace line the injected sleep drops to zero, and the re-baseline and too-soon paths no longer re-apply a stale sleep. Braking still engages the instant you're over pace again, so pacing is unchanged when you need it.

## 0.3.4

### Patch Changes

- 22a5274: Make the throttle deficit-aware so it stops over-braking when you're behind pace. It now brakes only when a rolling window is both over-rate AND at or over its linear pace line. While you're under the line you hold banked surplus, so a burst no longer triggers braking — the previous controller braked on instantaneous rate alone and slowed you even with days of runway and usage well under the line. Braking still engages as you reach the line and holds you to glide to reset, so the non-exhaustion behaviour is unchanged. Also fixes /wr-cruise:status, which labelled any active sleep as "ahead of pace" regardless of your real position.

## 0.3.3

### Patch Changes

- b49d196: Ship cruise's hooks executable. Both hooks — the PreToolUse throttle and the SessionStart statusline producer — were tracked at git mode 644, so Claude Code's direct invocation was refused with "Permission denied" on every firing and the throttle did no pacing. It failed open, so the plugin installed cleanly but was silently inert. They now ship at mode 755. A CI guard (`check:executable-modes`) asserts every plugin entrypoint is tracked executable so this cannot recur.

## 0.3.2

### Patch Changes

- cd6243d: README: show a single install command. The Install section listed both `npx @windyroad/cruise` and `npx @windyroad/agent-plugins`, which read as a two-step sequence and raised "why both?". Cruise's README now shows just `npx @windyroad/cruise` — cruise installs itself, self-contained. The suite is still linked at the top of the README.

## 0.3.1

### Patch Changes

- 36d13be: Rewrite the README to lead with the value — the pain of a mid-run rate-limit stop and the glide-to-reset outcome — and add the install commands and the `/wr-cruise:status` usage.

## 0.3.0

### Minor Changes

- 60b252a: Add `/wr-cruise:status` — see what the throttle is doing.

  An on-demand telemetry report for quota pacing: per rolling window (5-hour and 7-day) it shows your usage against the pace line, how far ahead or behind you are, the remaining sustainable burn rate, and time to reset; the exact sleep the throttle is injecting per tool call right now; a glide projection; and a cache-health check that flags a stale or absent quota cache — which means the throttle is silently doing nothing.

## 0.2.0

### Minor Changes

- 7c87fe5: Add `@windyroad/cruise` — token-quota pacing — and retire the seven-way throttle sync.

  `@windyroad/cruise` is a self-calibrating token-quota throttle for Claude Code. It reads your rate-limit usage, measures your actual burn, and paces your tool calls so you glide onto each window's pace line and converge on the reset — instead of sprinting into a hard rate-limit stop mid-session. It reserves a weekly headroom for your other Claude surfaces, never blocks, and fails open. Knobs live in a config file (`.claude/cruise.config.json` per project or `~/.claude/cruise.config.json` per machine); `WR_QUOTA_THROTTLE_DISABLE=1` pauses it.

  The seven governance plugins (architect, itil, jtbd, tdd, risk-scorer, style-guide, voice-tone) no longer ship the throttle — it now has a single home in `@windyroad/cruise`, installed as part of the default `npx @windyroad/agent-plugins` set.
