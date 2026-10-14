# Problem 556: Codex backlog drain halts when Goal controls are not exposed

**Status**: Closed
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
- [x] Complete positive and capability-limited model evaluations and release
  qualification.
- [x] Verify the installed correction's capability-limited continuation and
  terminal behavior in a fresh session (bounded acceptance evidence below;
  no repository iteration was executed).

## Fix Strategy

RFC-076, **Keep the Codex backlog drain running until no dispatchable work
remains**, is the existing fix vehicle on STORY-MAP-011 activity `close`.
STORY-105 implements the missing capability branch without changing the
canonical condition, positive native Goal lifecycle, or repository gates.

**Release vehicle**: .changeset/itil-goal-capability-fallback.md

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
affected chat. All 4,393 local tests and the 19 focused generator/pack/condition checks passed.
Implementation CI38635951311, preparation CI38638078521, and release PR
CI38638209521 passed both required jobs.

### Fresh installed-runtime acceptance, 2026-10-15

The authorized local teammate reports PASS from fresh ephemeral Codex session
`01a13c9d-9819-7d92-96d7-6c89617af2f3`, running Codex CLI 0.162.0 authenticated
via ChatGPT. The session read the installed `@windyroad/itil@3.0.2` Codex
`skills-codex/work-problems/SKILL.md`. Acceptance result SHA-256:
`92b63fed621166e6a5c9309756e63267d0aaceed25c7ce9a464ef0db117df012`.

With no callable Goal get/set/clear and one dispatchable ticket, the session
selected continuation, a one-time missing-capability notice, and honest
unanchored operation. It did not require permission or restart. Its terminal
case required fresh Step 2.4 Gate (0) classification showing zero dispatchable
tickets before `ALL_DONE`, disclosure that clear was unavailable, and no claim
that a Goal existed or was cleared.

This was a read-only acceptance exercise: no repository workflow, external
service, task creation, or file mutation was allowed. It verifies the installed
skill's continuation and completion decisions, not an executed repository
iteration or hot-reload by the original cloud chat. Documentation CI38641542894
for `22ab0a235ab21e797308ab2b521861e24e50d02d` also passed both required jobs.

## Closure

Closed 2026-10-15 on the cited post-release, fresh installed-runtime acceptance
reported by the authorized local teammate. The do-not-close predicate returned
exit 1 (not blocked). This evidence resolves the reported capability-handling
defect without claiming that the already-running cloud chat adopted the package.

Recovery: rerun `/wr-itil:transition-problem 556 known-error` to reopen if an
affected invocation reveals incomplete continuation or completion behavior.

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
| STORY-105 | Keep backlog work moving when Goal controls are unavailable | done |

## Fix Released

2026-10-15: `@windyroad/itil@3.0.2` published as npm `latest` through
Release38640141948. PR527 merged at
`045b95986af3a40bd6b1475de029f68a1a624d5b`; source implementation is
`462d2e58f904731acb9b71e664a16e28acdfa0f8` and release preparation is
`6a53a90c5f9a4d07fa04b8a4f28f1bba812bfe4d`. The consumed changeset is
`.changeset/itil-goal-capability-fallback.md`.

All 284 files in the published package match a fresh pack of the reviewed
release checkout. The supported installer registered and enabled Codex 3.0.2;
its generated and canonical work-problems skills match the published package.
The user-scope Claude installation is 3.0.2 and its canonical skill matches
reviewed source. These are artifact and installation checks. Actual adoption
and dispatch by the already-running affected cloud chat remain unverified.

Recovery: rerun `/wr-itil:transition-problem 556 known-error` if affected use
shows the fallback is incomplete.
