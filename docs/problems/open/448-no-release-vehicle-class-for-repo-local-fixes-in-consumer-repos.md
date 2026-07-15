# Problem 448: work-problems post-release K→V auto-transition has no release-vehicle class for repo-local fixes in consumer repos (no npm release)

**Status**: Open
**Reported**: 2026-07-15
**Priority**: 9 (Medium) — Impact: 3 (Moderate — adopter ticket lifecycle drifts out of sync with already-shipped fixes at every tier; manual transition passes required; witnessed P092/P075/P081 downstream) × Likelihood: 3 (Possible — every repo-local script/skill/doc fix in a consumer repo that does not publish to npm) — derived at capture per Step 4a
**Origin**: inbound-reported (#320)
**Effort**: M — recognise a repo-local/pushed-to-origin release-vehicle class in `enumerate-postrelease-kv-candidates` + `derive-release-vehicle` + work-problems Step 6.5; cf. P389's seed-discipline fix (same surfaces, different root cause)
**JTBD**: JTBD-302
**Persona**: plugin-user

## Description

The `/wr-itil:work-problems` Step 6.5 post-release K→V auto-transition only fires AFTER `release:watch` ships an npm changeset matching a Known-Error ticket's `**Release vehicle**: .changeset/<name>.md` citation. In a downstream CONSUMER repo that does not publish to npm, a fix to a repo-local script (e.g. downstream P092's `scripts/push-watch.sh`) is "released" by being pushed to origin (the script runs directly from the working tree), so there is no changeset and no npm version. The K→V auto-transition therefore never fires and the ticket stays in known-error/ indefinitely even though its fix is live.

Recurrence evidence (2026-06-27 downstream): the same root also drifts tickets stuck at the **Open** tier — a prior session implements + commits a repo-local fix but never walks the ticket through any lifecycle transition (downstream P075, P081 both manually resynced weeks later). Scope is therefore "any-tier → Verifying drift for repo-local consumer fixes": the absence of an npm release-vehicle signal means no automated lifecycle transition fires from any starting tier.

Candidate fix (upstream, wr-itil): recognise a "repo-local / pushed-to-origin" release-vehicle class (no changeset) so `push:watch` success on a commit that resolves a Known-Error ticket's repo-local fix triggers the K→V transition; alternatively document that repo-local-fix consumer repos must transition manually.

## Symptoms

- Known-Error ticket with a live, pushed repo-local fix never reaches Verification Pending; downstream loops manually dispatch transition iters (downstream commit 732b12a).
- Open-tier tickets whose repo-local fix already shipped sit "misfiled as Open" until a human notices.

## Workaround

Manually dispatch `/wr-itil:transition-problem` once the repo-local fix is pushed to origin (the downstream 2026-06-17 loop did exactly this for its P092).

## Impact Assessment

- **Who is affected**: plugin-user persona — consumer repos adopting the suite without an npm publish pipeline.
- **Frequency**: every repo-local fix in such repos; three downstream witnesses (P092, P075, P081).
- **Severity**: Moderate — lifecycle-state accuracy silently degrades; trust in the automated lifecycle (JTBD-302) erodes.
- **Analytics**: downstream repo windy-road content project, tracked there as P098.

## Root Cause Analysis

### Investigation Tasks

- [ ] Design the repo-local/pushed-to-origin release-vehicle class (derive-release-vehicle + enumerate-postrelease-kv-candidates + Step 6.5 recognition).
- [ ] Decide the any-tier → Verifying drift handling (broadened scope per the 2026-06-27 recurrence evidence).
- [ ] Create reproduction test.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P389 (seed-discipline gap, verifying — same surfaces, npm-changeset class), P361 (exit-3 false positive, verifying — its ancestry fix also presupposes npm version-bump commits and never fires in consumer repos)

## Related

- Upstream issue #320 (inbound; reporter's downstream ticket P098).
- Hang-off arbitration 2026-07-15 (wr-itil:hang-off-check): PROCEED_NEW — P389 is a seed-discipline gap within the npm-changeset vehicle class (its co-commit fallback cannot recover a changeset that never exists); P345 is the O→KE title seam, explicitly non-unifiable with the K→V seam; P363 is the upstream verdict-delivery loop after transition, not why the transition never fires; P361's shipped fix keys off `chore: version packages` commits which also presuppose npm releases. Cluster note: P448/P389/P361 are siblings on the "release-vehicle derivation assumes npm changesets" axis — consider a master ticket if the family grows.
