---
status: done
story-id: self-installing-quota-producer
reported: 2026-07-08
decision-makers: [Tom Howard]
problems: [P160, P443]
jtbd: [JTBD-010]
rfcs: [RFC-046]
story-maps: [STORY-MAP-003]
estimated-effort: L
---

# STORY-043: Self-install the quota-state producer

**Reported**: 2026-07-08
**Problems**: P160, P443
**JTBD**: JTBD-010
**RFCs**: RFC-046
**Story Maps**: STORY-MAP-003 (Sustain My Token Quota — Release 2, the fix)
**Estimated effort**: L

## User value (required, INVEST Valuable)

In order to get token pacing actually working the moment I install the plugin — not silently inert until I happen to hand-wire my statusline — as a developer installing `@windyroad/cruise`, I want the plugin to self-install its own data producer, so throttling works out of the box (or from the next session) with no invisible one-time setup step whose absence disables it (JTBD-010 outcome #7; closes the P160/P443 adopter-inert gap).

## Acceptance criteria (accepted-gate, INVEST Testable)

- [x] **Blocked-by a dedicated build-time ADR (per ADR-074 + ADR-093 amendment).** — satisfied: ADR-097 (self-installing quota-state producer) ratified 2026-07-09. Before this story is built, a dedicated ADR records the self-installer MECHANISM with considered options (exact write shape, idempotency sentinel, opt-out surface) and the consent model — **implied-at-install + opt-out** per the ADR-093 amendment (installing a plugin whose stated purpose requires the producer is the authorisation; ADR-034's silent-install rejection is superseded/unratified and a different case). The ADR is ratified before implementation.
- [x] A `SessionStart` hook self-installs the producer: **absent** → create the statusline (flat-schema cache-writer) + wire `~/.claude/settings.json` `statusLine.command`; **already a producer** (statusline writes the cache) → no-op; **present but not a producer** → **agent-merge nudge** (a once-only SessionStart instruction to integrate the block into the existing statusline, human-watched). **Build refinement (STORY-043, 2026-07-10):** ADR-097's indicative "guarded-append" is deliberately NOT used for a present statusline — it has already consumed stdin, so an appended stdin-reading block would run empty (broken); agent-merge is the safe realisation and blind-append is never done.
- [x] No self-install opt-out (per ADR-097 — install is the consent, uninstall is the reversal); no throttle kill-switch either (user direction 2026-07-10 — the glide never blocks, so there's nothing to escape; `max_sleep_s: 0` in the config disables pacing while installed). Idempotent (re-run never duplicates / never re-nudges); logs what it touched (SessionStart stderr); no-ops gracefully when `.rate_limits` / `jq` / `~/.claude` is unavailable and never breaks the session.
- [x] Behavioural bats (`packages/cruise/test/quota-state-producer-install.bats`, 7 green): absent → created + executable + settings wired; created statusline writes a flat cache from a payload; already-producer → no-op (not overwritten); present non-producer → valid agent-merge JSON + statusline UNTOUCHED; nudge fires at most once; kill-switch → no install.

## Notes

- Platform constraint (ADR-093 amendment): the statusline is the only surface exposed to `.rate_limits` and a plugin cannot ship the `statusLine` settings key, so self-installing the user's statusline config is the only mechanism to close the adopter-inert gap.
- The "self-installs on first (or second) session" caveat is acceptable: for a fresh adopter with no statusline, the `settings.json` wiring may only take effect next session; a SessionStart absent-cache log line covers the first-session window.


## Story Maps

| ID | Title | Status |
|----|-------|--------|
| STORY-MAP-003 | STORY-MAP-003: Sustain my token quota across the week and across surfaces | draft |
