# Problem 041: work-problems does not enforce release cadence

**Status**: Open
**Reported**: 2026-04-18
**Priority**: 16 (High) — Impact: Significant (4) x Likelihood: Likely (4)

## Description

The `wr-itil:work-problems` AFK orchestrator keeps iterating through problems
even when its own risk-scoring would advise stopping to release first. The
lean-release principle (and P034) require that unreleased changesets stay
within risk appetite. The scorer flags the accumulation via `push` and
`release` score layers, but the orchestrator has no control loop that stops
and releases when the queue hits the appetite threshold (4/25 per
RISK-POLICY.md).

Observed 2026-04-18: in a single AFK loop I worked four scorer-prompt
tightening fixes (P041 → P037 → P038 → P043 in local numbering). Each
successive commit added a patch changeset to `.changeset/`. On the fourth
iteration, the commit-risk score hit 4/25 (at appetite). The loop continued
into a fifth iteration (P036). The user had to manually interrupt with "make
sure you release to avoid going over risk appetite. I shouldn't have to tell
you this" before the loop would stop and ship.

## Symptoms

- 3+ patch changesets accumulate in `.changeset/` without release
- Risk-scorer commit/push scores rise into the Low band (3-4) or Medium (5+)
- Orchestrator continues to spawn new iterations regardless
- User intervention required to force release before the queue exceeds
  appetite
- Downstream consumers receive a batch release with multiple unrelated
  changes instead of small, frequent releases

## Workaround

Manually monitor the risk-scorer's reports between iterations. When commit
or push score enters the Low band, stop the loop, run `npm run push:watch`
followed by `npm run release:watch`, wait for the release to land on npm,
then resume.

## Impact Assessment

- **Who is affected**: Any AFK user relying on `work-problems` to self-pace;
  any downstream consumer of the plugins (batch releases vs lean-release
  principle)
- **Frequency**: Every AFK loop that runs more than ~2-3 iterations on a
  package with patch-level fixes
- **Severity**: Significant — violates the lean-release principle the
  risk-scorer framework is designed to enforce; creates exactly the failure
  mode P034 describes; erodes user trust when the user has to step in to
  release
- **Analytics**: Count patch changesets committed per AFK loop; compare
  against count of releases shipped in the same window

## Root Cause Analysis

### Preliminary Hypothesis

`work-problems` treats each iteration as independent. Its stop conditions are
about whether the next problem is actionable (no actionable problems / all
blocked / needs interactive input). There is no stop condition tied to the
pipeline's cumulative state — the unreleased changeset count, the risk
scorer's `push` / `release` score layers, or the changeset content class.
The orchestrator has no inter-iteration release step.

P034 (release risk accumulation) covers the underlying enforcement mechanism
in the scorer itself; this ticket covers the orchestrator-level response to
that signal.

### Fix Strategies

1. **Inter-iteration release step** — after each successful commit, if
   `.changeset/` contains ≥3 patch files OR the last scorer report reported
   `push >= 3` or `release >= 3`, pause the loop and run
   `npm run push:watch` followed by `npm run release:watch`. Resume the
   loop only after the release lands.
2. **Scorer-driven stop condition** — add a new stop condition to the
   orchestrator: "Release before continuing — unreleased queue risk at
   appetite." Surface this alongside the existing "No actionable problems"
   exit.
3. **Changeset-count guard** — hard limit of N patch changesets (e.g. 3)
   in `.changeset/` between releases; orchestrator refuses to commit past
   that limit.

The three strategies are complementary and can ship together.

### Investigation Tasks

- [ ] Confirm the orchestrator has no current hook into the pipeline-state
      scorer report
- [ ] Determine whether the release step can run non-interactively in the
      AFK loop (i.e. does `release:watch` require user input on failure, and
      can we auto-recover?)
- [ ] Decide the threshold: is it a scorer score band, a changeset count,
      or both?
- [ ] Create reproduction test
- [ ] Create INVEST story for permanent fix

## Related

- P040: work-problems does not fetch origin before starting — companion
  issue from the same incident
- P034: Risk scorer ignores release risk accumulation — scorer-layer
  equivalent; this ticket is the orchestrator-layer response to the signal
  P034 provides
- P039: Autonomous loops conflate diagnose with implement — broader
  autonomy-pattern concern; this ticket is a narrower orchestrator cadence
  issue
- `/Users/tomhoward/.claude/projects/-Users-tomhoward-Projects-windyroad-claude-plugin/memory/feedback_release_cadence.md`
  — personal feedback memo with the rule of thumb
