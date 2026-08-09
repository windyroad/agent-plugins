# Problem 493: A docs-only change runs the full build, so pushing prose costs what shipping code costs

**Status**: Open
**Reported**: 2026-08-09
**Priority**: 6 (Medium) — Impact: 2 × Likelihood: 3. Impact 2: nothing breaks; the cost is minutes of CI and a discouragement to push small changes often, which works against the batch-size goal. Likelihood 3: it fires on every docs-only push, which for governance work is a large share of them.
**Origin**: corrective-feedback (user, 2026-08-09)
**Effort**: S — path filters on the workflow triggers, plus a decision about what counts as docs-only.
**JTBD**: JTBD-002
**Persona**: developer

## Description

`.github/workflows/ci.yml` triggers on every push to `main` and every pull request against it, with no path filtering. So a commit that changes nothing but prose runs the full Quality Gates job — the whole hook and script suite, several thousand tests, around eight minutes — and the agent-prose eval job alongside it.

On 2026-08-09 a session pushed nine commits, six of which touched only `docs/`. Every one of them ran the full build. The single commit that carried a real defect was the one that touched a generated agent file, which is exactly the kind of change that *should* run it.

**A docs-only change should be able to reach GitHub without triggering a build or a release.**

### Why this matters more than the minutes

The cost is not really CI time. It is that an expensive push discourages frequent pushing, and frequent pushing is what keeps batches small. P492 records the missing nudge that would ask for more pushes; this ticket is the other half — if pushes become more frequent, what a push costs starts to matter. A docs commit that costs eight minutes of build is an argument for holding it until something else is ready, which is the accumulation both are trying to prevent.

### What "docs-only" has to mean here

Not simply "the diff is under `docs/`". This repository's governance documents are read by agents at runtime, and some of them are load-bearing:

- `docs/decisions/README.md` is the architect's routine load surface.
- `RISK-POLICY.md` drives the scorer.
- `docs/VOICE-AND-TONE.md` and `docs/STYLE-GUIDE.md` drive reviewers.
- `docs/jtbd/` drives the jobs reviewer.

Several of those have tests asserting their shape. So the filter needs to distinguish prose that nothing asserts against from prose that something does — or accept that some `docs/` paths keep triggering the build.

There is also a real hazard in getting it wrong: a path filter that skips too much lets a change through unverified, and a required check that never runs can leave a pull request unable to merge depending on how branch protection is configured. That has to be checked before the filter lands, not after.

## Symptoms

- A commit touching one markdown file running several thousand tests.
- Eight minutes of CI for a change no test covers.
- Weighing whether to push prose now or wait for something else to justify it.

## Workaround

Push anyway and let it run, or batch the docs commit with something else — the second of which is the accumulation P492 is about.

## Impact Assessment

- **Who is affected**: whoever pushes, and anyone waiting on a queue behind an unnecessary run.
- **Frequency**: every docs-only push. In a governance-heavy session that is most of them.
- **Severity**: minutes and friction. Nothing is wrong with what ships; the cost is on the behaviour it discourages.
- **Analytics**: none.

## Root Cause Analysis

Suspected: the workflow was written to run on everything because that is the safe default, and nothing since has needed it to be cheaper. The cost only becomes visible once pushing frequently is the goal — which it became when the batch-size problem was named.

### Investigation Tasks

- [ ] Decide what counts as docs-only, given that several `docs/` paths are runtime surfaces with tests asserting their shape. A `paths-ignore` list is the obvious mechanism; the content of the list is the decision.
- [ ] Check branch protection before landing a filter. If a required check is skipped rather than passed, a pull request may become unmergeable — verify the behaviour rather than assuming it.
- [ ] Decide whether the agent-prose eval job follows the same rule. It is the more expensive of the two and is even less likely to be affected by a prose-only change, but it is also the job that reviews prose.
- [ ] Confirm the release workflow is unaffected. A docs-only commit should not start a release either, and that is a separate trigger from CI.
- [ ] Consider whether a docs-only change should still run the markdown and link checks, if any exist. Skipping the build is not the same as skipping all verification.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- **P492** — nothing nudges when unpushed work piles up. The paired concern: that ticket asks for more frequent pushes, this one makes a push cheap enough to want.
- **ADR-020** — the interactive release trigger, confirmed changeset-only on 2026-08-09. A docs commit produces no changeset, so it already does not trigger a release; what it does trigger is the build.

(captured at the maintainer's direction while settling ADR-020's trigger: *"a doc only commit should be able to push and not trigger a ci build and full release."*)
