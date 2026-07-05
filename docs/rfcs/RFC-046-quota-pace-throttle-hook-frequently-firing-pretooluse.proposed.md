---
status: proposed
rfc-id: quota-pace-throttle-hook-frequently-firing-pretooluse
reported: 2026-07-06
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P160]
adrs: [ADR-093]
jtbd: [JTBD-006]
stories: [STORY-039]
---

# RFC-046: Quota-pace throttle hook — frequently-firing PreToolUse calculated-sleep pacing across all work

**Status**: proposed
**Reported**: 2026-07-06
**Problems**: P160
**ADRs**: ADR-093
**JTBD**: JTBD-006
**Stories**: STORY-039

## Summary

First slice of ADR-093 (mechanical quota-pace throttle): a canonical PreToolUse hook `packages/shared/hooks/quota-pace-throttle.sh` synced to all seven published plugins (staleness-surfacer precedent, ADR-017), firing before every tool call across ALL work — interactive and AFK. Each firing reads the statusline-written quota cache (`~/.claude/quota-state.json`), compares cumulative 5h/7d window usage% against elapsed% (5pp weekly headroom for non-Claude-Code surfaces), and when ahead of pace sleeps the calculated catch-up time (capped 60s per firing). Behind pace = fast no-op via a shared recent-check marker. Fail-open on every abnormal path; never blocks, never asks. Ships with behavioural bats, README activation docs in all seven plugins, and a JTBD-006 even-burn amendment.

## Driving problem trace

- P160 (Ship quota-pacing surface to prevent weekly-quota exhaustion, Open) — hitting a rate-limit window halts work mid-flight (AFK loops break; effortful resume; forced-waking). The throttle converts the statusline's diagnostic burn-rate data into mechanical pacing so work lands at each window reset with headroom instead of hard-stopping. Implements the user-ratified 2026-07-05 direction (corrections 1 + 2) recorded normatively in ADR-093.

## Scope

- Canonical hook + `scripts/sync-quota-pace-throttle.sh` + CI `--check` drift gate + hooks.json PreToolUse registration (no matcher, timeout 90) in the seven plugins.
- Behavioural bats (`packages/shared/test/quota-pace-throttle.bats`, `packages/shared/test/sync-quota-pace-throttle.bats`).
- "Quota pacing" README section in the seven plugin READMEs (behaviour, cap, kill-switch, cache contract, statusline activation snippet).
- JTBD-006 amendment: even-burn quota pacing across all sessions (oversight queued per P357).
- Changeset: minor bump × 7 plugins.

## Tasks

- [ ] Ship canonical hook + sync script + CI drift gate + 7× hooks.json registration + bats + README sections + JTBD-006 amendment + changeset (STORY-039 — this slice)
- [ ] SessionStart absent-cache nudge for adopters (deferred slice per ADR-093 — hook is inert until the statusline snippet is wired; nudge closes the discoverability gap)
- [ ] `/wr-itil:work-problems` between-iter pacing checkpoint (complementary coarse surface per ADR-093 slot note / P160 Correction 1)
- [ ] Cross-surface quota read (account-wide, beyond the statusline cache) — investigate upstream surface per P160 Q6/Q7

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook per ADR-060 Phase 1 item 12)

## Related

- ADR-093 (mechanical quota-pace throttle — normative mechanics; born-proposed, ratification queued)
- STORY-MAP-003 (quota-pace throttle story map, draft)
- JTBD-006 (progress the backlog while AFK), JTBD-001 (enforce governance without slowing down), JTBD-302 (trust README describes installed behaviour)
- `~/.claude/statusline-command.sh` — existing diagnostic read surface (cache writer host)

