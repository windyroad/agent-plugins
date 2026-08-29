# Problem 529: Codex work-problems drain stops on Claude CLI quota because iterations dispatch through claude -p

**Status**: Open
**Reported**: 2026-08-29
**Priority**: 20 (Very High) — Impact: 4 × Likelihood: 5 — derived at capture. Impact 4: the installed `/wr-itil:work-problems` skill cannot continue a Codex-native backlog drain when the unrelated Claude CLI quota is exhausted, so a core plugin workflow fails for an installed user even though the active runtime has capacity. Likelihood 5: the report reproduces the failure after the ChatGPT/Codex quota refreshed while the drain still stopped on the Claude CLI weekly limit, and describes the dispatch as applying to every isolated iteration in ChatGPT/Codex sessions.
**Origin**: internal
**Effort**: M — derived at capture. Runtime selection must change without weakening the existing isolation wrapper, governance gates, clean-state checks, idle recovery, optional cost metadata, or the one-ticket `ITERATION_SUMMARY` contract, and needs behavioural coverage for both Codex and Claude Code dispatch arms.
**WSJF**: 10 — (20 × 1.0) / 2
**JTBD**: JTBD-006
**Persona**: developer

## Description

In ChatGPT and Codex sessions, /wr-itil:work-problems dispatches every isolated iteration through claude -p, coupling the drain to the unrelated Claude CLI quota. The orchestrator must select the native runtime CLI: codex exec for ChatGPT/Codex and claude -p for Claude Code, while preserving process isolation, governance gates, clean-state checks, idle recovery, cost metadata where available, and the one-ticket ITERATION_SUMMARY contract. This was reproduced when the ChatGPT/Codex quota had refreshed but the drain still stopped on the Claude CLI weekly limit.

## Symptoms

(deferred to investigation)

## Workaround

(deferred to investigation)

## Impact Assessment

- **Who is affected**: (deferred to investigation)
- **Frequency**: (deferred to investigation)
- **Severity**: (deferred to investigation)
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [ ] Investigate root cause
- [ ] Create reproduction test

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: (none)

## Related

Captured via `/wr-itil:capture-problem`. Hang-off arbitration was not dispatched: the mechanical pre-filter found 93 open or verifying tickets sharing the `/wr-itil:work-problems` signal, above the five-candidate latency cap. Review-time re-evaluation candidates: P035, P065, P070, P087, P096, P102, P104, P124, P126, P131, P136, P137, P140, P142, P143, P144, P151, P152, P154, P162, P168, P170, P172, P173, P175, P176, P177, P178, P179, P185, P207, P213, P220, P232, P247, P248, P251, P261, P268, P272, P273, P274, P275, P276, P278, P279, P308, P314, P315, P330, P333, P343, P346, P350, P351, P358, P361, P370, P373, P374, P375, P376, P382, P385, P386, P389, P390, P398, P399, P401, P402, P404, P412, P413, P416, P424, P427, P428, P430, P434, P441, P443, P448, P451, P456, P464, P467, P470, P473, P502, P516, P517, and P528.

The title-only duplicate check matched P036, P040, P041, P053, P077, P083, P084, P089, P103, P104, P109, P122, P126, P130, P138, P140, P206, P210, P211, P212, P214, P221, P250, P307, P308, P333, P341, P344, P382, P385, P386, P413, P427, P428, P441, P451, and P528. None names native runtime CLI selection; `/wr-itil:review-problems` owns any later merge decision.
