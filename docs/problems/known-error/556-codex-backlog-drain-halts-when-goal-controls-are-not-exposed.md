# Problem 556: Codex backlog drain halts when Goal controls are not exposed

**Status**: Known Error
**Reported**: 2026-10-14
**Priority**: 15 (High) — Impact 3 × Likelihood 5. The affected capability-limited surface stops all backlog work before its first iteration; the unconditional projection instruction repeats on each invocation on that surface. No repository corruption was observed.
**Origin**: internal
**Effort**: S — correct the Codex overlay's capability branch and protect its generated artifact and model behavior; reuse the existing map, job, and fix vehicle.
**WSJF**: 30 — (15 × Known Error multiplier 2.0) / 1
**JTBD**: JTBD-006
**Persona**: developer

## Description

The installed `@windyroad/itil@3.0.1` Codex `work-problems` contract requires
`thread/goal/get` and `thread/goal/set` before loop entry without checking whether
the running session can call them. An invocation in a chat exposing only the
Goal stop control completed its backlog maintenance checks, then halted before
dispatching any problem because get/set were unavailable.

This contradicts ADR-094's existing never-halt rule and the canonical skill's
requirements-floor fallback: a missing external anchor is disclosed, while the
loop continues with unconditional Gate (0) completion checks.

## Symptoms

- Backlog preflight succeeds, but the first iteration is never dispatched.
- The report incorrectly treats missing optional anchoring capability as a
  mandatory repository Hard-fail gate.
- Local CLI protocol schemas expose Goal methods, but this does not make those
  methods callable on the current chat or bind another thread's Goal to it.

## Workaround

Apply ADR-094's already-approved unanchored fallback: disclose the missing
get/set controls once, continue work, and retain the unconditional fresh Gate
(0) classification and zero-dispatchable evidence before `ALL_DONE`. Do not
claim a Goal was set or use an unrelated thread to manufacture one.

## Impact Assessment

- **Who is affected**: developers using the unattended backlog workflow on
  Codex-compatible surfaces without callable Goal get/set controls.
- **Frequency**: each invocation on that capability-limited surface.
- **Severity**: High workflow interruption; no damaged checkout was observed.
- **Analytics**: one directly observed stopped invocation; broader prevalence
  has not been measured.

## Root Cause Analysis

The Codex build substitutes `packages/itil/scripts/codex-work-problems.md` for
the canonical skill body. The P528 correction added the active native Goal
lifecycle, but the overlay omitted the canonical source's capability floor and
honest degradation. The generated skill therefore promoted defense-in-depth
into an unconditional prerequisite. Missing clear capability has the same
truthfulness boundary: preserve actual terminal evidence and disclose that the
Goal could not be cleared instead of inventing a successful clear or a failure.

### Investigation Tasks

- [x] Reproduce the pre-iteration halt and distinguish current-session callable
  tools from the installed CLI's protocol schema.
- [x] Confirm ADR-094 Rule 6 and canonical Step 0e permit unanchored continuation.
- [x] Exercise the generated skill with positive and capability-limited model
  cases; exclude structural prose assertions from the regression suite.
- [x] Review the correction against the existing architecture; no new decision
  or change to approved map activities or jobs is required.
- [ ] Complete positive and capability-limited model evaluations and release
  qualification.
- [ ] Verify the installed correction dispatches work on an affected surface.

## Fix Strategy

RFC-076, **Keep the Codex backlog drain running until no dispatchable work
remains**, is the existing fix vehicle on STORY-MAP-011 activity `close`.
STORY-105 implements the missing capability branch without changing the
canonical condition, positive native Goal lifecycle, or repository gates.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P528

## Verification Notes

The generated Codex skill passed all ten selected model cases locally: five
native Goal lifecycle cases and five capability cases covering missing,
partial, stop-only, other-thread, and unavailable-clear controls. The existing
provider now builds and loads the generated skill through the supported sync
script. There were ten passes, zero assertion failures, and zero provider errors.

Architecture, JTBD, voice, style, accessibility, and behavioral-test reviews
passed. These model simulations do not establish adoption by an already-running
affected chat. Full-suite qualification and release delivery are in progress;
the correction remains unreleased.

## Related

- P528, **Codex projection of work-problems drops the Goal loop-anchor**,
  introduced the active native Goal contract; this failure is the missing
  capability-limited branch of that released contract.
- ADR-094, **AFK loops anchor completion with the native Goal evaluator**,
  Rule 6: an unanchored loop still runs.
- ADR-083, **Codex CLI as second runtime**, and ADR-128, **Per-ticket goal
  anchors each AFK iteration**.
- **Hang-off check**: fresh read-only arbiter returned `PROCEED_NEW`; P528 fixes
  omission of an available anchor, while this observation fixes the released
  anchor becoming a prerequisite on a surface that cannot call it.

## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-105 | Keep backlog work moving when Goal controls are unavailable | in-progress |
