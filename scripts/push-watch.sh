#!/bin/bash
# Usage: npm run push:watch
# Pushes the current branch and watches every CI run anchored on the
# pushed HEAD sha. Exit code is propagated from the first failing run.
#
# Preflight (P116): counts local-only commits (commits on HEAD that have
# never been pushed to origin) and prints a warning to stderr when the
# count is >= 2. GitHub Actions fires CI only on the pushed-tip sha, so
# any regression introduced by an intermediate commit in a batched push
# lands against the tip commit and not the regressing commit — the
# blame trail is wrong and the operator wastes diagnostic time on the
# innocent tip. The preflight names the hazard so the operator can
# Ctrl-C and re-sequence if running interactively; in AFK mode the
# warning lands in the push log for post-hoc attribution.
#
# Contract shape is warn-and-proceed per ADR-013 Rule 5 (policy-
# authorised silent proceed) and Rule 6 (non-interactive fail-safe).
# This script never blocks the push.
#
# Anchoring invariants (P060): the watch target MUST be anchored on
# `--commit=$(git rev-parse HEAD)` (not `--limit 1`), MUST loop over
# every matching run, MUST filter `--branch main`, and MUST propagate
# each run's exit code via `|| exit $?`.

set -uo pipefail

# ── Preflight: count local-only commits (P116) ──────────────────────────────
# `@{push}` is git's push-ref for the current branch. When origin is
# reachable and the branch has been pushed before, it resolves to the
# last pushed tip sha. When the branch is new (never pushed), `@{push}`
# is undefined; fall back to `origin/main..HEAD`.
local_only_count=$(git rev-list --count '@{push}..HEAD' 2>/dev/null || true)
if [ -z "${local_only_count:-}" ]; then
  local_only_count=$(git rev-list --count origin/main..HEAD 2>/dev/null || echo 0)
fi

if [ "${local_only_count:-0}" -ge 2 ]; then
  {
    echo ""
    echo "WARNING: ${local_only_count} local-only commits will batch-push."
    echo "Intermediate commits never ran origin CI. GitHub Actions fires CI"
    echo "only on the pushed tip sha, so any regression introduced by"
    echo "commits 1..$((local_only_count - 1)) will be attributed to the tip"
    echo "commit — the blame trail will point at the innocent tip commit."
    echo ""
    echo "Local-only commits:"
    git log '@{push}..HEAD' --oneline 2>/dev/null \
      || git log origin/main..HEAD --oneline 2>/dev/null \
      || true
    echo ""
    echo "Proceeding with push (warn-and-proceed per ADR-013 Rules 5 and 6)."
    echo ""
  } >&2
fi

# ── Push + watch every CI run on the pushed HEAD sha (P060) ─────────────────
set -e
git push 2>&1
sleep 5
for id in $(gh run list --commit=$(git rev-parse HEAD) --branch main --json databaseId --jq '.[].databaseId'); do
  gh run watch "$id" --exit-status || exit $?
done
