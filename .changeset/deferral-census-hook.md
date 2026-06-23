---
"@windyroad/retrospective": minor
---

Self-firing deferral census — a SessionStart hook that surfaces deferred work before it rots.

Governance deferrals that name a re-entry point ("deferred to the next review", "pending review", "re-rate at next…") only pay off if something automatically fires that re-entry point. When nothing does, the deferred work waits for someone to remember a command — and silently rots.

`retrospective-deferral-census.sh` runs on session start and counts deferred-work markers across your `docs/` and `packages/` `.md` files, surfacing a one-line total plus the worst-offender files so the backlog of parked work stays visible every session instead of fading with context.

- Advisory only — never blocks, fails open, silent when there is nothing deferred.
- Honours the ADR-040 session-start budget (output capped to the top 5 offenders).
- Skips archival records (CHANGELOG, history files) so the signal reflects live work.
- Suppressible per-iteration under AFK orchestration via `WR_SUPPRESS_DEFERRAL_CENSUS=1`.

Substance captured under P375 and a new ADR (self-firing deferral census), `human-oversight: unconfirmed` pending canonical review.
