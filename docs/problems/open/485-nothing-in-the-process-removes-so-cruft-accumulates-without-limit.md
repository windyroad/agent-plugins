# Problem 485: Every step in the process adds and none removes, so cruft accumulates without limit

**Status**: Open
**Reported**: 2026-08-08
**Priority**: 16 (High) — Impact: 4 × Likelihood: 4. Impact 4: this is a property of the process rather than a lapse within it, so it degrades every artefact the process touches — code, tests, decisions, tickets — and it compounds rather than plateauing. Likelihood 4: it operates on every change, because the mechanism is that additive steps are mandatory and gated while removal is optional and ungated.
**Origin**: corrective-feedback
**Effort**: L — a cadenced step, a definition of what it removes, and enforcement; the same shape as the review-cadence work
**JTBD**: JTBD-001
**Persona**: developer

## Description

The maintainer, 2026-08-08, on the state of the story-map code:

> Ultimately there is nothing in our process to fight the entropy. No refactor step. No simplification step. So cruft just accumulates and accumulates.

That is the root cause, and it is more general than the code that prompted it. **Every gate in this process adds something.** Capture a problem, write a decision, ratify it, write a story, write a test, write a changeset, write the comment explaining why. Each is mandatory, each is enforced by a hook, and each leaves an artefact behind.

**Nothing removes.** There is no step at which anyone asks what is now redundant, what explains a state that no longer exists, or what could be deleted outright. Removal happens only when someone happens to notice, which means it happens when the mess is already bad enough to notice — never before.

The asymmetry is structural: adding is gated, so it always happens; removing is optional, so it never does.

### Measured on the files this session touched

| File | Lines | Comment-only |
|---|---|---|
| `packages/itil/lib/story-oversight.sh` | 238 | **64%** |
| `packages/itil/scripts/render-story-map.mjs` | 853 | **34%** |
| `packages/itil/scripts/test/render-story-map.bats` | 1168 | 19% |

`story-oversight.sh` is nearly two-thirds prose. `render-story-map.mjs` holds status derivation, href resolution, story-file reading, three renderers and a refusal check in one file, with `renderGrid` at 107 lines and `renderStatus` at 100.

### Two distinct kinds of cruft, one cause

**Comment archaeology.** Comments that explain a state which no longer exists, to a reader who never saw it. From the renderer: *"This used to return `unproposed`, which gave a tidy name to work nobody had asked for and let it sit there."* Nobody reading that file will ever have seen `unproposed`. The comment documents the author's journey rather than the code's behaviour, and it will outlive everyone who can evaluate whether it is still true.

This is the same failure the maintainer corrected in a decision record on the same day — *"there is a lot of commentary on changes we made and things we removed that was never ratified in the first place, just iterations along the way to getting here"* — which suggests the habit is not specific to code. It is the author writing the trail into the artefact.

**Structural accretion.** A file that started with one job and now has six, because every change added to the nearest existing place rather than asking whether a new one was warranted. Sibling to P479 (decisions accrete into the nearest ADR because amending is cheaper than deciding) — the same economics, applied to modules instead of decisions.

## Symptoms

- A comment explaining what the code used to do, for a reader who never saw it do that.
- A file whose name describes one of the several things it now does.
- A test file longer than the implementation it tests.
- Removal happening only when someone complains, never on a schedule.
- A decision record narrating the iterations that produced it.

## Workaround

Notice, and delete. That is the current mechanism, and it is why this ticket exists.

## Impact Assessment

- **Who is affected**: anyone reading the code afterwards, including the agent — a file that is two-thirds stale prose costs context on every read and mis-teaches on some of them.
- **Frequency**: every change. The additive steps are mandatory; the removal step does not exist.
- **Severity**: compounding. Unlike a defect, this has no failure event that forces attention, so it degrades until someone's patience runs out.
- **Analytics**: none.

## Root Cause Analysis

Suspected, and stated by the maintainer: the process has no removal step at all. Not a weak one, not one that gets skipped — there is nothing to skip.

This composes with a known pattern in this repo: **an action with no automatic cadence never happens**. Refactoring is the archetype. It is always the thing that would be worth doing if there were time, and there is never a trigger that makes time.

### Investigation Tasks

- [ ] Decide what the removal step actually is, and where it fires. Candidates: a step inside the existing per-change flow (cheap, frequent, small scope); a cadenced pass over a package (heavier, catches structure the per-change view cannot); or a gate that refuses a change which only adds. The third is the most aggressive and the most likely to work, and needs a way to distinguish honest addition from accretion.
- [ ] Define what it removes, concretely enough to enforce. First candidates: a comment that explains a state no longer reachable; a test that duplicates another test's assertion; a file that has taken on a second responsibility; a document section describing how the current version came about.
- [ ] Give it a self-firing trigger. Without one this ticket describes its own fate — a maintenance action with no cadence, recorded and never run.
- [ ] Decide whether the comment-archaeology half is separable and cheaper. A rule that a comment must describe current behaviour, not the change that produced it, is enforceable at review time and would have caught most of what is in the renderer today.
- [ ] Check the same shape in the other artefact tiers. The decision corpus has it (P483's 27 amendment sections; ADR-107's removed session commentary), the ticket corpus probably does, and the SKILL prose almost certainly does.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P479, P483.

## Related

- **P479** — decisions accrete into the nearest ADR because amending is cheaper than deciding. The same economics one tier up: this ticket is that pattern generalised from decisions to everything.
- **P483** — a ratified decision is immutable. Its 27 amendment sections are this problem in the decision corpus.
- **ADR-107** — had its session commentary removed by the maintainer on the day it was ratified, which is the same cruft in a decision record. Worth reading as the worked example of what removal looks like.
- Maintainer correction, 2026-08-08: *"this code is a fucking mess"*, and the diagnosis above.

(captured via /wr-itil:capture-problem; duplicate-check found no ticket on refactoring, simplification, entropy or technical debt — the two keyword matches were an ADR-alignment audit and a stale-hook-binding problem, neither related.)
