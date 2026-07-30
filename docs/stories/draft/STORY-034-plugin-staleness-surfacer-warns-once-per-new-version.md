---
status: draft
story-id: plugin-staleness-surfacer-warns-once-per-new-version
reported: 2026-07-04
decision-makers: [Tom Howard]
problems: [P045, P375]
jtbd: [JTBD-007]
rfcs: [RFC-036]
estimated-effort: M
---

# STORY-034: Warn once per new version when a session runs stale plugin code

**Reported**: 2026-07-04
**Problems**: P045, P375
**JTBD**: JTBD-007
**RFCs**: RFC-036
**Estimated effort**: M

## User value (INVEST Valuable)

In order to stop silently running stale plugin code after a newer version installs mid-session, as a developer, I want each session to warn me once when its plugin version is behind the highest installed version — so I know to restart to pick it up.

## Acceptance criteria (INVEST Testable)

- [x] Each of the seven governance plugins' `UserPromptSubmit` hook compares its own version (from its script path) to the highest installed cache version for its key and prints one advisory line when behind.
- [x] The check is network-free, warn-only (never installs or restarts), fails quiet, and is silent when the session is current.
- [x] The advisory emits once per newly-detected version (a version-keyed extension of ADR-038's per-session announcement marker), so unchanged turns cost ~0 tokens and the line does not repeat.
- [ ] The remaining plugins (connect, retrospective, c4, wardley, agent-plugins) are wired to the surfacer so they stop being surfacer-blind (RFC-036 Task 3b — deferred).

## Driving problem trace (I6)

**P045** — the named-but-never-shipped startup check; this RFC delivers it in the corrected per-turn, surface-not-install shape. **P375** — the self-firing-cadence class; a session silently running stale plugin code is a direct instance.

## JTBD trace (I9)

**JTBD-007** (Keep Plugins Current Across Projects) — the developer persona's plugin-version-drift pain point (a new release lands on npm but active sessions still run the old code); the per-turn surfacer removes the silent-stale-code failure.

## Backfill note (ADR-089)

Umbrella backfill story for the pre-ADR-089 RFC-036, which was accepted before ADR-089 (every RFC has ≥1 story) shipped. Stays `draft` (born `human-oversight: unconfirmed`) until an interactive session ratifies it and decides whether to give it a story-map trace (I8) to reach `accepted`. The RFC-side `stories:` wiring is deferred to that same interactive drain per ADR-090 (an RFC may reference only ratified stories — ratify-then-wire order).

## Dependencies

- **Blocks**: (none — backfill)
- **Blocked by**: (none)

## Related

- RFC-036 (parent RFC), ADR-088 (governing decision), ADR-038 (announcement-marker discipline), ADR-089/090 (the invariants this backfills toward). P045 / P375 / P402 (forcing witness).
