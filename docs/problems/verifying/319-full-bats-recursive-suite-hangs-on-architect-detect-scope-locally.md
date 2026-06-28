# Problem 319: Full `bats --recursive` suite hangs locally on architect-detect-scope.bats — no timeout, wedges the whole run

**Status**: Verification Pending
**Reported**: 2026-05-27
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**Root cause identified**: 2026-06-16 (AFK work-problems iter 25). Fix landed; pending release verification.

## Fix Released

Resolved 2026-06-16 — the local-only hang was a missing-stdin-redirect test-fixture defect: `architect-detect.sh` reads `INPUT=$(cat)`, and the scope tests invoked the hook as bare `run bash "$HOOK"` with no stdin redirect, so under a full local `bats --recursive` sweep `cat` blocked on the inherited TTY. Fixed at source by redirecting stdin from `/dev/null` in the affected fixtures (`architect-detect-scope.bats` — all 6 hook invocations now carry `</dev/null`, verified in-file — plus the same-class siblings `jtbd-eval.bats` / `jtbd-eval-scope.bats`). Release marker: **test-infra only** (`hooks/test/*.bats`, tarball-excluded — no npm changeset); verifiable in-repo by running the full `bats --recursive` sweep to completion.

**Awaiting user verification** — confirm the full local `bats --recursive` sweep runs to completion without wedging on `architect-detect-scope.bats`.

## Description

Running the full `npm test` suite (`bats --recursive packages/*/hooks/test/ packages/*/skills/*/test/ ...`) locally **hung indefinitely** on `packages/architect/hooks/test/architect-detect-scope.bats` (test `detect-3a scope text mentions problem files exemption (P029)`). The run wedged ~40 min with no progress and no error before manual `pkill -f bats-core`.

The first full run of the session (background `bphfm6l80`) completed (exit 0, reached test 2402); the re-run (`bubxtlil8`) hung on architect-detect-scope. So it is **intermittent / environmental** (a subprocess the test spawns occasionally never returns), not a deterministic failure. Origin CI ("Run hook tests") passed the same test in the same session — so it is a LOCAL flake, not a real test failure.

**Cost this session**: the hang looked like a stall ("Looks stuck" — user), wasted ~40 min wall-clock, and forced a fallback to running targeted suites instead of the full sweep. A hanging full-suite run is worse than a failing one — it gives no signal and blocks the verify-before-push step.

## Symptoms

- `bats --recursive ...` stops emitting after a test in `architect-detect-scope.bats`; `ps` shows `bats-exec-test ... architect-detect-scope.bats test_detect-3a...` alive but idle for tens of minutes.
- Killing the run requires `pkill -f bats-core` / `pkill -f architect-detect-scope`.
- The same test passes on origin CI and in isolated runs.

## Workaround

Run targeted suites (the specific affected `.bats` files) instead of the full `bats --recursive` sweep; or add a per-test timeout. Avoid relying on the full local sweep as the pre-push verify gate.

## Root Cause Analysis

**Confirmed root cause (2026-06-16):** the hang was a missing-stdin-redirect test-fixture defect, exactly the hypothesis the Investigation Tasks named ("a `read` without stdin redirect in a test fixture"). `architect-detect.sh:16` reads its input via `INPUT=$(cat)`. The scope tests invoked the hook as bare `run bash "$HOOK"` with no stdin redirect. In CI and isolated runs the test's stdin is `/dev/null`, so `cat` gets immediate EOF and returns. In a full local `bats --recursive` sweep the test inherits the interactive terminal, so `cat` blocks forever waiting for input that never arrives — the intermittent local-only hang. This also explains why origin CI and isolated runs always passed.

Reproduced deterministically: running `architect-detect.sh` with an open (never-closing) stdin via a FIFO times out (exit 124 = hang); with `</dev/null` it returns immediately (exit 0).

**Same-class siblings:** the identical defect existed in `packages/jtbd/hooks/test/jtbd-eval.bats` and `packages/jtbd/hooks/test/jtbd-eval-scope.bats` (both invoke `jtbd-eval.sh`, which also reads `INPUT=$(cat)`, via bare `run bash "$HOOK"`). These were latent hangs of the same shape and are fixed in the same pass. A broader sweep of all `packages/*/hooks/test/*.bats` confirmed no fourth instance (`connect/session-start.bats` uses heredocs, not stdin reads — verified it terminates with open stdin).

**Fix:** added a `< /dev/null` stdin redirect to every bare `run bash "$HOOK"` invocation across the three files. This matches the convention already established by sibling hook tests (e.g. `jtbd-eval-once-per-session.bats` pipes `echo "$json" | bash "$HOOK"`) and is endorsed by ADR-005's "Functional pattern". Architect review: PASS (test-fixture conformance fix, no new ADR). JTBD review: PASS (serves JTBD-101 / JTBD-002 — the suite as a reliable pre-push verify gate).

Verified: all 16 tests across the three files pass, and the suite now terminates (exit 0) even when stdin is held open — the exact prior-hang condition.

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems.
- [x] Reproduce: identified the offending command — `INPUT=$(cat)` in the hook under test with no stdin redirect in the fixture (reproduced deterministically via an open-stdin FIFO).
- [x] Fix at source: redirected stdin from `/dev/null` in the test fixtures (the correct locus — the hooks read piped JSON in real use; only the tests forgot the redirect).
- [ ] (Optional, deferred) `npm test` wrapper with a global timeout + wedged-file naming — defence-in-depth only; not required now that the root cause is removed. Deferred to avoid scope creep; re-open if a new hang class surfaces.

## Dependencies

- **Composes with**: the verify-before-push discipline (a hanging suite defeats it).

## Related

- captured via /wr-retrospective:run-retro Step 2b pipeline-instability scan (Repeat-work / Skill-contract friction), 2026-05-27. Witnessed during the RFC-009 full-suite verification (background runs bphfm6l80 completed / bubxtlil8 hung).
