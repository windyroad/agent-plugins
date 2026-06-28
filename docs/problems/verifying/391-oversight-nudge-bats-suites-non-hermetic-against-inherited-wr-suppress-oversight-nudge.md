# Problem 391: oversight-nudge bats suites are non-hermetic against an inherited WR_SUPPRESS_OVERSIGHT_NUDGE — false reds inside AFK iters

**Status**: Verifying
**Reported**: 2026-06-27
**Fix applied**: 2026-06-28 (test-only, no release)
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: S (confirmed — 4 one-line `unset` additions to bats `setup()`)
**JTBD**: JTBD-001
**Persona**: developer

## Description

Type: pipeline-instability / test-hermeticity flake (sibling class of the LC_ALL=C em-dash bats flake and P193 non-deterministic bats).

Both oversight-nudge bats suites — `packages/jtbd/hooks/test/jtbd-oversight-nudge.bats` AND the architect sibling `packages/architect/hooks/test/architect-oversight-nudge.bats` — do not control the `WR_SUPPRESS_OVERSIGHT_NUDGE` environment variable in their `setup()`. The count-emitting tests invoke the hook via `run env CLAUDE_PROJECT_DIR=... bash "$HOOK"` WITHOUT unsetting that guard. The hook self-suppresses (exit 0, no output) when `WR_SUPPRESS_OVERSIGHT_NUDGE=1`. The AFK `/wr-itil:work-problems` orchestrator EXPORTS `WR_SUPPRESS_OVERSIGHT_NUDGE=1` (Step 5, the shared suite-wide oversight-nudge AFK guard). So when these suites run inside an AFK iter subprocess, the exported guard leaks into the bats subprocess and the count-emitting tests self-suppress, producing spurious failures:

- `jtbd-oversight-nudge.bats` test 1 ("emits a count line when there are unoversighted jobs/personas") and test 2 ("uses singular wording for exactly one unoversighted artifact").
- `architect-oversight-nudge.bats` the equivalent two count-emitting tests.

Evidence (P288 verify-and-transition iter, 2026-06-27): running `npx bats packages/jtbd/hooks/test/jtbd-oversight-nudge.bats` in the AFK iter env produced `not ok 1` / `not ok 2` with `[[ "$output" == *"2 jobs/personas lack human oversight"* ]]' failed`. `bash -x` of the hook showed `'[' 1 = 1 ']'` → `exit 0` (the guard branch). Re-running with `env -u WR_SUPPRESS_OVERSIGHT_NUDGE npx bats ...` → 6/6 green. The architect sibling reproduced identically (`not ok 2` count tests fail under the inherited guard). CI is GREEN because CI does not export the guard — the flake is invisible outside AFK iters. The shipped hook is correct; this is purely a test-hermeticity defect.

Impact: false reds during AFK work-problems iters that run these suites (e.g. a verify-and-transition iter spot-checking the suite, or any iter running `npm test`). Masks real failures and wastes iter cycles diagnosing a non-bug. Likelihood: every AFK iter that runs either suite while the orchestrator guard is exported.

## Symptoms

(deferred to investigation)

## Workaround

Run with `env -u WR_SUPPRESS_OVERSIGHT_NUDGE` (or run the suites outside an AFK orchestrator session).

## Impact Assessment

- **Who is affected**: (deferred to investigation)
- **Frequency**: (deferred to investigation)
- **Severity**: (deferred to investigation)
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Add `unset WR_SUPPRESS_OVERSIGHT_NUDGE` to the `setup()` of `packages/jtbd/hooks/test/jtbd-oversight-nudge.bats` so the guard is test-controlled (count tests stop self-suppressing under inherited guard).
- [x] Apply the identical fix to the architect sibling `packages/architect/hooks/test/architect-oversight-nudge.bats`.
- [x] Confirm the guard-specific tests (which set `WR_SUPPRESS_OVERSIGHT_NUDGE=1` and `=0` explicitly) still pass after the setup() unset.
- [x] Generalise: audit other hook bats suites whose hook branches on an env guard the AFK orchestrator exports; neutralise the guard in setup(). **Audit result**: the four oversight/scaffold-nudge suites below all branch on `WR_SUPPRESS_OVERSIGHT_NUDGE` and lacked the unset — all fixed. The fifth candidate `packages/itil/hooks/test/itil-pending-questions-surface.bats` already `unset`s its guard (`WR_SUPPRESS_PENDING_QUESTIONS`) in `setup()` + `teardown()` — it is the reference pattern this fix generalises. No further suites are exposed (grep for `WR_SUPPRESS_*` across `packages/*/hooks/test/*.bats` returns exactly these five). Brief in `afk-subprocess.md` / `governance-workflow.md` deferred to retro Tier-3.

## Resolution

Added `unset WR_SUPPRESS_OVERSIGHT_NUDGE` to the `setup()` of all four affected suites:
- `packages/jtbd/hooks/test/jtbd-oversight-nudge.bats`
- `packages/architect/hooks/test/architect-oversight-nudge.bats`
- `packages/itil/hooks/test/itil-rfc-oversight-nudge.bats`
- `packages/risk-scorer/hooks/test/risk-scorer-scaffold-nudge.bats`

**Verification (in-session, 2026-06-28)** — reproduced the exact AFK-iter failing condition by exporting `WR_SUPPRESS_OVERSIGHT_NUDGE=1 WR_SUPPRESS_PENDING_QUESTIONS=1` into the bats environment:
- Pre-fix: `not ok` on the six count-emitting tests (jtbd 1/2, architect 7/8, itil-rfc 13/14, risk-scorer 20/23/24).
- Post-fix: **30 ok / 0 not ok** under the exported guard (the AFK condition) AND 30/30 under `env -u` (the CI condition). Guard-specific tests (`run env WR_SUPPRESS_OVERSIGHT_NUDGE=1/0/yes`) unaffected — per-invocation env overrides the `setup()` unset.

Test-only change — no shipped hook modified, no changeset, no release. None of the four are `packages/shared` synced copies (package-local hooks), so no sync-script run owed.

## Fix Strategy

- **Kind** — `improve`
- **Shape** — `test fixture` (bats setup() hardening across two sibling suites)
- **Target files** — `packages/jtbd/hooks/test/jtbd-oversight-nudge.bats`, `packages/architect/hooks/test/architect-oversight-nudge.bats`
- **Observed flaw** — count-emitting tests inherit the AFK orchestrator's exported `WR_SUPPRESS_OVERSIGHT_NUDGE=1` and self-suppress, failing spuriously inside AFK iters.
- **Edit summary** — add `unset WR_SUPPRESS_OVERSIGHT_NUDGE` to each suite's `setup()` so the guard is test-controlled; guard-specific tests set it explicitly and are unaffected.
- **Evidence** — P288 iter 2026-06-27: `not ok 1/2` under inherited guard; `env -u WR_SUPPRESS_OVERSIGHT_NUDGE` → 6/6 green; architect sibling reproduced.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P288 (surfaced during its verify-and-transition iter).

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)

- **P288** — surfaced during its verify-and-transition iter; both packages affected.
- The `LC_ALL=C` em-dash bats flake (memory `feedback_bats_gather_flakes_on_multibyte_test_names`) — sibling test-hermeticity class (byte-mode vs env-guard isolation).
- **P193** — non-deterministic bats (TTL boundary) — adjacent flake class.
