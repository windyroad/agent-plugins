---
status: draft
story-id: extract-quota-pacing-plugin
reported: 2026-07-08
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P160, P443]
jtbd: [JTBD-010]
rfcs: [RFC-046]
story-maps: [STORY-MAP-003]
estimated-effort: L
---

# STORY-042: Extract quota-pacing into its own plugin

**Status**: draft
**Reported**: 2026-07-08
**Problems**: P160, P443
**JTBD**: JTBD-010
**RFCs**: RFC-046
**Story Maps**: STORY-MAP-003 (Sustain My Token Quota — Release 2, the fix)
**Estimated effort**: L

## User value (required, INVEST Valuable)

In order to install token pacing on its own — without pulling in a governance plugin I don't want — and to have it maintained as one thing rather than seven byte-identical synced copies, as a developer who wants quota pacing, I want the throttle extracted into a dedicated `@windyroad/quota-pacing` plugin, so it is an opt-in capability with a single home (per ADR-093's 2026-07-08 amendment).

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] A new installable plugin `packages/quota-pacing/` exists: `.claude-plugin` manifest, `hooks/quota-pace-throttle.sh` (moved from `packages/shared/hooks/`), `hooks.json` registering it as matcher-less `PreToolUse` (`timeout: 90`), a README (behaviour, per-firing cap, kill-switch, cache contract, opt-out), and `package.json` (`@windyroad/quota-pacing`).
- [ ] The seven governance plugins (architect, itil, jtbd, tdd, risk-scorer, style-guide, voice-tone) no longer ship `quota-pace-throttle.sh`; `scripts/sync-quota-pace-throttle.sh` and its CI `--check` drift gate are removed (single home → no sync surface).
- [ ] ADR-002 obligations met: `@windyroad/quota-pacing` is added to the ADR-002 plugin inventory, `marketplace.json`, and `install.mjs` (PLUGINS array + dependency graph).
- [ ] **Concurrency (per the 2026-07-08 design note):** glide-path pacing is verified to hold across N concurrent Claude Code sessions sharing one account. The machine-wide `$TMPDIR/wr-quota-throttle-*` recent-check marker — originally designed to dedupe seven hook-copies *within one session*, now moot with a single copy per session — MUST be reworked to per-session (or per-session + shared-lock hybrid) so concurrent sessions each get full throttle grip while the shared `~/.claude/quota-state.json` still coordinates aggregate account burn. A multi-session behavioural test asserts aggregate burn stays paced (no per-session no-op suppression under concurrency).
- [ ] Throttle behaviour is unchanged from Release 1 (STORY-039 acceptance criteria still pass against the extracted hook); `packages/shared/test/quota-pace-throttle.bats` moves with the hook.
- [ ] A `.changeset/*.md` entry: initial publish of `@windyroad/quota-pacing` + bumps for the seven plugins dropping the hook.

## Notes

- Opt-in reach is intentional (ADR-093 amendment retracts Option 4's "every adopter auto-gets it"): adopters of only other windyroad plugins no longer get throttling unless they add `@windyroad/quota-pacing`.
- Pairs with STORY-043 (self-installing producer) to fully close the P160/P443 adopter-inert + mis-placement gaps.
