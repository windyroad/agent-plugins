#!/usr/bin/env bats

# P060: the push-watch surface must anchor the `gh run watch` target on
# the pushed HEAD sha (not on `--limit 1`, which picks the most-recently-
# STARTED run regardless of sha and can report success on a PRIOR sha's
# workflow).
#
# Also: ADR-018 + ADR-020 consume push:watch's exit code to gate release
# drains. A bash `for` loop's exit code is the last iteration's only —
# earlier-iteration failures are swallowed unless explicitly propagated.
# The script MUST propagate failures via `|| exit $?` so a failing CI
# run on any workflow for the pushed sha stops the drain.
#
# P116 moved the command body from `package.json` into
# `scripts/push-watch.sh`. The anchoring tokens MUST remain present in
# the script file verbatim; `package.json`'s `push:watch` MUST delegate
# to the script. Doc-lint structural test (Permitted Exception per
# ADR-005).

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
  PKG_JSON="$REPO_ROOT/package.json"
  SCRIPT="$REPO_ROOT/scripts/push-watch.sh"
}

@test "push-watch: package.json exists" {
  [ -f "$PKG_JSON" ]
}

@test "push-watch: scripts/push-watch.sh exists (P116)" {
  [ -f "$SCRIPT" ]
}

@test "push-watch: package.json delegates to scripts/push-watch.sh (P116)" {
  run grep -F -- 'bash scripts/push-watch.sh' "$PKG_JSON"
  [ "$status" -eq 0 ]
}

@test "push-watch: script anchors on HEAD sha via --commit=\$(git rev-parse HEAD) (P060)" {
  run grep -F -- '--commit=$(git rev-parse HEAD)' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "push-watch: script propagates exit code from each watched run (|| exit \$?) — ADR-018/ADR-020 contract" {
  run grep -F -- '|| exit $?' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "push-watch: script does NOT use --limit 1 pattern (P060 regression guard)" {
  # --limit 1 alone (without --commit) is the P060 defect. The script may use
  # --limit with other flags in future variants, but the bare `--limit 1`
  # with no commit constraint is the regression to block.
  run grep -F -- '--limit 1 --json databaseId' "$SCRIPT"
  [ "$status" -ne 0 ]
}

@test "push-watch: script loops over all HEAD-sha runs (not just one)" {
  run grep -E 'for id in.*gh run list.*--commit=.*git rev-parse HEAD' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "push-watch: script filters by --branch main" {
  run grep -F -- '--branch main' "$SCRIPT"
  [ "$status" -eq 0 ]
}
