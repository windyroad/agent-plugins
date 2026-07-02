---
status: "proposed"
date: 2026-07-02
human-oversight: unconfirmed
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: []
reassessment-date: 2026-10-02
---

# Plugin-staleness surfacer — per-plugin, per-turn (UserPromptSubmit), surface-not-install, network-free

## Context and Problem Statement

A Claude Code session runs the plugin version it resolved at start; a newer installed version is not picked up until the session restarts, and nothing surfaces the gap. So a shipped governance fix silently fails to take effect — and can silently re-introduce a retired bug. Witnessed 2026-07-01: a stale `0.51.0` cache ran a pre-ADR-067 capture-problem SKILL template and re-leaked the uncadenced deferred-placeholder default P375 had retired (→ P402).

**The gap opens mid-session, not at boot.** At session start the running version and the installed version are usually already equal. The staleness you most need flagged appears *during* a long session — you run `/install-updates`, a release lands, or the AFK loop refreshes — advancing the installed version while the session keeps running the old code. A once-at-startup check misses this (the prevalent case); the surfacer must re-check each turn (user correction 2026-07-02).

This traces P045 (Auto plugin install after governance release — reopened; its named-but-never-shipped startup check) + P375 (a named re-entry point is not a self-firing cadence).

ADR-080 (highest-version-wins shim wrapper) resolves stale-code at invoke time for scaffold-shim **binaries** routed through the ADR-049 PATH shims. SKILL / agent / `hooks.json` **content**, however, is loaded keyed to the session-start version and is a residual ADR-080 does not cover — SQ-080-6 addressed only the non-shim binary surface; session-start-keyed content staleness is outside ADR-080's shim-resolution mechanism entirely. That residual is the P402 failure and the surface this ADR occupies. ADR-034 (auto-install, superseded) and ADR-081 (PATH-refresh, rejected) are lineage-not-basis.

## Decision Drivers

- **Catch mid-session installs, not just start-of-session staleness** — the gap opens when the installed version advances during a live session.
- **Tractable + network-free detection** — no registry round-trip.
- **Cheap enough to run every turn** — the per-turn check must cost near-zero and emit nothing when the session is current (user direction 2026-07-02: "if it's a small efficient check that doesn't burn tokens, happy for it to run very often").
- **Surface-not-install** — P045's ratified direction rejects auto-restart; P343 (restart-required) means auto-refresh only helps the next session, so surface + a one-command action is the correct altitude.
- **Fail-open** (ADR-013 Rule 6) — any detector error → silent proceed; never block a turn.
- **Within the ADR-038 per-turn UserPromptSubmit injection budget** (once-per-change announcement discipline).
- **Adopter-portable + per-plugin self-contained** (ADR-002/003).

## Considered Options

1. **SessionStart-only, per-plugin** — fires once at boot. **Rejected**: misses the prevalent mid-session-install case (SessionStart has already fired; nothing re-checks). User correction 2026-07-02.
2. **UserPromptSubmit per-turn, per-plugin** — each plugin's hook re-checks every turn; cheap; silent when current; emits once per newly-detected version. **Chosen.**
3. **Single iterating hook (consolidation — ADR-038 Considered-Option-3)** — one hook walks all enabled windyroad plugins each turn. **Rejected**: breaks ADR-002/003 self-containment (one plugin enumerating siblings it doesn't own; an adopter installing only `wr-itil` would still ship the walker). Its per-turn saving mainly benefits the all-plugins-installed maintainer case — see the self-limiting-cost note in Consequences.
4. **Auto-install / auto-refresh** — rejected (P045 rejects auto-restart; P343 means it can't help the current session anyway).
5. **npm-registry check as core** — rejected (network on every turn: latency + offline failure); retained as an opt-in secondary axis.

## Decision Outcome

Chosen: **Option 2 — UserPromptSubmit per-turn, per-plugin, surface-not-install, network-free.** User-ratified 2026-07-02 (per-turn trigger to catch mid-session installs; per-plugin shape; surface-not-install; network-free; run-very-often-if-cheap).

Each plugin ships a `UserPromptSubmit` hook that, every turn, infers its own version from its script path (`.../windyroad/<key>/<version>/hooks/...`), reads the highest semver-named directory in `~/.claude/plugins/cache/windyroad/<key>/` (reusing the `/install-updates` SHA-residual semver filter), and compares. The check is a stat + one version compare — near-zero, and it emits **nothing** when the session is current (a silent hook adds no context tokens). When the session version is lower than the highest installed version, it emits ONE advisory line. Any error → fail-open silent. Canonical hook in `packages/shared`, synced per ADR-017.

**Output throttle (ADR-038 alignment) — emit once per newly-detected version, not every turn.** Running the *check* every turn is cheap, but repeating the same advisory line every turn would burn output tokens. So emission is gated on a version-keyed extension of ADR-038's per-session announcement marker (`/tmp/${SYSTEM}-announced-${SESSION_ID}` becomes version-keyed): the line is emitted the turn a newer version is first detected and suppressed until the detected version changes again. This keeps the surface within ADR-038's per-turn injection budget: ~0 bytes on unchanged turns, one short line on a version change.

**No cross-hook coordination — each hook emits its own line independently (user-ratified 2026-07-02).** Each per-plugin hook emits its own one-line advisory for its own plugin; there is no aggregation, no shared cross-plugin marker, and no coordination between hooks. This eliminates the P260 shared-marker race class outright: N behind-version plugins print N short lines, bounded and accepted.

## Pros and Cons of the Options

- **Option 1 (SessionStart-only):** good — fires once, cheapest. bad — misses mid-session installs, the case that matters most.
- **Option 2 (UserPromptSubmit per-turn, per-plugin, chosen):** good — catches mid-session installs; ADR-002/003 self-contained; per-turn cost scales with plugins-installed (self-limiting); network-free; silent when current. bad — runs every turn (mitigated: stat + one compare, silent output when current); N independent lines when N plugins are simultaneously stale (bounded, accepted).
- **Option 3 (single iterating hook):** good — one hook per turn regardless of plugin count. bad — breaks ADR-002/003 self-containment; the saving is material only when many plugins are installed.
- **Option 4 (auto-install):** good — zero user action. bad — violates P045's no-auto-restart; P343 means it can't help the current session.
- **Option 5 (npm check as core):** good — also catches cache-behind-npm. bad — network on every turn; wrong for the load-bearing path (kept as opt-in secondary).

## Consequences

- Good: shipped fixes stop silently failing to take effect *including mid-session*; a retired bug cannot silently return via stale session code; no network dependency; never blocks a turn; adopter-portable.
- Cost + ADR-038 cluster growth: the trigger is per-turn, so each per-plugin hook joins the UserPromptSubmit cluster (currently five: architect, jtbd, tdd, style-guide, voice-tone). ADR-038's Reassessment Criteria flags the sixth UserPromptSubmit hook as the point to reconsider its Considered-Option-3 (cross-plugin consolidation). This ADR **assesses that trigger and retains per-plugin**: the per-turn cost is a stat + one compare (near-zero) and, critically, **self-limiting** — an adopter runs one such hook per windyroad plugin they actually installed (typically 2–3), so the N≈10 aggregate only ever hits the all-plugins maintainer/dogfood case; consolidation's saving there does not justify breaking ADR-002/003 self-containment for every adopter. The staleness lines are homogeneous, so consolidation would also lose little context — the deciding factor is self-containment, not context economy.
- This is per-turn hook cost, not an HTTP request-path surface, so the ADR-023 runtime-path performance review does not fire.

## Confirmation

Behavioural bats (ADR-052 behavioural-default): session-version-behind → advisory emitted once; unchanged subsequent turns → silent; version advances mid-session → advisory re-emitted once; detector error → fail-open silent; AFK-launched session → suppressed. `docs/decisions/README.md` compendium regenerated per ADR-077 (body edit **and** file rename).

## Reassessment Criteria

- If the measured per-turn aggregate cost becomes noticeable in practice, revisit Option 3 (single shared walk) — the ADR-038 6th-hook consolidation trigger, assessed-and-deferred here, is the re-entry point.
- If the secondary cache-vs-npm network axis is built, it lands as an amendment here.
- ADR-080 to be back-referenced to this ADR as the decision taking up its uncovered session-start-content residual; and ADR-038's Related to record that its UserPromptSubmit cluster grew past five and was assessed against its consolidation trigger — both tracked as RFC-036 tasks to avoid same-session multi-decision-file edits.

## Related

- **P045 / P375 / P402** — driving problems + forcing witness.
- **RFC-036** (Plugin-staleness surfacer) — the implementation vehicle.
- **ADR-038** — per-turn UserPromptSubmit injection budget + once-per-session announcement discipline (the governing budget authority for this surface); its 6th-hook consolidation trigger is assessed in Consequences.
- **ADR-040** — SessionStart briefing surface; lineage only (this ADR leaves the SessionStart surface for per-turn).
- **ADR-080** (highest-version-wins shim wrapper) — covers the binary surface; this ADR covers the session-start-content residual.
- **ADR-034** (superseded) / **ADR-081** (rejected) — retired auto-install / PATH-mutation lineage.
- **ADR-084 / ADR-087** — self-firing deferral census; the class-B self-firing-advisory template this clones.
- **ADR-017** — shared-code sync discipline (canonical in `packages/shared`).
- **ADR-002 / ADR-003** — per-plugin self-containment (the deciding factor for per-plugin over consolidation).
