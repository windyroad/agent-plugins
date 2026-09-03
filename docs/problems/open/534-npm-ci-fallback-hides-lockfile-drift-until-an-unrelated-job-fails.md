# Problem 534: The `npm ci || npm install` fallback hides lockfile drift until an unrelated job fails

**Status**: Open
**Reported**: 2026-09-04
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4 — derived at capture from the description per Step 4a
**Origin**: internal
**Effort**: S — derived at capture per Step 4a
**JTBD**: JTBD-002
**Persona**: plugin-developer

## Description

Every install step in `.github/workflows/ci.yml` and `.github/workflows/release.yml` runs `npm ci || npm install`. When `package-lock.json` disagrees with the workspace set, `npm ci` refuses — and the fallback quietly installs anyway. Nothing reports the drift, so it accumulates until something downstream breaks.

Observed 2026-09-04: `packages/cruise` had been added as a workspace with no entry in `package-lock.json` at all (`grep -c cruise package-lock.json` returned 0). `npm ci --dry-run` refused with "Missing: @windyroad/cruise@0.4.11 from lock file". CI was red on main across at least two consecutive runs — 33736001196 on the release merge `ab8da4a0e`, and 33736524129 on `34af8778a` — with the failing job reported as **Agent-Prose Behavioural Evals**, a name that points at eval behaviour rather than at dependencies. Regenerating the lock (`npm install --package-lock-only`, commit `d55ecfec`) turned CI green.

The misleading job name is the visible half. The invisible half is why the drift survived long enough to get there: with the fallback in place, no job ever fails on a stale lock, so a workspace can be added and the lock never regenerated with nothing objecting.

## Symptoms

- CI red on main with a job name that has nothing to do with the actual failure; the real message is buried in that job's install step.
- `npm ci --dry-run` refuses locally while `npm install` and the full local suite behave normally.
- A workspace under `packages/` has no `node_modules/@windyroad/<name>` link entry in `package-lock.json`.

## Workaround

`npm install --package-lock-only`, then confirm with `npm ci --dry-run`.

## Impact Assessment

- **Who is affected**: anyone releasing. CI is the only full-suite arbiter this repo has — the local suite cannot complete — so red CI blocks the release gate, and a misattributed cause costs the time it takes to read the failing job's log rather than its name.
- **Frequency**: once per workspace added without regenerating the lock. Rare event, but nothing catches it, so each occurrence runs until someone investigates an unrelated-looking failure.
- **Severity**: main stays red and the release path is gated shut. Not data-affecting, and the fix is one command once the cause is known.
- **Analytics**: one observed occurrence, spanning at least two CI runs including a release merge.

## Root Cause Analysis

`npm ci || npm install` is a resilience idiom — it keeps CI moving when the lock is briefly behind. The cost is that it also removes the only signal that the lock is behind at all. `npm ci` is the check; falling back on its failure discards the check's result.

Both effects compound: the drift is never reported, and when it does surface it surfaces wherever `npm ci`'s failure happens not to be absorbed, which need not be a job whose name suggests dependencies.

### Investigation Tasks

- [ ] Confirm exactly how the drift reached a job failure despite the fallback — whether `npm install` also refused, or the failure came later in that job. The log line captured was the `npm ci` EUSAGE error; the causal chain past it is inferred, not verified.
- [ ] Add a fast, explicitly-named lockfile-sync check that runs before the heavy jobs and says what is wrong, rather than letting drift surface through whichever job absorbs it last.
- [ ] Decide whether the fallback earns its keep once a named check exists, or whether `npm ci` should be allowed to fail on the jobs that can afford it.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: the release gate — CI green is the release precondition, so anything that reddens CI for a non-code reason stops releases.

## Related

Captured via `/wr-itil:capture-problem` from a session retrospective. Found while landing an unrelated fix: CI had already been red on the release merge before that session's own work touched anything.

Sibling in kind to the shell-portability class (a check that silently does not check), though the mechanism differs — there the guard never matches, here the guard's verdict is discarded by design.
