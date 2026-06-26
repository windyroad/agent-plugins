# Problem 382: work-problems `claude -p` iter subprocesses miss project-scoped governance plugins (need `--plugin-dir` in dispatch)

**Status**: Open
**Reported**: 2026-06-26
**Priority**: 16 (High) — Impact: 4 x Likelihood: 4
**Origin**: inbound-reported (#274)
**Effort**: L
**JTBD**: JTBD-001
**Persona**: plugin-developer

## Description

In `/wr-itil:work-problems`, the AFK orchestrator dispatches each iteration to a fresh `claude -p` subprocess (Step 5 dispatch contract, ADR-032). The contract assumes the subprocess has the full governance surface — architect / jtbd / risk-scorer / voice-tone agents, the commit-gate + external-comms-gate hooks, and `/wr-retrospective:run-retro`. In practice, headless `claude -p` loads only user-scoped `enabledPlugins`, not project-scoped ones. When the windyroad plugins are enabled at project scope (the common adopter setup), the iter subprocess receives no windyroad agents/hooks; it commits work ungated and cannot run retro-on-exit.

## Symptoms

- A subprocess `Task(subagent_type "wr-architect:agent", ...)` returns `Agent type 'wr-architect:agent' not found` (only user-scoped marketplace agents available).
- The subprocess commits changeset/code work without architect/jtbd/risk/voice-tone review; retro-on-exit is unavailable.

## Workaround

Orchestrator-layer compensation: the interactive orchestrator turn (which loads both project + user scopes) re-runs the governance reviews on release-bearing iter output before pushing/releasing. Covers only what the orchestrator inspects.

## Impact Assessment

- **Who is affected**: any adopter running AFK work-problems with windyroad plugins at project scope.
- **Frequency**: every AFK iteration in such projects.
- **Severity**: ungated commits during iters; governance bypass unless the orchestrator re-inspects at release.

## Root Cause Analysis

Headless `claude -p` does not activate project-scoped plugins (project-plugin activation is trust-gated; headless skips trust). `--setting-sources user,project` alone is insufficient; `--plugin-dir <marketplace>/packages/<plugin>` does make the plugin available.

### Investigation Tasks

- [ ] Have Step 5 `claude -p` dispatch pass `--plugin-dir` for each governance plugin it needs, derived from the installed marketplace path
- [ ] Resolve the marketplace path portably (ADR-049 PATH-shim spirit — must work in adopter trees, not just the source monorepo)
- [ ] Behavioural test: dispatched subprocess can resolve `wr-architect:agent` and fire the commit-gate hook
- [ ] Confirm retro-on-exit is reachable in the dispatched subprocess

## Dependencies

- **Blocks**: trustworthy AFK governance (commits ship gated from within iters, not just at orchestrator re-inspection)
- **Blocked by**: (none)
- **Composes with**: ADR-032 (governance-skill invocation patterns / dispatch contract)

## Related

- **Upstream**: windyroad/agent-plugins#274 — verified 2026-06-21 (`--plugin-dir <marketplace>/packages/architect` makes the agent available; `--setting-sources user,project` does not).
- **ADR-032** — Step 5 `claude -p` dispatch contract is the locus.
- `packages/itil/skills/work-problems/SKILL.md` — Step 5 dispatch.
- Inbound-reported from a downstream consumer (tracked as P244 in that downstream project — distinct from the local P244 maturity-shim ticket).
