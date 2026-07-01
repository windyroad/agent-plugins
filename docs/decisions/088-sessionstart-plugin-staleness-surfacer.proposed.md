---
status: "proposed"
date: 2026-07-02
human-oversight: unconfirmed
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: []
reassessment-date: 2026-10-02
---

# SessionStart plugin-staleness surfacer — per-plugin hook, surface-not-install, network-free

## Context and Problem Statement

A Claude Code session runs the plugin version it resolved at start; a newer installed version is not picked up until the session restarts, and nothing surfaces the gap. So a shipped governance fix silently fails to take effect — and can silently re-introduce a retired bug. Witnessed 2026-07-01: a stale `0.51.0` cache ran a pre-ADR-067 capture-problem SKILL template and re-leaked the uncadenced deferred-placeholder default P375 had retired (→ P402).

This traces P045 (Auto plugin install after governance release — reopened; its named-but-never-shipped `session-start-update-check.sh`) + P375 (a named re-entry point is not a self-firing cadence).

ADR-080 (highest-version-wins shim wrapper) resolves stale-code at invoke time for scaffold-shim **binaries** routed through the ADR-049 PATH shims. SKILL / agent / `hooks.json` **content**, however, is loaded keyed to the session-start version and is a residual ADR-080 does not cover — SQ-080-6 addressed only the non-shim binary surface (scaffold scripts called by absolute path, other non-shim PATH lookups); session-start-keyed content staleness is outside ADR-080's shim-resolution mechanism entirely. That residual is the P402 failure and the surface this ADR occupies. ADR-034 (auto-install, superseded) and ADR-081 (PATH-refresh, rejected) are lineage-not-basis (retired auto-install / retired PATH-mutation respectively).

## Decision Drivers

- **Tractable + network-free detection** — no registry round-trip at boot.
- **Surface-not-install** — P045's ratified direction (2026-04-20) rejects auto-restarting the active session; P343 (restart-required) means even an auto-refresh only helps the *next* session, so surfacing + a one-command action is the correct altitude.
- **Fail-open** (ADR-013 Rule 6) — any detector error → silent proceed; never block boot.
- **Adopter-portable + per-plugin self-contained** (ADR-002/003).
- **Within the SessionStart injection / once-per-session budgets** (ADR-045 / ADR-038).
- **Low session-init cost.**

## Considered Options

1. **Single iterating hook** — one SessionStart hook walks all enabled windyroad plugins and emits one aggregated advisory. Fewest boot hooks (ADR-081 SQ-081-1 leaned this way to keep the SessionStart hook count low).
2. **Per-plugin hook** — each plugin ships its own SessionStart hook checking only itself; an adopter gets checks for exactly the plugins installed; needs cross-hook advisory de-dup so N plugins do not emit N lines.
3. **Auto-install / auto-refresh** — rejected (P045 rejects auto-restart; P343 means it can't help the current session anyway).
4. **npm-registry check as core** — rejected for the core path (network at every boot: latency + offline failure); retained as an opt-in secondary axis.

## Decision Outcome

Chosen: **Option 2 — per-plugin hook, surface-not-install, network-free.** User-ratified 2026-07-02 (per-plugin shape + surface-not-install + network-free).

Each plugin's SessionStart hook infers its own version from its script path (`.../windyroad/<key>/<version>/hooks/...`), compares it to the highest semver-named directory in `~/.claude/plugins/cache/windyroad/<key>/` (reusing the `/install-updates` SHA-residual semver filter so a git-source residual dir cannot win the sort), and emits ONE advisory line when the session version is lower than the highest installed version. Any error → fail-open silent. The canonical hook lives in `packages/shared` and is synced into each plugin per ADR-017 (`sync-<hook>.sh` + `npm run check:<hook>` drift step).

**De-dup mechanism (the load-bearing part) — one race-free single-emitter, NOT a best-effort first-writer.** The N per-plugin hooks are separate, potentially-concurrent boot processes, so a naive "first hook to fire emits" cannot guarantee it observes all siblings' lines — that is the P260 shared-marker race class this repo has repeatedly been bitten by. The mechanism MUST be race-free: each hook **atomically appends** its own plugin's staleness line to a per-boot marker (`/tmp/wr-staleness-<session>`), and a **single deterministic owner** emits the aggregated block (e.g. lock-guarded single emitter, or the owner emits last after a bounded settle). RFC-036 pins the exact race-free mechanism at implementation grain (P132). One aggregated emission keeps the surface within ADR-045 (injection budget) + ADR-038 (once-per-session budget).

## Pros and Cons of the Options

- **Option 1 (single iterating hook):** good — one boot hook, one line, one cache walk. bad — one plugin must enumerate sibling plugins it does not own, breaking ADR-002/003 self-containment; an adopter who installs only `wr-itil` still ships the whole walker.
- **Option 2 (per-plugin, chosen):** good — ADR-002/003 self-contained; adopter gets exactly the checks for installed plugins; canonical-in-`packages/shared` keeps every copy identical. bad — N boot processes + a de-dup mechanism; N cache walks (mitigated by a cheap check + the marker-gated single emission).
- **Option 3 (auto-install):** good — zero user action. bad — violates P045's ratified no-auto-restart; P343 means it cannot help the current session regardless.
- **Option 4 (npm check as core):** good — also catches cache-behind-npm. bad — network at every boot (latency, offline failure); wrong for the load-bearing path (kept as an opt-in secondary axis).

## Consequences

- Good: shipped governance fixes stop silently failing to take effect; a retired bug cannot silently return via stale session code; no network dependency; no boot-blocking; adopter-portable.
- Cost: N per-plugin hooks fire at boot. With ~10 windyroad plugins and a ~50ms cache walk each, that is ~500ms added to every session boot atop the existing ADR-040 briefing + ADR-084 census stanzas — mitigated by a cheap check + the marker-gated single emission. This is session-init cost, not an HTTP request-path surface, so the ADR-023 runtime-path performance review does not fire.

## Confirmation

Behavioural bats (ADR-052 behavioural-default): session-version-behind → advisory emitted; session-version-current → silent; detector error → fail-open silent; AFK-launched session → suppressed (mirrors the existing SessionStart-nudge AFK convention). `docs/decisions/README.md` compendium regenerated per ADR-077.

## Reassessment Criteria

- If the measured boot-cost aggregate exceeds ~1s, revisit Option 1 (a single shared cache walk).
- If the secondary cache-vs-npm network axis is built, it lands as an amendment to this ADR.
- ADR-080 to be back-referenced to this ADR as the decision that took up its uncovered session-start-content residual (tracked as an RFC-036 task to avoid a same-session two-decision-file gate edit).

## Related

- **P045 / P375 / P402** — driving problems + forcing witness.
- **RFC-036** (SessionStart plugin-staleness surfacer) — the implementation vehicle; pins the race-free de-dup mechanism.
- **ADR-080** (highest-version-wins shim wrapper) — covers the binary surface; this ADR covers the session-start-content residual.
- **ADR-034** (superseded) / **ADR-081** (rejected) — retired auto-install / PATH-mutation lineage.
- **ADR-084 / ADR-087** — self-firing deferral census; the class-B self-firing-advisory template this clones.
- **ADR-040** — SessionStart briefing surface (lifecycle precedent).
- **ADR-017** — shared-code sync discipline (canonical in `packages/shared`).
- **ADR-045 / ADR-038** — SessionStart injection / once-per-session budgets the de-dup satisfies.
