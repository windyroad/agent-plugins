# Ask Hygiene — 2026-05-17 (session 4, iter 7, P087 Phase 3 ADR-063 landing)

Per ADR-044 framework-resolution-boundary, the lazy-AskUserQuestion-count is the per-retro regression metric. Target = 0.

## In-session classifications

(No `AskUserQuestion` calls fired in this iter — AFK subprocess; mid-loop AskUserQuestion forbidden per P135 / ADR-044; orchestrator constraint also: "No mid-loop AskUserQuestion".)

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|

**Lazy count: 0**
**Direction count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## Cross-session trend (check-ask-hygiene.sh)

```
RETRO 2026-05-17-session-4-iter-6-p162-phase-2b lazy=0
RETRO 2026-05-17-session-4-iter-5-p233            lazy=0
RETRO 2026-05-17-session-4-iter-4-p234-transition lazy=0
RETRO 2026-05-17-session-4-iter-3-p234-phase-1    lazy=0
RETRO 2026-05-17-session-4-iter-2-p234            lazy=0
RETRO 2026-05-17                                  lazy=1
RETRO 2026-05-16                                  lazy=0
RETRO 2026-05-15-p186                             lazy=0
TREND lazy_first=0 lazy_last=0 delta=+0
```

R6 numeric gate (lazy ≥ 2 across 3 consecutive retros) does NOT fire — only one retro (2026-05-17) has lazy=1, all others sit at 0. No deviation-candidate queued.

## Notes

- AFK subprocess mode enforces zero AskUserQuestion per orchestrator constraint + P135 / ADR-044 framework-mediated stage discipline. The capture-on-correction OFFER pattern (P078) does not fire because no user-correction was received this iter.
- The capture-problem SKILL Step 1.5 derive-first classifier resolved `type_value` silently on the one capture-problem invocation (P237). No AskUserQuestion fired there. The other three captures (P238/P239/P240) were written via direct Write rather than SKILL invocation; no classifier path triggered.
