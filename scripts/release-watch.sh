#!/bin/bash
# Usage: npm run release:watch
# Merges the open changeset release PR, watches the Release workflow,
# and reports which packages were published. On failure: shows what
# failed and prompts for a fix.
#
# Env vars:
#   RELEASE_WATCH_VERBOSE=1   Print poll-loop progress (P143) to stderr
#                             while waiting for the changesets/action
#                             workflow to open the release PR. Default
#                             off — the script is silent during the poll
#                             window so existing `npm run release:watch
#                             | tee` orchestrator pipes are unaffected.
#
# Contract with the release gate (per ADR-015, ADR-018, ADR-020):
#   Callers MUST have an in-session release risk score for this session
#   (produced by wr-risk-scorer:pipeline). Running this script immediately
#   after `npm run push:watch` within the same session is supported — the
#   pipeline-state hash is stable across a policy-authorised git push, so
#   the score produced pre-push remains valid post-push (P054). No
#   mid-cycle rescore delegation is required.
#
#   If the gate still reports drift after a push (e.g. new uncommitted
#   edits arrived, TTL expired, or a new changeset was added), delegate
#   to wr-risk-scorer:pipeline to rescore against the current state.

set -euo pipefail

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)

# ── Helper: show failed jobs and guidance ─────────────────────────────────────
show_failure_guidance() {
  local run_id="$1"
  local run_url="$2"

  echo ""
  echo "Failed checks:"
  gh run view "$run_id" --json jobs \
    --jq '.jobs[] | select(.conclusion == "failure") | "  ✗ \(.name)"' 2>/dev/null || true

  echo ""
  echo "Fix the failure above, then re-run: npm run release:watch"
  echo ""
  echo "CLAUDE: The release pipeline failed. Show the user which checks failed above,"
  echo "help them fix the issue, then run \`npm run release:watch\` again."
}

# ── Helper: poll for the changeset release PR (P143) ─────────────────────────
# Wraps `gh pr list` in a bounded poll loop to absorb changesets/action
# workflow latency (~30-120s between `git push` and PR creation/update).
# Without this, callers invoking release:watch immediately after push:watch
# routinely raced the PR-creation window and exited 1 on a transient empty
# query.
#
# Contract:
#   stdout (success): one line, tab-separated <number>\t<url>
#   exit 0 on success; exit 1 after 12 consecutive empty results (120s)
#   stderr (verbose only): "Polling for release PR (attempt N/12)..." per
#     iteration when RELEASE_WATCH_VERBOSE=1
#
# Bounds: 12 attempts × 10s sleep = 120s wall-clock ceiling. The final
# iteration does NOT sleep afterwards — that would burn 10s for nothing.
find_release_pr() {
  local max_attempts=12
  local sleep_seconds=10
  local attempt=1
  local pr_json pr_number pr_url

  while [ "$attempt" -le "$max_attempts" ]; do
    pr_json=$(gh pr list --head changeset-release/main --base main --state open --limit 1 --json number,url 2>/dev/null || echo "[]")
    pr_number=$(echo "$pr_json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['number'] if d else '')" 2>/dev/null)
    pr_url=$(echo "$pr_json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['url'] if d else '')" 2>/dev/null)

    if [ -n "$pr_number" ]; then
      printf '%s\t%s\n' "$pr_number" "$pr_url"
      return 0
    fi

    if [ "$attempt" -lt "$max_attempts" ]; then
      if [ "${RELEASE_WATCH_VERBOSE:-0}" = "1" ]; then
        echo "Polling for release PR (attempt $attempt/$max_attempts)..." >&2
      fi
      sleep "$sleep_seconds"
    fi
    attempt=$((attempt + 1))
  done

  return 1
}

# ── 1. Find and merge the open release PR ────────────────────────────────────
if PR_LINE=$(find_release_pr); then
  PR_NUMBER=$(printf '%s\n' "$PR_LINE" | head -1 | cut -f1)
  PR_URL=$(printf '%s\n' "$PR_LINE" | head -1 | cut -f2)
else
  echo "No open release PR found (changeset-release/main -> main)." >&2
  echo "Has it already been merged, or are there no pending changesets?" >&2
  echo "Polled for 120s. The changesets/action workflow may have failed to open a release PR — check Actions tab:" >&2
  echo "  https://github.com/$REPO/actions/workflows/release.yml" >&2
  exit 1
fi

echo "Merging release PR: $PR_URL"
gh pr merge "$PR_NUMBER" --merge --delete-branch
echo ""

# ── 2. Find the Release workflow run ─────────────────────────────────────────
printf 'Waiting for Release workflow'
RUN_ID=""
for i in $(seq 1 40); do
  RUN_ID=$(gh run list \
    --workflow=release.yml \
    --branch main \
    --limit 5 \
    --json databaseId,status,createdAt \
    --jq '[.[] | select(.status != "completed")] | sort_by(.createdAt) | reverse | .[0].databaseId' 2>/dev/null)
  [ -n "$RUN_ID" ] && [ "$RUN_ID" != "null" ] && break
  printf '.'
  sleep 3
done
echo ""

if [ -z "$RUN_ID" ] || [ "$RUN_ID" = "null" ]; then
  echo "No in-progress Release workflow found." >&2
  echo "The merge may have completed too quickly. Check:" >&2
  echo "  https://github.com/$REPO/actions/workflows/release.yml" >&2
  exit 1
fi

RUN_URL="https://github.com/$REPO/actions/runs/$RUN_ID"
echo "Release pipeline: $RUN_URL"
echo ""

# ── 3. Watch ──────────────────────────────────────────────────────────────────
if ! gh run watch "$RUN_ID" --exit-status; then
  echo ""
  echo "Release failed — $RUN_URL"
  show_failure_guidance "$RUN_ID" "$RUN_URL"
  exit 1
fi

echo ""
echo "Release complete."

# ── 4. Pull the merge commit locally ─────────────────────────────────────────
echo ""
echo "Pulling merged changes..."
git pull --ff-only

echo ""
echo "CLAUDE: The release is published to npm. Let the user know the release is live."
echo "Packages are available at: https://www.npmjs.com/org/windyroad"
