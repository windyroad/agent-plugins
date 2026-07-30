---
status: in-progress
story-id: extract-quota-pacing-plugin
reported: 2026-07-08
decision-makers: [Tom Howard]
problems: [P160, P443]
jtbd: [JTBD-010]
rfcs: [RFC-046]
story-maps: [STORY-MAP-003]
estimated-effort: L
human-oversight: confirmed
oversight-hash: 3aa1acef05ec689794c3dd49f6d39be20677cf261be893e8a4deb619736c429d
---

# STORY-042: Extract quota-pacing into its own plugin

**Reported**: 2026-07-08
**Problems**: P160, P443
**JTBD**: JTBD-010
**RFCs**: RFC-046
**Story Maps**: STORY-MAP-003 (Sustain My Token Quota — Release 2, the fix)
**Estimated effort**: L

## User value (required, INVEST Valuable)

In order to install token pacing on its own — without pulling in a governance plugin I don't want — and to have it maintained as one thing rather than seven byte-identical synced copies, as a developer who wants quota pacing, I want the throttle extracted into a dedicated `@windyroad/cruise` plugin, so it is an opt-in capability with a single home (per ADR-093's 2026-07-08 amendment).

## Acceptance criteria (accepted-gate, INVEST Testable)

- [x] A new installable plugin `packages/cruise/` exists: `.claude-plugin` manifest, `hooks/quota-pace-throttle.sh` (moved from `packages/shared/hooks/`), `hooks.json` registering it as matcher-less `PreToolUse` (`timeout: 90`), a README (behaviour, per-firing cap, kill-switch, cache contract, opt-out), and `package.json` (`@windyroad/cruise`).
- [x] The seven governance plugins (architect, itil, jtbd, tdd, risk-scorer, style-guide, voice-tone) no longer ship `quota-pace-throttle.sh`; `scripts/sync-quota-pace-throttle.sh` and its CI `--check` drift gate are removed (single home → no sync surface).
- [x] ADR-002 obligations met: `@windyroad/cruise` is added to the ADR-002 plugin inventory, `marketplace.json`, and `install.mjs` (PLUGINS array + dependency graph).
- [x] **Concurrency (per the 2026-07-08 design note):** glide-path pacing is verified to hold across N concurrent Claude Code sessions sharing one account. The machine-wide `$TMPDIR/wr-quota-throttle-*` recent-check marker — originally designed to dedupe seven hook-copies *within one session*, now moot with a single copy per session — MUST be reworked to per-session (or per-session + shared-lock hybrid) so concurrent sessions each get full throttle grip while the shared `~/.claude/quota-state.json` still coordinates aggregate account burn. A multi-session behavioural test asserts aggregate burn stays paced (no per-session no-op suppression under concurrency).
- [x] **Config file (per-machine AND per-project), not env-only (user direction 2026-07-08 — env vars judged inconvenient).** The plugin reads a config file for its knobs — `headroom_7d_pp` (default 5), `headroom_5h_pp` (default 0), per-firing sleep cap (default 60s), kill-switch, cache path — resolved with precedence **project-root config → machine (`~/.claude/`) config → built-in defaults**, with env vars as a final override. Per P444, the exact keys + file name/location are surfaced as an explicit decision at build (not baked in silently). This is the `QUOTA-POLICY`-style config ADR-093 deferred ("no separate config file for the first slice") — now reinstated. Behavioural test: project config overrides machine config overrides defaults.
- [x] Throttle behaviour is unchanged from Release 1 (STORY-039 acceptance criteria still pass against the extracted hook); `packages/shared/test/quota-pace-throttle.bats` moves with the hook.
- [x] A `.changeset/*.md` entry: initial publish of `@windyroad/cruise` + bumps for the seven plugins dropping the hook.

## Notes

- Opt-in reach is intentional (ADR-093 amendment retracts Option 4's "every adopter auto-gets it"): adopters of only other windyroad plugins no longer get throttling unless they add `@windyroad/cruise`.
- Pairs with STORY-043 (self-installing producer) to fully close the P160/P443 adopter-inert + mis-placement gaps.
- **Name: `@windyroad/cruise`** (user-ratified 2026-07-08 — the marketable name for the capability; "cruise control" for your token burn). Propagate the name into ADR-093, RFC-046, and the P160/P443/P444 prose during the RFC-046 repair batch so the lineage stays consistent (do NOT leave `@windyroad/quota-pacing` in the decision-of-record while the stories say `cruise`).
