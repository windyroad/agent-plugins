# Problem 529: Codex work-problems cannot use refreshed Codex CLI quota

**Status**: Known Error
**Reported**: 2026-08-29
**Priority**: 20 (Very High) — Impact: 4 × Likelihood: 5 — derived at capture. Impact 4: the installed `/wr-itil:work-problems` skill cannot continue a Codex-native backlog drain when the unrelated Claude CLI quota is exhausted, so a core plugin workflow fails for an installed user even though the active runtime has capacity. Likelihood 5: the report reproduces the failure after the ChatGPT/Codex quota refreshed while the drain still stopped on the Claude CLI weekly limit, and describes the dispatch as applying to every isolated iteration in ChatGPT/Codex sessions.
**Origin**: internal
**Effort**: M — derived at capture. Runtime selection must change without weakening the existing isolation wrapper, governance gates, clean-state checks, idle recovery, optional cost metadata, or the one-ticket `ITERATION_SUMMARY` contract, and needs behavioural coverage for both Codex and Claude Code dispatch arms.
**WSJF**: 20 — (20 × 2.0) / 2
**JTBD**: JTBD-006
**Persona**: developer

## Description

The installed `@windyroad/itil` 2.1.0 Codex projection of `/wr-itil:work-problems` cannot dispatch an isolated iteration through the Codex CLI after that CLI's quota refreshes. Its authored Codex contract instead requires a native Codex subagent and explicitly says: `Never invoke codex exec, start a nested Codex CLI, or implement process/PID polling.`

That prohibition removes the runtime-native process boundary available to a Codex session. The Claude Code source contract still uses `claude -p`; it remains canonical for Claude Code and is not the defect being changed here. The Codex projection needs its own `codex exec` adapter while preserving one-ticket isolation, governance hooks and plugins, suppression guards, exact-checkout handling, clean-state recovery, quota/error classification, retro-on-exit, and the `ITERATION_SUMMARY` hand-back.

## Symptoms

- Installed `skills-codex/work-problems/SKILL.md` line 19 forbids `codex exec`.
- The same installed contract's Loop step 4 dispatches a native Codex subagent rather than a fresh CLI process.
- A Codex CLI quota refresh therefore cannot restore iteration capacity through the installed drain contract; the contract forbids the only path that would start a fresh Codex CLI iteration against that quota.

## Workaround

Invoke `/wr-itil:work-problem 529` directly in a foreground Codex session with available capacity. The singular flow works one ticket in the current session and avoids the plural drain's prohibited nested-dispatch path. Preserve the exact checkout and unrelated work manually until the Codex-specific iteration adapter ships.

## Impact Assessment

- **Who is affected**: developers running `/wr-itil:work-problems` from ChatGPT/Codex who need a fresh Codex CLI process to continue the drain.
- **Frequency**: every installed 2.1.0 Codex drain; the prohibition is unconditional in the generated skill.
- **Severity**: Significant — an installed core workflow cannot use available runtime quota, but foreground singular work remains available.
- **Analytics**: direct installed-contract inspection and the RED command below; no telemetry is required.

## Root Cause Analysis

### Root cause (confirmed 2026-08-29)

`packages/itil/scripts/sync-codex-skills.mjs` selects `packages/itil/scripts/codex-work-problems.md` as a wholesale runtime-specific source for this one skill. The generated installed skill therefore does not inherit the canonical Claude Code Step 5 subprocess wrapper.

The authored Codex overlay replaced that wrapper with native-subagent prose and added an explicit nested-CLI prohibition. That is the controlling defect: the installed contract cannot select `codex exec` even when the Codex CLI has usable quota. This is not a Claude Code source defect and does not require changing ADR-094's loop-anchor decision.

### Reproduction (RED, installed 2.1.0)

Run against the installed artifact:

```bash
if rg -n 'Never invoke `codex exec`' \
  /Users/tomhoward/.codex/plugins/cache/windyroad-itil-local/wr-itil/2.1.0/skills-codex/work-problems/SKILL.md; then
  echo 'RED: installed Codex work-problems forbids runtime-native codex exec' >&2
  exit 1
fi
```

Observed 2026-08-29: exit 1, with the prohibition matched on installed line 19. This is RED because the required Codex-native dispatch contract must permit and execute one nested `codex exec` iteration.

### Investigation Tasks

- [x] Investigate root cause
- [x] Create reproduction test — installed-contract RED command above
- [x] Identify a workaround — foreground `/wr-itil:work-problem 529`
- [x] Draw RFC-075 and attach accepted STORY-069 tracing P529 and JTBD-006 on confirmed STORY-MAP-002
- [x] Implement and behaviourally verify the Codex-specific adapter — the packed installed-skill smoke launched a real outer Codex, dispatched exactly one fake nested Codex for P529 in the exact checkout, kept the fail-fast fake Claude unused, and consumed separate JSONL progress plus the final-output sentinel summary.

## Fix Strategy

RFC-075 — *Use available Codex capacity for isolated backlog iterations* — is a release row on confirmed STORY-MAP-002 under activity D, *Implement the changes*. It carries in-progress STORY-069, *Drain one Codex ticket through an isolated Codex CLI*.

The row limits the fix to the Codex projection/adapter: one exact-checkout `codex exec` iteration, governance and suppression controls, separate JSONL metadata plus final-output `ITERATION_SUMMARY`, path-scoped recovery, error classification, retro-on-exit, and an installed-artifact behavioural test. The canonical Claude Code branch and ADR-094 remain unchanged.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: (none)

## Related

- **Architecture review**: PASS on 2026-08-29. ADR-083 permits a package-local Codex adapter while Claude Code remains unchanged; ADR-032's isolation intent remains mandatory; ADR-019 requires path-scoped recovery; ADR-103 permits a row/story on confirmed STORY-MAP-002; ADR-094 is unchanged.
- **Upstream report pending** -- false positive; detection misfire. `@windyroad/itil` is the package owned by this repository, not an external dependency.

Captured via `/wr-itil:capture-problem`. Hang-off arbitration was not dispatched: the mechanical pre-filter found 93 open or verifying tickets sharing the `/wr-itil:work-problems` signal, above the five-candidate latency cap. Review-time re-evaluation candidates: P035, P065, P070, P087, P096, P102, P104, P124, P126, P131, P136, P137, P140, P142, P143, P144, P151, P152, P154, P162, P168, P170, P172, P173, P175, P176, P177, P178, P179, P185, P207, P213, P220, P232, P247, P248, P251, P261, P268, P272, P273, P274, P275, P276, P278, P279, P308, P314, P315, P330, P333, P343, P346, P350, P351, P358, P361, P370, P373, P374, P375, P376, P382, P385, P386, P389, P390, P398, P399, P401, P402, P404, P412, P413, P416, P424, P427, P428, P430, P434, P441, P443, P448, P451, P456, P464, P467, P470, P473, P502, P516, P517, and P528.

The title-only duplicate check matched P036, P040, P041, P053, P077, P083, P084, P089, P103, P104, P109, P122, P126, P130, P138, P140, P206, P210, P211, P212, P214, P221, P250, P307, P308, P333, P341, P344, P382, P385, P386, P413, P427, P428, P441, P451, and P528. None names native runtime CLI selection; `/wr-itil:review-problems` owns any later merge decision.


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-069 | STORY-069: Drain one Codex ticket through an isolated Codex CLI | in-progress |
