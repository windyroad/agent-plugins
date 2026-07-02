---
status: accepted
rfc-id: plugin-staleness-surfacer
reported: 2026-07-02
accepted: 2026-07-02
human-oversight: confirmed
oversight-confirmed-date: "2026-07-02 — acceptance ratified via AskUserQuestion against the per-turn (UserPromptSubmit) design (per-plugin, each hook its own line, warn-only, network-free); decision held in ADR-088 per ADR-070"
decision-makers: [Tom Howard]
problems: [P045, P375]
adrs: [ADR-088]
jtbd: [JTBD-007]
stories: []
---

# RFC-036: Plugin-staleness surfacer

**Status**: accepted
**Reported**: 2026-07-02
**Accepted**: 2026-07-02
**Problems**: P045, P375
**ADRs**: ADR-088 (Plugin-staleness surfacer — per-plugin, per-turn, surface-not-install, network-free)
**JTBD**: JTBD-007 (Keep Plugins Current Across Projects — primary); JTBD-001 (extended)

## Summary

Ship the self-firing staleness check that P045 named as its close-condition and never delivered, in the per-turn shape ratified 2026-07-02. Each windyroad plugin ships a `UserPromptSubmit` hook that re-checks **every turn** whether the running session's plugin version is behind the highest version installed on disk, and — when it is — prints ONE advisory line ("wr-itil: this session is on 0.51.0, 0.55.5 installed — restart to pick it up"). The check is network-free (own version from the hook's script path vs the highest semver-named cache dir), warn-only (never installs or restarts), fails quiet, and is silent when the session is current. It emits once per newly-detected version (a version-keyed extension of ADR-038's per-session announcement marker), so it costs ~0 tokens on unchanged turns and does not repeat. Each plugin emits its own line independently — no cross-hook coordination, eliminating the P260 shared-marker race.

The per-turn trigger is load-bearing: a once-at-boot check misses the prevalent case, where a newer version is installed *mid-session* (via `/install-updates`, a release, or the AFK loop) after the boot check has already fired. The full decision — options, drivers, the ADR-038 6th-hook consolidation assessment — is held in **ADR-088** per ADR-070 (RFCs hold no independent decisions).

## Driving problem trace

- **P045** (`docs/problems/open/045-auto-plugin-install-after-governance-release.md`) — reopened; its named-but-never-shipped startup check. This RFC delivers that check in the corrected per-turn, surface-not-install shape.
- **P375** (`docs/problems/known-error/375-repo-conflates-named-re-entry-point-with-self-firing-cadence.md`) — the class. A session silently running stale plugin code is a direct instance; the fix is P375's own class-B self-firing-advisory template. Forcing witness: P402 (a stale 0.51.0 cache re-leaked a retired deferred-placeholder default).

## Scope

**Body-shape note:** this RFC rides the Phase-1 `## Scope` + `## Tasks` body structure (consistent with RFC-005 and the live `docs/rfcs/README.md` Phase-1 structure) **pending the ADR-073 story-map migration** — a conscious recorded deviation, not a silent default. Captured as a framework-gap ticket for the ADR-073↔README Phase-1 inconsistency.

Ship the per-plugin, per-turn plugin-staleness surfacer per ADR-088: each windyroad plugin's `UserPromptSubmit` hook compares its own version (from its script path) to the highest installed cache version for its key and emits one advisory line when behind; network-free; warn-only; fail-open; silent when current; emit-once-per-new-version; each hook independent (no coordination). Canonical hook in `packages/shared`, synced per ADR-017. The secondary cache-vs-npm network axis is out of core scope.

## Tasks

- [ ] 1. Canonical hook in `packages/shared`: own-version-from-script-path vs highest semver-named cache dir compare (reuse the `/install-updates` SHA-residual filter); fail-open; emit-once-per-new-version via a version-keyed extension of ADR-038's `/tmp/${SYSTEM}-announced-${SESSION_ID}` announcement marker.
- [ ] 2. `sync-<hook>.sh` + `npm run check:<hook>` CI drift step per ADR-017 (external-comms-gate precedent).
- [ ] 3. Wire the `UserPromptSubmit` hook into each plugin's `hooks.json` + per-plugin `lib/` copy.
- [ ] 4. Behavioural bats (ADR-052): behind → advisory once; unchanged subsequent turns → silent; version advances mid-session → advisory re-emitted once; detector error → fail-open silent; AFK-launched → suppressed.
- [ ] 5. Amend ADR-080 `## Related` to back-reference ADR-088 as the decision taking up its uncovered session-start-content residual (deferred from ADR-088 to avoid a same-session two-decision-file edit; regenerate + verify the compendium per ADR-077 / P365).
- [ ] 6. Amend ADR-038 `## Related` to record its UserPromptSubmit cluster grew past five and was assessed against its 6th-hook consolidation trigger (same deferral rationale; same compendium care).
- [ ] 7. Changeset per touched plugin + release.

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook)

## Related

- **ADR-088** (`docs/decisions/088-plugin-staleness-surfacer.proposed.md`) — the governing decision (per-turn, per-plugin, surface-not-install, network-free).
- **P045 / P375 / P402** — driving problems + forcing witness.
- **P343** — restart-required; the constraint making surface-not-install correct.
- **ADR-038** — per-turn UserPromptSubmit injection budget (the announcement-marker discipline Task 1 extends).
- **ADR-017** — shared-code sync discipline (Task 2).
- **`/install-updates`** — the on-demand manual path this RFC makes self-firing at the detection layer.
