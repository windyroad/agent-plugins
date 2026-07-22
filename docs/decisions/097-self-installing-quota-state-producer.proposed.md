---
status: "proposed"
date: 2026-07-09
decision-makers: [Tom Howard]
consulted: [wr-architect:agent]
informed: []
reassessment-date: 2026-10-09
human-oversight: confirmed
oversight-date: 2026-07-22
---

# Self-installing quota-state producer (SessionStart guarded-statusline edit)

## Context and Problem Statement

The `@windyroad/cruise` throttle (ADR-093) reads `~/.claude/quota-state.json`, which only a **statusline** can write — Claude Code exposes `.rate_limits` to no other surface, and a plugin cannot ship the `statusLine` settings key (ADR-093 amendment, verified 2026-07-08). So the producer is unavoidably user-owned config the plugin cannot ship directly. Release 1 left it as a copy-paste doc snippet → the throttle was **inert for every adopter** (P160/P443). STORY-043 closes this by having the plugin **self-install** the producer via a SessionStart hook. The consent model is already decided in ADR-093's amendment — **implied-at-install + opt-out** (installing a plugin whose stated purpose requires the producer is the authorisation; ADR-034's silent-plugin-install rejection is superseded/unratified and a materially different case: our own required config on the user's own chosen machine). **This ADR settles the write MECHANISM, not the consent principle.** STORY-043 is blocked on this ADR being ratified (ADR-074).

## Decision Drivers

- Must actually write the statusline cache-writer so the throttle works on install (close the P160/P443 adopter-inert gap).
- Must never corrupt or clobber a user's existing statusline (idempotent, reversible, guarded).
- Must never corrupt or clobber a user's existing statusline (idempotent, reversible, guarded).
- Must fail safe when there's nothing to do (non-Pro/Max accounts, before first API response — no `.rate_limits`).
- **Reversibility:** because install writes to the user's `~/.claude/` config, uninstalling must be able to leave no trace.

## Considered Options (how self-install is controlled)

1. **A separate opt-out knob** (env var and/or a config-file key) that disables self-install while the plugin stays installed.
2. **No opt-out knob — install is the consent, uninstall is the reversal.** Installing `@windyroad/cruise` (whose whole purpose is quota pacing, which *requires* the producer) is the authorisation (ADR-093 implied-at-install). There is no coherent "keep the plugin but disable its core function" state. To pause pacing without uninstalling, set `max_sleep_s: 0` in the cruise config (disables the throttle, leaves the producer untouched).

## Decision Outcome

**Chosen: Option 2 — no self-install opt-out knob (user direction 2026-07-09: "it should live in not installing the plugin").** A `cruise` install with self-install disabled would be an inert plugin, identical to not installing it — so a separate opt-out is incoherent. Consent is the install; the control surface is install / uninstall; temporary pause is `max_sleep_s: 0` in the config.

**Write mechanism (determined by constraints):** a SessionStart hook that —
- **statusline absent** → create `~/.claude/statusline-command.sh` with the cache-writing code and wire `~/.claude/settings.json` `statusLine.command` to it;
- **statusline present, our block missing** → idempotently append a **guarded block** bounded by sentinel comments (`# >>> @windyroad/cruise (quota pacing) — managed, do not edit >>>` … `# <<< @windyroad/cruise <<<`), added exactly once (presence detected by grepping the sentinel);
- **complex/foreign existing statusline** where a blind append could break it → **agent-merge fallback**: inject an instruction for the agent to carefully merge the snippet, human-watched, rather than blind-append;
- always: **log what it touched** (a one-line SessionStart note naming the file + action), **idempotent** (re-run never duplicates the block), and **no-op gracefully** when `.rate_limits` is unavailable (non-Pro/Max, or before the first API response) — never breaking the user's session.

**Reversal on uninstall:** because the guarded block is sentinel-bounded, uninstalling `@windyroad/cruise` must **remove the block** (and unwire the `settings.json` `statusLine.command` if — and only if — cruise created it), leaving the statusline as it was. The sentinel bounds make this a clean, deterministic removal. (Uninstall-cleanup mechanism — a plugin uninstall hook vs a documented `cruise` cleanup command — is a build detail for STORY-043, not a separate decision.)

## Consequences

### Good
- The throttle works on install for every adopter — closes the P160/P443 inert gap.
- The user's existing statusline is never clobbered (guarded block + agent-merge fallback).
- No incoherent "inert plugin" state; the control surface is simple and honest — install to get it, uninstall (clean removal) to reverse it, `max_sleep_s: 0` to pause without touching the statusline.

### Neutral
- The plugin writes to the user's `~/.claude/` config — invasive by nature, but bounded, logged, and cleanly reversible on uninstall (sentinel-bounded block), and consented at install.
- For a fresh adopter with no statusline, the `settings.json` wiring may only take effect next session; a first-session SessionStart log line covers the window.

### Bad
- A malformed or exotic user statusline could defeat auto-detection; the agent-merge fallback mitigates but adds a human-in-the-loop path.
- Writing `settings.json` is the most sensitive touch; it must be a minimal, guarded, reversible merge.

## Confirmation

Behavioural bats: absent → created + `settings.json` wired; present-missing-block → guarded-append exactly once (idempotent on re-run); foreign complex statusline → agent-merge path taken (no blind append); no `.rate_limits` → no-op, session unbroken; **uninstall → the guarded block is removed and (if cruise wired it) `settings.json` is unwired, leaving no trace**; `max_sleep_s: 0` (config) pauses pacing without touching the statusline. Verified against STORY-043's acceptance criteria before it transitions to done.

Codex confirmation adds: SessionStart never writes under `~/.claude`; app-server binary selection follows `CODEX_BINARY` → macOS app bundle → `PATH`; reads time out and fail open; cache writes are atomic; and package uninstall removes only a default cache carrying the `codex-app-server` source marker.

## Pros and Cons of the Options

### Option 1 — A separate opt-out knob (env/config disables self-install, plugin stays)
- Good: a "keep plugin but off" state, if that were ever meaningful.
- Bad: incoherent — a cruise install with self-install off is inert (identical to not installing); adds a documented surface + precedence rule for a state no one wants.

### Option 2 — No knob; install is consent, uninstall is reversal (chosen)
- Good: simplest honest model; consent = install (ADR-093); clean uninstall removes all trace; `max_sleep_s: 0` already handles temporary pause.
- Bad: relies on uninstall doing the cleanup (a build requirement for STORY-043).

## Reassessment Criteria

Revisit if Claude Code ever exposes `.rate_limits` to a hook or ships a plugin-contributable statusLine (the self-install mechanism would become unnecessary), or if the guarded-append proves fragile against real-world statuslines in the field.


## Amendment 2026-07-10 — build refinements (STORY-043)

Two mechanics were refined while building the self-installer + throttle; both stay inside this decision (self-installing producer, implied-at-install consent), so this is pre-acceptance evolution, not a supersession:

1. **Present statusline → agent-merge, NOT guarded-append.** The indicative "idempotently append a guarded block when present but missing our code" above is superseded for the *present* case: a live statusline has already consumed stdin, so an appended stdin-reading block would run empty (broken). The shipped self-installer instead: **absent** → create the statusline + wire `settings.json`; **already a producer** (writes the cache) → no-op; **present non-producer** → a once-only SessionStart agent-merge instruction (human-watched), and it NEVER blind-appends. Verified by `packages/cruise/test/quota-state-producer-install.bats` (7 green).
2. **No kill-switch.** All references above to a throttle kill-switch (`WR_QUOTA_THROTTLE_DISABLE`) are retired (user direction 2026-07-10): the glide only ever slows and never blocks, so there is nothing to escape; pacing is disabled via config `max_sleep_s: 0`, and the producer is reversed by uninstalling. The env-switch existed for the declined deny-backstop.

## Amendment 2026-07-22 — Codex app-server producer

Codex does not use the Claude statusline producer. On Codex, the SessionStart hook must not write `~/.claude`; it initializes `~/.codex/quota-state.json` from the authenticated Codex app-server instead. It also atomically writes a mode-0600 `.pace` numeric sidecar with the normalized windows and write timestamp for the latency-bounded frequent hook; neither file contains credentials or raw account data. Subsequent stale refreshes are single-flight background reads started by the existing PreToolUse hook, while the on-demand status command may refresh synchronously. The producer calls `account/rateLimits/read`, prefers `CODEX_BINARY` when supplied, then the ChatGPT app-bundled Codex binary on macOS, then `codex` on `PATH`; it has a bounded timeout, writes atomically, and fails open.

Codex uninstall through the package installer removes the default cache and its `.pace` sidecar only when the JSON cache carries Cruise's `codex-app-server` source marker. It never removes an arbitrary configured cache path. Claude's statusline mechanism and reversal contract remain unchanged. User direction 2026-07-22 pinned the Codex port; pre-edit architect review confirmed this is an amendment to the existing producer decision, not a new decision.
