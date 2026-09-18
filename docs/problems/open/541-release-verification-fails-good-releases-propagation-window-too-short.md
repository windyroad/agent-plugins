# Problem 541: Release verification fails good releases — propagation window too short, and per-package nesting makes widening worse

**Status**: Open
**Reported**: 2026-09-18
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4 — derived at capture from the description per Step 4a
**Origin**: internal
**Effort**: M — derived at capture per Step 4a
**JTBD**: JTBD-001, JTBD-007
**Persona**: developer

## Description

`scripts/verify-release-dist-tags.sh` failed a release that had actually succeeded, deadlocked the release pipeline, and misdirected roughly twenty minutes of diagnosis toward a publish-auth cause that did not exist.

**Measured evidence** (run 35350964367, 2026-09-18):

| Time | Event |
|---|---|
| 13:35:07 | `changeset publish` reports `success: packages published successfully: @windyroad/itil@2.4.0`, pushes the git tag |
| 13:35:09 | `Verify stable npm dist-tags` starts polling |
| 13:35:38 | verifier gives up after 6 attempts × 5s = **30 seconds**, fails the job |
| 13:37:45.239Z | npm registry `time` map records 2.4.0 — a **2m36s** propagation lag |

Current registry state confirms the release genuinely succeeded: `dist-tags.latest = 2.4.0`, version present, tarball published. A correct release was failed by its own verifier.

**Knock-on**: the release gate blocks while main's latest run is a failure, so a false negative here deadlocks the pipeline until another green run lands. It also cost real diagnosis time — the misleading message sent the investigation toward npm auth / trusted-publishing, which was never involved (yesterday's successful release used the identical OIDC path).

### Three compounding defects

All in `scripts/verify-release-dist-tags.sh` unless noted.

1. **The window is roughly 5× too short** for observed propagation — 30s against a measured 2m36s.

2. **The retry loop is nested inside the per-package `for` loop**, so the window is per-package rather than per-run. This is the load-bearing one: naively widening to 30 × 10s yields a **62m50s worst case** across the 13 published packages and 390 `npm view` calls — an 11.6× regression on the genuine-failure path that *lengthens* the very deadlock the fix targets. The fix needs a single absolute deadline computed before the loop, or a round-robin over the not-yet-confirmed set.

3. **The failure message conflates two states** — "version absent from the registry" and "version present but `latest` points elsewhere". It renders both as *"is published without latest"*, asserting a publish happened when it may not have. This is what misdirected the diagnosis.

### Fix constraints (found during architect review)

- `packages/shared/test/release-trusted-publishing.bats:41` asserts the failure message byte-for-byte, and that fixture's fake `npm` echoes one value for every invocation — so it would silently take the wrong branch once a version probe is added. Update the assertion, split the fixture's probes so the version and dist-tag lookups answer independently, and add a case for the absent-from-registry branch. Prove both RED first.
- Any new `npm view` probe needs `|| true`: the script runs under `set -eu` and `npm view` exits non-zero on an absent version. Place it on the failure branch only, to avoid doubling registry reads.
- **Unverified**: whether repeated `npm view` calls within the window actually reach the registry or are served from the local metadata cache. If the latter, a wider window buys nothing. Consider `--prefer-online` or a per-run `npm_config_cache`. This needs an empirical check before the widened window is trusted.

### Prior art

`docs/briefing/releases-and-ci.md` line 9 records the intent this continues: *"Post-publish npm verification must tolerate registry propagation, while pre-publish verification must reject immutable version collisions."*

Distinct from P284, which is a publish-auth failure class (E404 / 2FA), not a verification false-negative.

## Symptoms

- Release job fails at `Verify stable npm dist-tags` with `<pkg>@<version> is published without latest (registry latest: <older>)` despite the publish having succeeded.
- The named version is briefly absent from the registry, then appears a minute or two later.
- Subsequent releases are blocked by the release gate because main's latest run concluded failure.

## Workaround

Wait for propagation, confirm `npm view <pkg> dist-tags` shows the expected `latest`, then land any commit to produce a green run on main and clear the gate. No override exists, by design.

## Impact Assessment

- **Who is affected**: the maintainer running releases; anyone blocked behind a stuck release pipeline.
- **Frequency**: every release where npm propagation exceeds 30 seconds. Observed once on 2026-09-18; propagation above 30s is not unusual.
- **Severity**: blocks releasing until a separate green run lands, and actively misleads diagnosis.
- **Analytics**: not instrumented.

## Root Cause Analysis

Post-publish verification treats registry visibility as immediate when it is eventually consistent, and its retry budget (`POST_PUBLISH_ATTEMPTS=6` × `POST_PUBLISH_DELAY=5`) was set well below real propagation latency. The nesting of that retry inside the per-package loop means the budget cannot simply be raised without multiplying by package count.

### Investigation Tasks

- [ ] Verify empirically whether repeated `npm view` calls within the window reach the registry or are served from cache (blocks trusting any widened window).
- [ ] Restructure the retry to a single run-level deadline computed before the per-package loop, or a round-robin over the not-yet-confirmed set.
- [ ] Widen the window to a real multiple of observed propagation, keeping the env override.
- [ ] Split the failure message into absent-from-registry vs present-but-not-latest.
- [ ] Update `packages/shared/test/release-trusted-publishing.bats` — assertion string, independent fixture probes, and a new absent-branch case. Prove RED first.
- [ ] Consider `timeout-minutes` on the Release job as a structural backstop.
- [ ] Add the measured propagation evidence to `docs/briefing/releases-and-ci.md` alongside the existing line-9 entry.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P284 (release-pipeline sibling — different failure class: publish-auth, not verification false-negative)

## Related

- Run 35350964367 — the failing release; registry `time` map records 2.4.0 at 2026-09-18T13:37:45.239Z.
- `docs/briefing/releases-and-ci.md` line 9 — recorded intent this fix continues.
- P284 — adjacent release-pipeline ticket, publish-auth (E404/2FA) class. Checked as a hang-off parent and rejected: different mechanism.
- ADR-071 / ADR-072 / ADR-073 / ADR-119 — the fix needs a traced release row before implementation.
- No changeset needed: the script is repo-root infrastructure, not under `packages/`, and no published package changes.

(captured via /wr-itil:capture-problem; expand at next investigation)
