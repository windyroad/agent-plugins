---
"@windyroad/risk-scorer": patch
---

P096 Phase 2 — `plan-risk-guidance.sh` (PreToolUse EnterPlanMode) once-per-session emission + new shared session-marker consumer:

- **First-vs-subsequent EnterPlanMode behaviour**: first EnterPlanMode of a session emits the full advisory body (compressed: drops the standing release-strategy listing in favour of cross-references to ADR-018 / ADR-042). Subsequent EnterPlanMode invocations in the same session emit a terse one-line reminder.
- **New consumer of `lib/session-marker.sh`**: `packages/risk-scorer/hooks/lib/session-marker.sh` (NEW byte-identical copy synced from `packages/shared/hooks/lib/session-marker.sh` per ADR-017 duplicate-script pattern). risk-scorer joins the session-marker CONSUMERS list as the 7th plugin.
- **`scripts/sync-session-marker.sh` extended**: CONSUMERS list now covers 7 plugins; `packages/shared/test/sync-session-marker.bats` drift fixtures extended to match (mkdir + iteration both updated).

Confirms ADR-038's documented extension pattern: the once-per-session helper is event-type-agnostic (PostToolUse and PreToolUse both supported).

7 new behavioural bats tests (`packages/risk-scorer/hooks/test/plan-risk-guidance-once-per-session.bats`) cover first-emit body, marker write, terse reminder shape, byte budget, distinct-session re-emit, empty-session-id fallback, JSON validity on both branches. All green.

Refs: P096, P095 (session-marker), ADR-009, ADR-017 (duplicate-script), ADR-038 (progressive disclosure).
