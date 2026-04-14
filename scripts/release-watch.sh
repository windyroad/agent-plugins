#!/bin/bash
# Usage: npm run release:watch
# Merges the open changeset release PR, watches the Release workflow,
# and reports which packages were published. On failure: shows what
# failed and prompts for a fix.

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

# ── 1. Find and merge the open release PR ────────────────────────────────────
PR_JSON=$(gh pr list --head changeset-release/main --base main --state open --limit 1 --json number,url 2>/dev/null)
PR_NUMBER=$(echo "$PR_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['number'] if d else '')" 2>/dev/null)
PR_URL=$(echo "$PR_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['url'] if d else '')" 2>/dev/null)

if [ -z "$PR_NUMBER" ]; then
  echo "No open release PR found (changeset-release/main -> main)." >&2
  echo "Has it already been merged, or are there no pending changesets?" >&2
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
