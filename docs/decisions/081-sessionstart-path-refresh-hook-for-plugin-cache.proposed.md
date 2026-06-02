---
status: "proposed"
date: 2026-06-02
decision-makers: [unspecified — fill at canonical review]
consulted: []
informed: []
reassessment-date: 2026-09-02
---

# SessionStart PATH refresh hook for plugin cache

> Captured via /wr-architect:capture-adr (foreground-lightweight aside-invocation per ADR-032 P156 amendment). Run /wr-architect:create-adr on this ID to expand the deferred sections canonically.

## Context and Problem Statement

P343 — `/install-updates` refreshes the plugin cache but does NOT mutate the parent shell's PATH; PATH is populated at Claude Code's session-init from the cache state at that time and stays frozen for the lifetime of the session, so subsequent sessions continue to find stale-version shims first on PATH until the user manually restarts.

## Decision Drivers

- (deferred to /wr-architect:create-adr canonical review)

## Considered Options

1. **Option A (chosen)** — Add a SessionStart hook (per ADR-040 SessionStart surface) that recomputes PATH from current cache state at every session start, prepending the latest-version bin directories of every enabled `@windyroad/*` plugin ahead of any stale entries.
2. (deferred — see /wr-architect:create-adr canonical review)

## Decision Outcome

Chosen option: **"Option A"**, because a SessionStart hook that recomputes PATH from current cache state at every session start eliminates the stale-PATH-on-next-session pattern without requiring a user-visible restart. This is a bounded addition on the existing ADR-040 SessionStart surface. Pairs with the sibling ADR-080 (P343 Option 3 — highest-version-wins shim wrapper) which covers mid-session staleness; this ADR covers cold-start cleanup at the next session boundary.

## Consequences

### Good

- (deferred to /wr-architect:create-adr canonical review)

### Neutral

- (deferred to /wr-architect:create-adr canonical review)

### Bad

- (deferred to /wr-architect:create-adr canonical review)

## Confirmation

(deferred to /wr-architect:create-adr canonical review)

## Pros and Cons of the Options

### Option A

- (deferred to /wr-architect:create-adr canonical review)

## Reassessment Criteria

(deferred to /wr-architect:create-adr canonical review — default reassessment-date 3 months from capture)

## Related

- **P343** (Known Error) — driving problem ticket; Option 4 in P343 § Root Cause Analysis.
- **ADR-040** — session-start-briefing-surface — the hook surface this ADR extends.
- **ADR-080** — sibling capture for P343 Option 3 (highest-version-wins shim wrapper); the two compose (ADR-080 covers mid-session staleness; this ADR covers cold-start at next session boundary).
- **P045** — auto plugin install after governance release; same install/PATH coupling.
- **P106** — `claude plugin install` silent no-op when already installed; same plugin-cache-management surface.
