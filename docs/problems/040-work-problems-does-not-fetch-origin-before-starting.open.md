# Problem 040: work-problems does not fetch origin before starting

**Status**: Open
**Reported**: 2026-04-18
**Priority**: 12 (High) — Impact: Significant (4) x Likelihood: Possible (3)

## Description

The `wr-itil:work-problems` AFK orchestrator does not run `git fetch origin` or
compare local state against `origin/main` before beginning its work loop. When a
parallel Claude session has advanced `origin/main` — creating new problem
tickets, closing others, or shipping related fixes — the local orchestrator
continues oblivious, reviewing a stale backlog and potentially creating new
problem tickets with IDs that will collide with the remote's numbering on push.

Observed 2026-04-18: a parallel session advanced `origin/main` by 20+ commits,
creating P031-P039 with completely different semantics than the P031-P042 I had
created locally. The work-problems loop reviewed, ranked, transitioned, and
worked 4 problems across 5 commits before the user intervened. The push then
failed with a non-fast-forward error, requiring a surgical rebase that dropped
14 of my problem tickets because of numbering collisions.

## Symptoms

- `work-problems` runs against a stale local backlog without warning
- New problem tickets created with IDs that duplicate existing IDs on remote
- Push fails with non-fast-forward after substantial local work
- Surgical rebase required; problem-ticket content often has to be dropped due
  to same-number-different-semantics collisions
- Fix commits closing "P<NNN>" reference ticket IDs that mean different things
  locally vs upstream

## Workaround

Manually run `git fetch origin && git log --oneline HEAD..origin/main` before
invoking `/wr-itil:work-problems`. If the command shows any commits, pull or
investigate before starting the loop.

## Impact Assessment

- **Who is affected**: Anyone running the AFK work-problems loop on a branch
  also being edited by a parallel session (manually, via CI, or via another
  Claude instance)
- **Frequency**: Every AFK loop where a parallel session has committed to
  `origin/main` since the last local fetch
- **Severity**: Significant — wasted surgical-rebase effort, lost problem
  tickets, and eroded user trust in the orchestrator
- **Analytics**: N/A

## Root Cause Analysis

### Preliminary Hypothesis

The `work-problems` skill's opening steps (scan backlog, check README cache
freshness) operate only on the local working tree. The cache-freshness check
was specifically designed to detect stale problem-ticket state within the
local repo (P031 fix) — but it does not detect state drift relative to
`origin/main`. The orchestrator implicitly assumes the local branch is the
canonical view of the backlog.

### Fix Strategies

1. **Pre-flight fetch + divergence check** — before step 1, run
   `git fetch origin` and compare `HEAD` with `origin/main`. If origin has
   advanced, pause the loop and surface the divergence to the user (or,
   in fully autonomous mode, auto-pull/rebase if the merge is trivial).
2. **Post-review numbering-collision guard** — before creating any new
   problem ticket, check the next-ID scan against `origin/main`'s problem
   directory via `git ls-tree origin/main docs/problems/`. If a clash is
   detected, renumber.
3. **Atomic push during each iteration** — push after every successful fix
   commit so the window for divergence is minimised and collisions surface
   immediately rather than at end-of-loop.

### Investigation Tasks

- [ ] Audit `work-problems` skill opening steps for any existing origin
      awareness
- [ ] Decide which fix strategy (or combination) best fits the AFK autonomy
      model — pre-flight fetch is cheap; atomic push restores lean-release
      discipline
- [ ] Create reproduction test (simulated: mock a diverged origin, verify
      the orchestrator refuses to start or auto-rebases)
- [ ] Create INVEST story for permanent fix

## Related

- P041: work-problems does not enforce release cadence — companion issue
  from the same incident; same session, different root cause
- P035: manage-problem commit gate no subagent delegation fallback
  (known-error, fix released) — related commit-gate/subagent context
- P036: work-problems orchestrator does not verify commit-landing between
  iterations — adjacent orchestrator-hygiene concern
- `/Users/tomhoward/.claude/projects/-Users-tomhoward-Projects-windyroad-claude-plugin/memory/feedback_release_cadence.md`
  — personal feedback memo capturing the release-timing half of the lesson
