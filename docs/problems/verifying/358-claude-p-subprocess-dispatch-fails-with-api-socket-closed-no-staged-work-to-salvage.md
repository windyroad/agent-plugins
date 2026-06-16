# Problem 358: `claude -p` subprocess dispatch fails with API "socket connection closed unexpectedly" — no staged work survives, P261 salvage path does not apply

**Status**: Verification Pending
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

**Framing reconciliation (2026-06-16, iter-29 — new empirical evidence).** The title premise "no staged work survives, P261 salvage path does not apply" is INCOMPLETE. The `socket connection was closed unexpectedly` error is just another `is_error: true` shape, already taxonomised by the Step 5 exit-code semantics: **SALVAGE** when staged coherent work survives (P261), **HALT-with-advisory** when nothing staged (P214 — which the socket-closed catch-all advisory matches). The two original 2026-06-10 occurrences happened to have NO staged work, so they routed to HALT — but that is sub-class (b), not the whole class. Iter-24 of the 2026-06-16 session hit this EXACT socket-closed `is_error: true` failure mid-iter, but the iter HAD staged coherent work (5 files modified + 7/7 GREEN bats); the orchestrator main turn SALVAGED it per the P261 carve-out (commit `60e94d2a`) — sub-class (a). So the socket-closed shape is NOT a new failure class; the Step 5 SALVAGE/HALT taxonomy already covers both iter sub-classes. The **genuinely-novel, actionable** gap P358 surfaces is the ORTHOGONAL one named in the "SKILL-contract gap" paragraph above: the Step 0b/0c/0d **pre-flight** subprocess `is_error: true` / non-zero-exit handling was undocumented. That is the fix this ticket ships (RFC-024).

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

**Confirmed (iter-29, 2026-06-16).** Two distinct concerns were conflated in the original capture:

1. **The `is_error: true` socket-closed failure mode of `claude -p` itself** is upstream API/network instability — not deterministic from input, not reproducible on demand, and already handled at the **iter** surface by the Step 5 exit-code semantics (SALVAGE per P261 when staged coherent work survives — confirmed live this session via iter-24 salvage commit `60e94d2a`; HALT-with-advisory per P214 when nothing staged — the socket-closed shape routes to the `any other is_error: true` catch-all advisory). No SKILL change is needed for the iter surface; the taxonomy already covers both sub-classes. A retry policy for the transient classes remains deferred to the P214 Phase-2 amendment (out of scope here).

2. **The orthogonal, actionable gap (this ticket's fix)**: Step 0b/0c/0d each dispatch a `/wr-itil:review-problems` (or `check-upstream-responses`) **pre-flight** subprocess "same shape as Step 5", but none documented what to do when that pre-flight returns non-zero exit / `is_error: true`. A literal reading of Step 5's "non-zero → halt the loop" would halt the whole AFK loop on a non-load-bearing cache-refresh hiccup. The orchestrator improvised the correct recovery (reverted the dirty unstaged cache write, proceeded to Step 1); the contract did not name it. **Root cause of the gap: the "same shape as Step 5" prose imported the dispatch mechanism without the failure semantics, leaving the iter-vs-pre-flight role distinction implicit.**

A behavioural reproduction of the pre-flight contract exists (`work-problems-preflight-failure-handling.bats`, 11/11 GREEN); it also caught a real robustness bug — the combined `git checkout -- docs/problems/ docs/audits/` revert reverts NOTHING when `docs/audits/` is absent on a fresh adopter repo, so the contract now specifies per-path-tolerant reverts.

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Investigate root cause: socket-closed is upstream API/network instability; not deterministic. Already handled at the iter surface by Step 5 SALVAGE/HALT taxonomy. (Confirmed iter-29.)
- [x] Distinguish from P261 (stream-idle-timeout, staged-work salvage applies) and P147 (SIGTERM stuck-before-emit, 0-byte JSON). Reconciled: socket-closed is NOT a new iter class — it is an `is_error: true` instance already covered by P261 SALVAGE (sub-class a, staged) + P214 HALT (sub-class b, no-staged). The novel axis is iter-vs-pre-flight role, not a new error class.
- [~] Propose a retry policy for transient pre-flight/iter failures — deferred to the P214 Phase-2 amendment (Phase 1 is HALT/revert-with-advisory only); not in scope for this fix.
- [x] Document the orthogonal SKILL-contract gap on `/wr-itil:work-problems` pre-flight prose: explicit non-blocking revert-and-proceed handling for `is_error: true` / non-zero exit from a Step 0b/0c/0d pre-flight subprocess. (Shipped — see Fix Strategy.)
- [x] Create reproduction test. (`work-problems-preflight-failure-handling.bats` — behavioural revert-and-proceed contract + doc-lint slice; 11/11 GREEN.)

## Fix Strategy

**Vehicle**: RFC-024 (work-problems pre-flight subprocess failure handling — non-blocking revert-and-proceed). The fix documents the **pre-flight subprocess failure contract**, orthogonal to the Step 5 iter SALVAGE/HALT taxonomy:

- `packages/itil/skills/work-problems/SKILL.md` — new shared subsection "Step 0 pre-flight subprocess failure handling (P358)" after Step 0d (general rule, any future Step 0x inherits it) + forward-pointer clauses in each Step 0b/0c/0d dispatch-shape paragraph. Contract: a pre-flight that exits non-zero OR returns `is_error: true` is NON-BLOCKING — revert any dirty (unstaged) partial write per-path-tolerant (`git checkout -- docs/problems/ 2>/dev/null; git checkout -- docs/audits/ 2>/dev/null`), `git reset` any staged residue first (ADR-009 no-trust-window-extension), log a one-line annotation, proceed to Step 1 with the existing README. The Step 5 SALVAGE branch does NOT apply to a pre-flight.
- `docs/decisions/032-governance-skill-invocation-patterns.proposed.md` — additive amendment "Pre-flight subprocess failure handling — non-blocking revert-and-proceed (P358 amendment, 2026-06-16)" in the AFK-iteration-isolation-wrapper series; documents the iter-vs-pre-flight failure-semantics axis as orthogonal to the P261/P214 SALVAGE-vs-HALT axis.
- `packages/itil/skills/work-problems/test/work-problems-preflight-failure-handling.bats` — behavioural fixture (11/11 GREEN).
- `.changeset/` — `@windyroad/itil` patch.

**Release vehicle**: .changeset/p358-preflight-subprocess-failure-handling.md

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

## Fix Released

Fix committed this AFK iteration (iter-29, 2026-06-16). Release marker: `@windyroad/itil` patch changeset `.changeset/p358-preflight-subprocess-failure-handling.md`; **release drain deferred** per the AFK no-push/no-release constraint (the orchestrator's Step 6.5 release-cadence check — or a later interactive release — drains it). The orthogonal SKILL-contract gap is closed: `packages/itil/skills/work-problems/SKILL.md` now carries the shared "Step 0 pre-flight subprocess failure handling (P358)" subsection (non-blocking revert-and-proceed, general rule + 0b/0c/0d forward-pointers), ADR-032 carries the "Pre-flight subprocess failure handling — non-blocking revert-and-proceed (P358 amendment, 2026-06-16)" section (iter-vs-pre-flight failure-semantics axis, orthogonal to the P261/P214 SALVAGE/HALT iter axis), and `work-problems-preflight-failure-handling.bats` pins the contract.

**Exercised in-session**: the behavioural fixture `work-problems-preflight-failure-handling.bats` ran 11/11 GREEN (4 behavioural revert-and-proceed branch cases via a fake socket-closed shim + 7 doc-lint contract assertions); the full work-problems suite ran with 0 failures (reached test 466) — no regression from the SKILL.md edits. The fixture also caught a real robustness bug (combined `git checkout -- A B` reverts nothing when one path is absent), now fixed to per-path-tolerant reverts in both SKILL prose and the harness. Awaiting user verification of the contract on the next real pre-flight subprocess failure.
