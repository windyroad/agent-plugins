---
status: accepted
story-id: cruise-status-telemetry-skill
reported: 2026-07-11
decision-makers: [Tom Howard]
problems: [P160, P446]
jtbd: [JTBD-010]
rfcs: [RFC-046]
story-maps: [STORY-MAP-003]
estimated-effort: M
---

# STORY-044: See what cruise is doing — a status/telemetry skill

**Reported**: 2026-07-11
**Problems**: P160, P446
**JTBD**: JTBD-010
**RFCs**: RFC-046
**Story Maps**: STORY-MAP-003
**Estimated effort**: M

## User value (required, INVEST Valuable)

In order to trust that quota pacing is actually working — to see at a glance whether I'm ahead of pace, how hard the throttle is braking *right now*, and whether I'll glide to the reset — as a developer who otherwise can't see a silent background throttle, I want an on-demand `/wr-cruise:status` report of the live telemetry, so the pacing is legible instead of invisible, and an inert/fail-open throttle (the P160 "installed but doing nothing" failure) is immediately obvious.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [x] A `/wr-cruise:status` skill runs a bundled reporting script (`wr-cruise-status` shim → `scripts/cruise-status.sh` per ADR-049) and presents its output.
- [x] **Per window (5h + 7d):** current used% vs the pace line (a bar), how far ahead/behind pace, the remaining sustainable rate (%/hr), and time-to-reset.
- [x] **Right now:** the per-call sleep the throttle is currently injecting (from the per-session state `cur_s`), and whether it's throttling / easing off / idle.
- [x] **Projection:** at the measured burn rate, whether it glides to the reset or would breach the reserved line — and roughly when.
- [x] **Config + health:** headroom (5h/7d), the sleep ceiling, the cache path, and cache freshness — a stale/absent cache is flagged loudly because it means the throttle is fail-open / inert (the exact P160 failure class this whole capability exists to prevent).
- [x] **Fail-safe:** missing cache / state / `jq` → a clear "not paced yet / no data" report, never an error.
- [x] Behavioural bats (`packages/cruise/test/cruise-status.bats`): inject a cache + session state and assert the report surfaces the right used%/ahead/sleep numbers; a stale/absent cache prints the inert-throttle warning; no-data path is graceful.
- [x] `plugin.json` declares the `status` skill; `package.json` ships `skills/` + `scripts/` + the `bin/` shim; a `.changeset/*.md` bumps `@windyroad/cruise`.

## Driving problem trace (required — I7 invariant)

- **P160** — the throttle was inert-for-adopters and silently fail-open; there was no way to *see* whether pacing was active. This skill makes the "installed but doing nothing" state visible on demand.
- **P446** — the throttle's effectiveness was invisible until a hard stop happened; telemetry surfaces whether the glide is holding the line *before* exhaustion.

## JTBD trace (accepted-gate — I8 invariant)

Serves JTBD-010's "trust the tooling to pace automatically" and "the failure mode is expensive" outcomes: legibility is what lets a developer trust a silent automatic throttle, and a health check catches the inert-throttle failure before it costs a window.

## Related

- RFC-046 (the cruise RFC — this is a Release-3 legibility slice), ADR-093 (throttle mechanics — the state/cache this reads), ADR-098 (config), STORY-039/042/043 (the throttle + extraction + producer this observes).
