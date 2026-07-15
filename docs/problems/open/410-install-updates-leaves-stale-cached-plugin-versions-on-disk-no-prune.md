# Problem 410: install-updates leaves stale cached plugin versions on disk — no prune step

**Status**: Open
**Reported**: 2026-07-03
**Priority**: 8 (Medium) — Impact: 2 (Minor — disk bloat; stale caches also feed the P402-class stale-code-execution risk) × Likelihood: 4 (Likely — accumulates on every release; releases are frequent) — re-rated 2026-07-15 /wr-itil:review-problems
**Origin**: internal
**Effort**: M — prune step in the repo-local /install-updates skill; needs care around live sessions holding old versions
**WSJF**: 4.0 — (8 × 1.0) / 2
**JTBD**: JTBD-007
**Persona**: developer

## Description

Plugin updates are additive on disk. Each time a `@windyroad/*` plugin updates, Claude Code downloads the new version into a fresh folder under `~/.claude/plugins/cache/windyroad/<plugin>/<version>/` and never deletes the old ones. Only the newest version per plugin is ever loaded/used; the rest are inert dead weight on disk.

Observed footprint (2026-07-02): `wr-itil` alone had 11 cached versions (0.29.0 → 0.55.0), ~4MB each, ~41MB total, of which ~10 (~37MB) are stale. Across all windyroad plugins combined: ~77MB of cache, mostly old versions.

Not a context/token concern — the stale versions are disk-only and are not loaded into the model context. This is disk hygiene: the install/update mechanism (`/install-updates`, repo-local per ADR-030) should prune superseded cached versions after a successful refresh, so old downloads don't accumulate unbounded across release loops.

Reclaiming disk safely must go through the plugin tooling (`/plugin` / `claude plugin`) or the install-updates skill, not a manual `rm` of cache folders — deleting the wrong folder could break the active plugin. Any prune step this ticket adds must identify the active version first and only remove genuinely-superseded siblings.

## Symptoms

(deferred to investigation)

## Workaround

(deferred to investigation)

## Impact Assessment

- **Who is affected**: (deferred to investigation)
- **Frequency**: (deferred to investigation)
- **Severity**: (deferred to investigation)
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Investigate root cause
- [ ] Create reproduction test

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: (none)

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)

- Hang-off pre-filter short-circuited: `install-updates` is a shared signal across many open/verifying install-updates tickets (297, 343, 320, 280, 263, 259, 242, 219, 293), exceeding the 5-candidate cap — subagent dispatch skipped per the latency-bound safe default. Re-evaluate absorption at next /wr-itil:review-problems.
- Adjacent closed context: P299 (ADR-034 plugin cache is global/shared), P253 (no house-cleaning cadence for cruft/deprecation removal), P115 parked (install-updates does not detect stale plugin installs in worktrees). None owns the "prune superseded cached versions on install" scope.
