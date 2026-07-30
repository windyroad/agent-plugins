---
status: archived
story-id: throttle-token-burn-against-quota-windows
reported: 2026-07-08
decision-makers: [Tom Howard]
problems: [P160, P443]
jtbd: [JTBD-010]
rfcs: [RFC-046]
story-maps: [STORY-MAP-003]
estimated-effort: M
human-oversight: confirmed
oversight-hash: 1417aeb2d8062969b90296a5f4a1724ae6509b06817dd8772dc5df3c90abab41
---

# STORY-039: Throttle token burn against the quota windows

**Reported**: 2026-07-08
**Problems**: P160, P443
**JTBD**: JTBD-010
**RFCs**: RFC-046
**Story Maps**: STORY-MAP-003 (Sustain My Token Quota — Release 1, the shipped throttle)
**Estimated effort**: M

> **Archived 2026-07-11** — scope superseded by Release 2. The Release-1 throttle this story back-documented (`packages/shared/hooks/quota-pace-throttle.sh`) was deleted and replaced by the corrected self-calibrating throttle in `@windyroad/cruise` (STORY-042 extraction + P446 fix). Kept as the Release-1 lineage anchor on STORY-MAP-003; it can never advance draft→done, so `archived` is its honest terminal state.

> **Back-documents already-shipped Release-1 work.** The throttle CODE shipped 2026-07-06 (`packages/shared/hooks/quota-pace-throttle.sh`, released across 7 plugins, itil 0.57.x) BEFORE this story existed — the P443 lineage debt. Born `draft` (not `done`, no bootstrap-exempt marker — that marker is P170-only per ADR-095) to document the shipped behaviour on STORY-MAP-003. Acceptance criteria are already met by the shipped code; this story records what was built, not pending work.

## User value (required, INVEST Valuable)

In order to keep working across a whole week without a mid-window quota hard-stop halting my loops mid-flight, as a developer sharing one Claude token quota across Code + chat + Cowork, I want every tool call to mechanically self-pace against the tighter of the 5-hour and 7-day windows, so cumulative usage never sprints past the elapsed fraction of the window into a hard stop.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [x] A matcher-less `PreToolUse` hook fires on every tool call and reads the statusline-written `~/.claude/quota-state.json` cache.
- [x] When ahead of pace (usage% > elapsed% − headroom) on the governing (tighter) window, the hook sleeps the calculated glide-path catch-up — proportional ease-back, capped at 60s per firing — converging onto pace before the quota is consumed; behind pace it is a fast no-op that adds negligible latency.
- [x] A configurable weekly headroom is reserved for non-Claude-Code surfaces (chat/Cowork) — **defaults: 5pp weekly, 0pp for the 5h window** (user-ratified defaults 2026-07-08). Both are **tunable**, today via env vars (`WR_QUOTA_HEADROOM_7D_PP` / `WR_QUOTA_HEADROOM_5H_PP`); a per-project + per-machine config file follows in STORY-042. The values are defaults the user chose, not baked policy (P444).
- [x] Fail-open on every abnormal path (missing/stale/malformed cache, kill-switch `WR_QUOTA_THROTTLE_DISABLE=1`, `resets_at` in the past, `jq` absent): exit 0, empty stdout, never emits `permissionDecision`, never blocks or asks.
- [x] Behavioural bats green (`packages/shared/test/quota-pace-throttle.bats`): behind-pace no-op, ahead-of-pace calculated sleep, proportional ease-back (far-over sleeps strictly longer than mildly-over), 7d-headroom throttle, recent-check short-circuit, fail-open paths.

## Notes

- The throttle mechanics are normatively recorded in ADR-093 (ratified 2026-07-08). Release 2 (STORY-042 extraction + STORY-043 self-installing producer) re-homes this hook into `@windyroad/cruise` and closes the adopter-inert gap; this story is the Release-1 baseline they build on.
