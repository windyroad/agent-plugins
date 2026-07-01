---
status: proposed
rfc-id: sessionstart-plugin-staleness-surfacer
reported: 2026-07-02
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P045, P375]
adrs: []
jtbd: [JTBD-007]
stories: []
---

# RFC-036: SessionStart plugin-staleness surfacer

**Status**: proposed
**Reported**: 2026-07-02
**Problems**: P045, P375
**ADRs**: (none yet — the surfacer mechanism is a genuine ≥2-option decision; a new ADR is extracted and ratified at the `/wr-itil:manage-rfc accepted` transition BEFORE implementation, per ADR-070 [RFCs hold no independent decisions] + ADR-073)
**JTBD**: JTBD-007 (Keep Plugins Current Across Projects — primary); JTBD-008 (Decompose a Fix Into Coordinated Changes — capture-vehicle); JTBD-001 (Enforce Governance Without Slowing Down — extended scope)

## Summary

Ship the self-firing startup check that P045 named as its close-condition and never delivered: a **network-free, cross-plugin, class-B self-surfacing** SessionStart hook that stops a Claude Code session from silently running stale `@windyroad/*` plugin code.

The hook reads **its own version from its script path** (`.../windyroad/<key>/<version>/hooks/...`), compares it to the highest-installed version in the global plugin cache (`~/.claude/plugins/cache/windyroad/<key>/`), and when the running session is behind, surfaces one advisory line:

> `wr-itil: this session is on 0.51.0, 0.55.5 installed — restart to pick it up.`

Surface, do not auto-install: P045's ratified direction (2026-04-20, user) explicitly rejects auto-restarting the active session, and P343 (restart-required) means even an auto-refresh only helps the *next* session — so surface-and-act is the correct altitude. A secondary, opt-in axis (cache-vs-npm-latest, which needs network) may nudge "run `/install-updates`" but is out of the load-bearing core.

## Driving problem trace

- **P045** (`docs/problems/open/045-auto-plugin-install-after-governance-release.md`) — the execution tracker for auto-install-on-next-session-start. Reopened 2026-07-02: closed on a P375 antipattern (on-demand `/install-updates` substituted for the self-firing startup check), and the hook `packages/itil/hooks/session-start-update-check.sh` it names as its close-condition was never shipped. This RFC delivers that startup check, in the corrected surface-not-install shape.
- **P375** (`docs/problems/known-error/375-repo-conflates-named-re-entry-point-with-self-firing-cadence.md`) — the class. "Session silently runs stale plugin code" is a direct instance: the only trigger to pick up a release was a human remembering to restart / run `/install-updates`, which per the rot test never self-fires. The concrete failure this RFC prevents (a stale 0.51.0 cache re-introducing the retired uncadenced-deferred-placeholder default → P402) is exactly the invisible-rot P375 describes. The fix is P375's own prescribed class-B self-surfacing template (ADR-084 / ADR-087 lineage).

## Residual surface (why this is not redundant with existing decisions)

This RFC occupies the surface that two retired decisions vacated and one shipped decision does not cover:

- **ADR-034** (Auto-install on next session start — SessionStart hook + `.claude/.auto-install-consent` + npm-registry check) is **superseded** (by ADR-030 via P299): the per-project install model was wrong (the cache is global/shared) and the registry network dependency was a bad consequence. Historical "what-not-to-do" lineage only — NOT a design basis. The surfacer clears both rejection reasons (it reads the global cache directly, mutates nothing, and is network-free).
- **ADR-081** (SessionStart PATH-refresh hook for plugin cache) is **rejected** — retired PATH-mutation. Also lineage-only.
- **ADR-080** (highest-version-wins shim wrapper) covers scaffold-shim *binaries* at invoke time. It does NOT cover SKILL / agent / `hooks.json` **content**, which is loaded keyed to the session-start version and is genuinely stale in an old session — exactly the P402 failure (a stale 0.51.0 SKILL template ran despite 0.55.x installed). That uncovered residual is the reason this surfacer is needed.

## Scope

(deferred — populate at /wr-itil:manage-rfc accepted transition)

Seed notes for that pass (NOT yet ratified scope):
- **New ADR required before implementation** (ADR-070 + ADR-073): extract the surfacer decision to a new ADR ratified at the `accepted` transition. Do not host the decision in the RFC body. Sub-decisions to record there, each ≥2-option:
  - **per-plugin hook vs one iterating hook** — ADR-081 SQ-081-1 leaned toward a single iterating hook to keep the SessionStart hook count low; "each plugin ships its own copy" is N firings at boot and needs advisory-line de-dup / aggregation.
  - the secondary **cache-vs-npm** opt-in axis (network cost at every session start).
  - **fail-open envelope** (ADR-013 Rule 6): any detector error → silent proceed, never block boot.
- **Detector is network-free**: infer own version from `$BASH_SOURCE` / script path and compare to the highest semver-named cache dir (reuse the `/install-updates` Step 3 SHA-residual filter; `feedback_verify_cache_refresh_by_version_dir`).
- **Cross-plugin via `packages/shared` engages ADR-017**: the decomposition MUST include a `sync-<hook>.sh` + an `npm run check:<hook>` CI drift step + canonical-lives-in-`packages/shared` discipline, matching the external-comms-gate precedent (`feedback_edit_canonical_synced_hook_not_consumer_copy`).
- **Lifecycle precedent**: ADR-040 (session-start briefing surface) + ADR-084/087 (self-firing deferral census — the class-B advisory template). Cite these, not ADR-047 (which is install-updates scaffolding, not a SessionStart precedent).
- AFK-launched sessions: mirror the existing SessionStart-nudge AFK-suppression convention.
- Session-init latency (~50ms cache walk per ADR-081 estimate) belongs in the accepted-transition ADR's Consequences.

## Tasks

- [ ] (deferred — populate at /wr-itil:manage-rfc accepted transition; decompose into: new ADR extraction/ratification → shared-hook in `packages/shared` + `sync`/`check:` per ADR-017 → per-plugin wiring → bats coverage)

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook)

## Related

(captured via /wr-itil:capture-rfc; expand at next /wr-itil:manage-rfc invocation)

- **ADR-034** (`docs/decisions/034-auto-install-on-next-session-start.superseded.md`) — superseded; retired auto-install + consent-marker + npm-network mechanism. Historical lineage, not design basis.
- **ADR-081** (`docs/decisions/081-sessionstart-path-refresh-hook-for-plugin-cache.rejected.md`) — rejected; retired PATH-mutation. Historical lineage.
- **ADR-080** (highest-version-wins shim wrapper) — covers scaffold-shim binaries; the SKILL/agent/hooks.json content residual is what this RFC addresses.
- **ADR-084 / ADR-087** — self-firing deferral census + cadence-annotation contract; the class-B self-firing-advisory template this surfacer clones.
- **ADR-040** — session-start briefing surface; the SessionStart lifecycle precedent.
- **ADR-017** — shared code duplicated into per-package `lib/` kept in sync by script + CI drift check; engaged by the cross-plugin hook.
- **JTBD-007** (`docs/jtbd/developer/JTBD-007-keep-plugins-current.proposed.md`) — primary job; desired outcomes name this failure verbatim.
- **P402** (`docs/problems/open/402-...md`) — the forcing witness (stale-cache leak of a retired bug).
- **P343** — PATH-stale-shim / restart-required; the constraint that makes surface-not-auto-install correct.
- **`/install-updates`** (`.claude/skills/install-updates/`) — the on-demand manual path this RFC makes self-firing at the detection layer.
