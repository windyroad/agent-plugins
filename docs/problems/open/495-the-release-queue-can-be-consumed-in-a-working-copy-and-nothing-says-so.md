# Problem 495: The release queue can be consumed in a working copy and nothing says so

**Status**: Open
**Reported**: 2026-08-09
**Priority**: 12 (High) — Impact: 4 × Likelihood: 3. Impact 4: committing the consumed state destroys the release notes for everything queued and stamps versions CI never issued, which reaches npm. Likelihood 3: observed once, cause unidentified, and nothing prevents a recurrence.
**Origin**: internal
**Effort**: S — a guard and a check; the hard part is deciding which of the two.
**WSJF**: 12 — (12 × 1.0) / 1 (added 2026-08-21 review)
**JTBD**: JTBD-002
**Persona**: developer

## Description

On 2026-08-09 the five changesets waiting in `.changeset/` vanished from the working copy. Alongside them, `@windyroad/itil` and `@windyroad/architect` had their versions bumped in `package.json` and CHANGELOG entries written. That is the complete output of `changeset version` — the release step, which runs in CI on `main` and has no business running in a working copy.

Nothing warned. No hook fired, no gate objected, and the last commit before it went through clean. It surfaced only because the queue happened to be counted while answering an unrelated question about release triggers.

Everything was recoverable: the deletions were uncommitted and the files were intact in `HEAD`, so `git checkout -- .changeset/ packages/` restored the lot.

### What would have happened had it not been noticed

The next commit would have carried five deletions and two version bumps. The release notes for the story-map renderer work, the amendment refusal, the value-statement fix, the traces derivation and the AFK carve-out retirement would all have gone, silently, because a changeset that has been consumed leaves nothing behind to miss. The two packages would then have been published at versions CI never issued, from a state no release workflow produced.

The risk scorer would not have caught it. It reads the pending queue to score release risk, so an empty queue reads as *nothing to release* — the safest possible verdict — rather than as *the queue was just destroyed*.

### The cause is not established

The obvious suspect was ruled out empirically: `npm pack --dry-run` had been run in five workspace packages shortly before, and re-running it consumes nothing and modifies no files. Neither package's `prepack` touches changesets.

What is known: nineteen `claude` processes were running and this repository has five worktrees, so a concurrent session is the likeliest candidate. That is a hypothesis, not a finding, and this ticket does not rest on it — the detection gap is the same whatever ran the command.

### Why the gap is the finding rather than the cause

Whatever consumed the queue, the working copy is a place where the release step *can* run and where nothing notices that it has. Those are two separate holes:

- **Nothing prevents it.** `changeset version` is an ordinary command with no environment guard; anything that can invoke npm scripts can run it.
- **Nothing detects it.** A consumed queue is indistinguishable from an empty one, and a commit that removes changesets while bumping versions looks exactly like a legitimate release commit — because that is precisely what a release commit is.

The second is the harder half. The signal that separates the two cases is *where it ran*, not *what it did*.

## Symptoms

- `.changeset/` empty when work is queued for release.
- Version bumps in `package.json` that no release workflow produced.
- CHANGELOG entries appearing in a working copy.
- A release-risk score of zero because there is nothing queued, when moments earlier there was.

## Workaround

Count the changesets before committing. That is what happened here, by accident.

## Impact Assessment

- **Who is affected**: this project's release integrity, and adopters who would receive packages at versions issued outside the release pipeline.
- **Frequency**: observed once. Cause unidentified, so the rate is unknown.
- **Severity**: recoverable only while uncommitted. Past that, the release notes for the queued work are gone and the version numbers are wrong at the registry.
- **Analytics**: none.

## Root Cause Analysis

Suspected: `changeset version` was designed to run in one place and nothing enforces that it does. The release workflow calls it on `main`; the repository does not distinguish that call from any other. The detection half follows from the same shape — the queue is state with no expected value, so emptiness carries no information.

### Investigation Tasks

- [ ] Decide between preventing and detecting, or take both. A guard that refuses to run outside CI is the smaller change and closes the hole at its source; a check that notices the queue shrinking without a release catches whatever the guard does not cover, including a direct `npx changeset version`.
- [ ] If detecting: find the signal that separates a release commit from a working-copy accident. Both delete changesets and bump versions. Candidates are the branch, the author, or the absence of the release workflow's own marker — the last is the only one that cannot be produced locally by accident.
- [ ] Consider whether the risk scorer should read this. It already reads the queue for the release layer, and it is the surface that would notice the queue emptying between two scorings of the same branch. That is a change to what it treats as a signal, not new machinery.
- [ ] Establish the cause if it can be established cheaply, and stop if it cannot. Five worktrees and nineteen concurrent processes make attribution expensive, and the fix does not depend on the answer.
- [ ] Check whether it has happened before and gone unnoticed. A changeset consumed and committed would show as a release commit with no release; the history can be searched for version bumps that do not correspond to a published version.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- **P305** — post-Edit silent revert of working-tree files. Same family: work disappearing from the working copy with no warning. Not the same defect — that one is the harness reverting in-flight edits, this one is a release command consuming queued state — and the fixes do not overlap, so it is captured separately rather than folded in.
- **ADR-099** — changesets are release metadata, not shipment controls. This is what makes the loss expensive: the changeset *is* the release note, so consuming it destroys the only record of what a release contained.
- **P454** — the restage helper's whole-index sweep. Adjacent hazard on the same path: a commit picking up more than was intended.

(captured after the queue was restored; the deletions were uncommitted and recovered in full.)
