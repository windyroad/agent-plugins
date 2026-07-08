---
status: draft
story-id: self-installing-quota-producer
reported: 2026-07-08
decision-makers: [Tom Howard]
problems: [P160, P443]
jtbd: [JTBD-010]
rfcs: [RFC-046]
story-maps: [STORY-MAP-003]
estimated-effort: L
human-oversight: confirmed
oversight-hash: 84065ec7d04ebf3ef687fd2b0e1efc62d5a6ba15b031ff5a8ff74e0700427759
---

# STORY-043: Self-install the quota-state producer

**Status**: draft
**Reported**: 2026-07-08
**Problems**: P160, P443
**JTBD**: JTBD-010
**RFCs**: RFC-046
**Story Maps**: STORY-MAP-003 (Sustain My Token Quota — Release 2, the fix)
**Estimated effort**: L

## User value (required, INVEST Valuable)

In order to get token pacing actually working the moment I install the plugin — not silently inert until I happen to hand-wire my statusline — as a developer installing `@windyroad/cruise`, I want the plugin to self-install its own data producer, so throttling works out of the box (or from the next session) with no invisible one-time setup step whose absence disables it (JTBD-010 outcome #7; closes the P160/P443 adopter-inert gap).

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] **Blocked-by a dedicated build-time ADR (per ADR-074 + ADR-093 amendment).** Before this story is built, a dedicated ADR records the self-installer MECHANISM with considered options (exact write shape, idempotency sentinel, opt-out surface) and the consent model — **implied-at-install + opt-out** per the ADR-093 amendment (installing a plugin whose stated purpose requires the producer is the authorisation; ADR-034's silent-install rejection is superseded/unratified and a different case). The ADR is ratified before implementation.
- [ ] A `SessionStart` hook self-installs the producer: when `~/.claude/statusline-command.sh` is **absent**, create it with the cache-writing code and wire `~/.claude/settings.json` `statusLine.command`; when **present but missing our code**, idempotently append a **guarded block** (sentinel comment, added exactly once); for a **complex existing statusline** where a blind append could break it, fall back to **agent-merge** (inject an instruction to carefully merge the snippet, human-watched).
- [ ] Opt-out honored (env/settings kill path); idempotent (re-running never duplicates the block); logs what it touched; no-ops gracefully when `.rate_limits` is unavailable (non-Pro/Max, or before the first API response) and never breaks the user's session.
- [ ] Behavioural bats: absent → created + settings wired; present-missing → guarded-append once (idempotent on re-run); opt-out set → no write; existing-custom-statusline → agent-merge fallback path taken (no blind append).

## Notes

- Platform constraint (ADR-093 amendment): the statusline is the only surface exposed to `.rate_limits` and a plugin cannot ship the `statusLine` settings key, so self-installing the user's statusline config is the only mechanism to close the adopter-inert gap.
- The "self-installs on first (or second) session" caveat is acceptable: for a fresh adopter with no statusline, the `settings.json` wiring may only take effect next session; a SessionStart absent-cache log line covers the first-session window.
