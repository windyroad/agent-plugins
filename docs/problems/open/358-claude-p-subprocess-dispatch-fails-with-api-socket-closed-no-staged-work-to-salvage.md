# Problem 358: `claude -p` subprocess dispatch fails with API "socket connection closed unexpectedly" — no staged work survives, P261 salvage path does not apply

**Status**: Open
**Reported**: 2026-06-10
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-006
**Persona**: developer

## Description

`claude -p` subprocess dispatches fail mid-stream with `API Error: The socket connection was closed unexpectedly. For more information, pass \`verbose: true\` in the second argument to fetch()` — distinct from P261 stream-idle-timeout because no staged work survives, so the documented P261 salvage path does not apply.

Observed twice consecutively in the same orchestrator main-turn session window (2026-06-10 `/wr-itil:work-problems` session):

1. **Step 0b inbound-discovery pre-flight iter** invoking `/wr-itil:review-problems` failed at 23 turns / -.89 / 1202s wall-clock with `is_error=true` + `stop_reason=stop_sequence` + `.result` body containing the verbatim error message (`.afk-run-state/iter-step0b-review-problems.json`). The iter had partially refreshed `docs/problems/.upstream-cache.json` (valid JSON, `last_checked=2026-06-10T07:32:46Z`) but had NOT staged the file — orchestrator reverted the dirty mod to keep working tree clean.

2. **Iter 1 dispatch against P288** failed at 9 turns / -.89 / 727s wall-clock with identical error shape (`.afk-run-state/iter-p288.json`); nothing modified, nothing staged.

The orchestrator main-turn itself ran cleanly throughout — multiple Agent-tool delegations (hang-off-check, wip, pipeline, external-comms, voice-tone subagents), Skill tool invocations (run-retro, capture-problem), Edit + Write + Bash + AskUserQuestion all worked. The failure path is specific to the `claude -p` subprocess dispatch surface.

**SKILL-contract gap (orthogonal observation)**: `/wr-itil:work-problems` Step 0b prose does not explicitly describe what the orchestrator should do when the Step 0b pre-flight subprocess returns `is_error=true`. Step 5 documents non-zero exit-code halt for iters, but Step 0b is a pre-flight (semantically distinct — a cache-refresh dependency, not an iter of the loop body). The orchestrator improvised: discard the partial cache write, proceed to Step 1 since the pre-flight is not load-bearing for backlog scan. Documenting the contract would close the ambiguity.

Recurring class-of-behaviour (2 occurrences this session) auto-ticketed per P342 mechanical-stage carve-out from `/wr-retrospective:run-retro` Step 4b Stage 1.

## Symptoms

(deferred to investigation)

- Both failures produced `is_error: true` JSON envelopes (1314-1886 bytes — NOT the P147 stuck-before-emit 0-byte JSON shape; metadata WAS preserved on socket-closed exit).
- Both failures preserved `usage.*` cost metadata (cumulative `total_cost_usd` correct per the Step 5 Authority Hierarchy contract).
- Neither failure had staged work — the P261 salvage carve-out requires `git diff --cached --name-only` to be non-empty, which neither dispatch satisfied.
- Wall-clock duration before failure: 727s (iter 1) and 1202s (Step 0b) — both well under the `IDLE_TIMEOUT_S=3600` SIGTERM threshold; the SIGTERM mechanism did NOT fire because the subprocess exited on its own (orchestrator's idle-timeout poll loop observed normal `kill -0` exit).

## Workaround

(deferred to investigation)

- Orchestrator improvised: treated the Step 0b failure as a non-load-bearing pre-flight failure, reverted the dirty cache write (clean working tree), and continued to Step 1. Iter 1 dispatch then failed identically; orchestrator halted the loop per Step 5 exit-code halt rule.
- For the user-invoked `/wr-itil:capture-problem` that ran in the same session window: the main-turn invocation worked fine (no subprocess involved), so the capture commit landed (`57ca021`).

## Impact Assessment

- **Who is affected**: (deferred to investigation)
- **Frequency**: (deferred to investigation) — 2 occurrences in one session is high enough to be worth tracking; not enough data to claim the failure rate
- **Severity**: (deferred to investigation)
- **Analytics**: (deferred to investigation) — `.afk-run-state/iter-step0b-review-problems.json` + `.afk-run-state/iter-p288.json` capture the two failure envelopes verbatim

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Investigate root cause: is the socket-closed error correlated with subprocess invocation count, wall-clock duration, prompt size, or upstream API instability? Check whether the network path between `claude -p` and the Anthropic API has known instability windows.
- [ ] Distinguish from P261 (stream-idle-timeout, staged-work salvage applies) and P147 (SIGTERM stuck-before-emit, 0-byte JSON). This is a third failure class: clean exit-with-error-flush BUT no staged work to salvage.
- [ ] Propose a retry policy: should the orchestrator auto-retry a Step 0b pre-flight failure (cache-refresh is idempotent, retry-safe) before halting? Should the orchestrator auto-retry an iter dispatch failure ONCE before halting? The 2x identical failure shape this session suggests retries may not help if the underlying issue is upstream API instability.
- [ ] Document the orthogonal SKILL-contract gap on `/wr-itil:work-problems` Step 0b prose: explicit handling for `is_error: true` from Step 0b pre-flight subprocess. Suggested rule: pre-flight failure is non-blocking (revert any dirty state, log the failure, proceed to Step 1); iter failure is the existing Step 5 halt rule (the iter IS the loop body unit).
- [ ] Create reproduction test (likely hard — failure is upstream API state, not deterministic from input).

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P261 (stream-idle-timeout salvage — sibling class, different recovery path), P147 (stuck-before-emit, sibling-third class), P121 (SIGTERM idle-timeout — different recovery mechanism), P146 + P232 (polling-antipattern sibling — different failure family but same AFK orchestrator surface).

## Related

(captured via /wr-itil:capture-problem; sub-step 2b hang-off-check SKIPPED via candidate-cap short-circuit because the description referenced many shared signals — review-time hang-off re-evaluation at next /wr-itil:review-problems is the documented audit-trail path.)

Sibling-candidate tickets (shared subprocess-dispatch / AFK orchestrator surface — review at next /wr-itil:review-problems for absorb-vs-sibling arbitration):

- **P261** (`docs/problems/verifying/261-iter-subprocess-api-stream-timeout-class-orchestrator-salvage-path-needs-documentation.md`) — stream-idle-timeout salvage path; this ticket is the SIBLING class where salvage does NOT apply (no staged work).
- **P147** (`docs/problems/closed/147-...md`) — SIGTERM stuck-before-emit, 0-byte JSON, metadata lost; this ticket is the THIRD sibling class (metadata preserved, no staged work).
- **P121** (`docs/problems/closed/121-...md`) — SIGTERM idle-timeout recovery for stuck subprocesses; the timeout did NOT fire here (sub-1200s wall-clock).
- **P146** + **P232** — bash polling antipatterns; different failure family but same `claude -p` dispatch surface.
- **P086** + **P088** + **P089** — historical work-problems Step 5 dispatch robustness tickets.
- **ADR-032** — subprocess-boundary contract; this ticket may surface a new ADR-032 amendment depending on the investigation outcome (retry policy + pre-flight failure handling).

Related framework references in the description (not duplicate candidates — citation context):

- **P342** (`docs/problems/open/342-...md`) — mechanical-stage carve-out drove the auto-ticket path from /wr-retrospective:run-retro Step 4b Stage 1.
- **P288** — the iter 1 target that failed.
- **/wr-itil:review-problems**, **/wr-itil:work-problems**, **/wr-retrospective:run-retro** — affected skill surfaces.
- **JTBD-006** (Progress the Backlog While I'm Away) — anchor JTBD; subprocess instability degrades AFK throughput.

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-024 | proposed | work-problems pre-flight subprocess failure handling — non-blocking revert-and-proceed |
