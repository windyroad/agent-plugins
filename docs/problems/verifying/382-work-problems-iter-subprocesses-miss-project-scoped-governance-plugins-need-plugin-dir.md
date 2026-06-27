# Problem 382: work-problems `claude -p` iter subprocesses miss project-scoped governance plugins (need `--plugin-dir` in dispatch)

**Status**: Verification Pending
**Reported**: 2026-06-26
**Priority**: 16 (High) — Impact: 4 x Likelihood: 4
**Origin**: inbound-reported (#274)
**Effort**: L
**JTBD**: JTBD-001
**Persona**: plugin-developer
**Release vehicle**: .changeset/wr-itil-p382-iter-plugin-dir-injection.md

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

- [x] Have Step 5 `claude -p` dispatch pass `--plugin-dir` for each governance plugin it needs, derived from the installed marketplace path — done: `mapfile -t PLUGIN_DIR_ARGS < <(wr-itil-resolve-governance-plugin-dirs)` + `"${PLUGIN_DIR_ARGS[@]}"` spliced into the `claude -p` invocation.
- [x] Resolve the marketplace path portably (ADR-049 PATH-shim spirit — must work in adopter trees, not just the source monorepo) — done: `resolve-governance-plugin-dirs.sh` discovers each plugin's cache parent from its `bin/` dir on `$PATH` and selects the highest-semver version (ADR-080); no repo-relative `packages/...` path.
- [x] Behavioural test — done: `packages/itil/scripts/test/resolve-governance-plugin-dirs.bats` (token pairs + stale-PATH-order-ignored version selection + missing-plugin skip). Live run confirms the resolver emits `--plugin-dir <root>` for architect/jtbd/risk-scorer/voice-tone/itil/retrospective/style-guide against the real cache, and picks `wr-itil/0.51.2` over the stale-PATH `0.51.0`.
- [x] Confirm retro-on-exit is reachable in the dispatched subprocess — addressed: with the itil + retrospective plugins now `--plugin-dir`-injected, `/wr-retrospective:run-retro` resolves inside the subprocess (P086 retro-on-exit assumption restored). Full end-to-end subprocess verification deferred to post-release dogfood (see Verification below).

## Fix Strategy (implemented)

**Root cause** (verified upstream 2026-06-21): headless `claude -p` activates only USER-scoped `enabledPlugins`. Project-scoped plugins are not activated because project-plugin activation is trust-gated and headless skips the trust prompt; `--setting-sources user,project` does NOT lift that gate. `--plugin-dir <plugin-root>` does make a project-scoped plugin available.

**Fix**:
1. `packages/itil/scripts/resolve-governance-plugin-dirs.sh` (+ ADR-049/ADR-080 bin shim `wr-itil-resolve-governance-plugin-dirs`) — emits `--plugin-dir <root>` line-pairs for the governance plugins (wr-architect, wr-jtbd, wr-risk-scorer, wr-voice-tone, wr-itil, wr-retrospective, wr-style-guide; override via `WR_GOVERNANCE_PLUGINS`). Each plugin's cache parent is discovered from its `bin/` dir on `$PATH`, then the highest-semver version is selected (ADR-080 — `$PATH` order is frozen/stale mid-session, so it is NOT trusted for version selection). Unresolvable plugins are skipped silently (a missing governance plugin must not abort the AFK dispatch).
2. `packages/itil/skills/work-problems/SKILL.md` Step 5 — `mapfile -t PLUGIN_DIR_ARGS < <(wr-itil-resolve-governance-plugin-dirs)` before the `claude -p` call + `"${PLUGIN_DIR_ARGS[@]}"` spliced into it, with a flag-rationale entry. Step 0b/0c/0d pre-flights reference the Step 5 wrapper "same shape as Step 5", so they inherit the expansion by construction.
3. `docs/decisions/032-*.md` — P382 amendment to the AFK iteration-isolation-wrapper dispatch contract (2026-06-27).
4. `.changeset/wr-itil-p382-iter-plugin-dir-injection.md` — `@windyroad/itil` patch.

**Verification**: behavioural bats green (5/5); live resolver output confirmed against the real marketplace cache including the stale-PATH-order override. End-to-end "dispatched subprocess resolves `wr-architect:agent` + fires the commit-gate hook" requires a released cache (the orchestrator dispatches from the installed plugin, not source); confirm on the post-release dogfood iteration after `@windyroad/itil` ships.

## Dependencies

- **Blocks**: trustworthy AFK governance (commits ship gated from within iters, not just at orchestrator re-inspection)
- **Blocked by**: (none)
- **Composes with**: ADR-032 (governance-skill invocation patterns / dispatch contract)

## Related

- **Upstream**: windyroad/agent-plugins#274 — verified 2026-06-21 (`--plugin-dir <marketplace>/packages/architect` makes the agent available; `--setting-sources user,project` does not).
- **ADR-032** — Step 5 `claude -p` dispatch contract is the locus.
- `packages/itil/skills/work-problems/SKILL.md` — Step 5 dispatch.
- Inbound-reported from a downstream consumer (tracked as P244 in that downstream project — distinct from the local P244 maturity-shim ticket).
