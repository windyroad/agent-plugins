# Releases and CI — Archive (pre-2026-05-05)

Cold-storage one-line stubs of releases-and-ci.md entries dated 2026-04-19 through 2026-04-26, rotated 2026-05-13 per Tier 3 budget MUST_SPLIT. Sibling: [`releases-and-ci.md`](./releases-and-ci.md) carries current entries.

## What You Need to Know (archived 2026-05-13)

- **`changesets/action@v1`'s `version:` input defaults to running `changeset version` directly**, bypassing any `npm run version` script — pass `version: npm run version` explicitly to fire a custom version hook. (P052) <!-- signal-score: 0 | last-classified: 2026-05-25 | first-written: 2026-04-19 -->
- **`release:watch` after `push:watch` may need a mid-cycle pipeline rescoring** — a `reducing-release` bypass marker skips it; otherwise the 3-step dance fires (`push:watch` → delegate `wr-risk-scorer:pipeline` → `release:watch`). (P048/P053/P054) <!-- signal-score: 0 | last-classified: 2026-05-25 | first-written: 2026-04-19 -->
- **When an ADR defers a mechanical migration to a follow-up commit, land both commits before pushing** so the system is never pushed in an inconsistent state (ADR-022 contract+migration paired-commit pattern). <!-- signal-score: 0 | last-classified: 2026-05-25 | first-written: 2026-04-19 -->

## What Will Surprise You (archived 2026-05-13)

- **Release drain fires AT appetite (≥ 4/25), not above it** — a score of exactly 4 triggers the drain. <!-- signal-score: 0 | last-classified: 2026-05-25 | first-written: 2026-04-20 -->
- **`push:watch` may report success on the wrong (prior-sha) CI run** when an older workflow is still in flight; verify with `gh run list --commit=$(git rev-parse HEAD)` (flag is `-c/--commit`, not `--head-sha`). (P060) <!-- signal-score: 0 | last-classified: 2026-05-25 | first-written: 2026-04-20 -->
- **ADR Confirmation sections that only assert source content can pass while the runtime/CI integration silently fails** — add behavioural/CI-wiring assertions, not just source greps. (P052) <!-- signal-score: 0 | last-classified: 2026-05-25 | first-written: 2026-04-20 -->
- **`changesets/action@v1` does NOT tolerate subdirectories under `.changeset/`** — hold partial-progress changesets OUTSIDE `.changeset/` (this repo uses `docs/changesets-holding/`). (P103/P104) <!-- signal-score: 0 | last-classified: 2026-05-25 | first-written: 2026-04-22 -->
- **Local commit accumulation between pushes masks CI regressions on intermediate commits** — GitHub Actions fires CI only on the pushed tip SHA. A regression mid-chain is invisible until the next push, then blames the innocent tip. (P113/P116) <!-- signal-score: 0 | last-classified: 2026-05-25 | first-written: 2026-04-24 -->
- **Partial-progress iterations can paint the release queue into an undrainable corner** — a held `minor` bump whose value only lands at slice 2; hold the high-risk changeset + drain the low-risk subset, or defer the whole release. (P100/P103/P104) <!-- signal-score: 0 | last-classified: 2026-05-25 | first-written: 2026-04-22 -->
- **Iter-retro "bats green" claims do NOT guarantee CI green on the same commit** — CI green on the pushed commit IS the release-readiness signal, not the iter's local subset. (P127) <!-- signal-score: 0 | last-classified: 2026-05-25 | first-written: 2026-04-26 -->
- **GNU `cp -R . dest` refuses source-into-itself; BSD on macOS allows it silently** — bats fixtures snapshotting a working dir must target OUTSIDE the source tree (`SNAP=$(mktemp -d); cp -R "$TEST_DIR/." "$SNAP"`). Reproduce via `docker run --rm -v "$PWD:/work" -w /work bats/bats:latest <fixture>`. (P127) <!-- signal-score: 0 | last-classified: 2026-05-25 | first-written: 2026-04-26 -->

> Archived from `releases-and-ci.md` on 2026-05-13 per ADR-040 Tier 3 budget MUST_SPLIT. These entries remain authoritative; load alongside `releases-and-ci.md` when full historical context is needed.
