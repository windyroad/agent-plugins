# `packages/shared/` — canonical shared-helper source

This directory is **not a published plugin**. It holds the single canonical
copy of code shared across the `@windyroad/*` plugins. Each consuming package
carries its own synced copy so it stays self-contained at install time — see
[ADR-017](../../docs/decisions/017-shared-code-sync-pattern.proposed.md) for
the decision and its rationale. **ADR-017 is authoritative; this README is a
pointer, not a restatement.**

## What lives here

| Path | Holds | Synced into each package's… |
|------|-------|------------------------------|
| `packages/shared/` (root) and `packages/shared/lib/` | Cross-cutting libs — e.g. `derive-first-dispatch.sh`, `migrate-problems-layout.sh`, `install-utils.mjs` | `lib/` |
| `packages/shared/hooks/lib/` | Hook helpers — e.g. `session-marker.sh`, `leak-detect.sh`, `external-comms-key.sh`, `command-detect.sh` | `hooks/lib/` |

## Adding a new shared helper

1. **Pick the subpath by role** — a hook helper goes under `hooks/lib/`
   (so it sits beside the hooks that consume it); anything else under `lib/`.
2. Write the canonical copy here.
3. Add a matching `scripts/sync-<name>.sh` plus `sync:<name>` / `check:<name>`
   npm scripts and a CI drift-check step, following the existing shape (see
   ADR-017 § Confirmation). The sync *mechanism* is identical for both roles;
   only the destination subpath differs.

The `check:<name>` CI gate fails loudly if any package's synced copy drifts
from the canonical source here.
