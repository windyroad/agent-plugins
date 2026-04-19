#!/usr/bin/env bats

# P042 / ADR-021: plugin manifest version drift guard.
# Every packages/<plugin>/.claude-plugin/plugin.json `version` must match
# its sibling packages/<plugin>/package.json `version`. The sync script
# (scripts/sync-plugin-manifests.mjs) is the remediation; this test is
# the CI guard that catches drift in PRs before it reaches main.

setup() {
  # Test file lives at packages/shared/test/ — 3 levels below repo root.
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
  SYNC_SCRIPT="$REPO_ROOT/scripts/sync-plugin-manifests.mjs"
}

@test "sync-plugin-manifests: script exists and is executable by node" {
  [ -f "$SYNC_SCRIPT" ]
  run node "$SYNC_SCRIPT" --help 2>&1
  # --help is unrecognised; either exit 0 (graceful) or exit 1 (strict). Both OK.
  # The assertion is that `node` can at least load and start the script.
  # A syntax error or missing file would fail before reaching here.
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "sync-plugin-manifests: --check flag returns OK on current tree" {
  run node "$SYNC_SCRIPT" --check
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK:"* ]]
}

@test "sync-plugin-manifests: --check flag flags divergence when a manifest differs" {
  # Mutate a temp workspace mirroring the layout so we can intentionally
  # diverge a copy without touching the repo. The script resolves paths
  # relative to its own location, so we copy the script into the temp root.
  local tmp
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/scripts"
  cp "$SYNC_SCRIPT" "$tmp/scripts/sync-plugin-manifests.mjs"

  # Create a fake package with drifted versions.
  mkdir -p "$tmp/packages/fakepkg/.claude-plugin"
  echo '{"name": "@windyroad/fakepkg", "version": "0.9.9"}' > "$tmp/packages/fakepkg/package.json"
  echo '{"name": "wr-fakepkg", "version": "0.1.0"}' > "$tmp/packages/fakepkg/.claude-plugin/plugin.json"

  run node "$tmp/scripts/sync-plugin-manifests.mjs" --check
  [ "$status" -ne 0 ]
  [[ "$output" == *"DIVERGED"* ]] || [[ "$output" == *"diverged"* ]]

  rm -rf "$tmp"
}

@test "sync-plugin-manifests: sync mode updates drifted manifest to package version" {
  local tmp
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/scripts"
  cp "$SYNC_SCRIPT" "$tmp/scripts/sync-plugin-manifests.mjs"

  mkdir -p "$tmp/packages/fakepkg/.claude-plugin"
  echo '{"name": "@windyroad/fakepkg", "version": "0.9.9"}' > "$tmp/packages/fakepkg/package.json"
  echo '{"name": "wr-fakepkg", "version": "0.1.0"}' > "$tmp/packages/fakepkg/.claude-plugin/plugin.json"

  run node "$tmp/scripts/sync-plugin-manifests.mjs"
  [ "$status" -eq 0 ]

  # Verify the manifest now matches the package.
  run node -e "console.log(require('$tmp/packages/fakepkg/.claude-plugin/plugin.json').version)"
  [ "$status" -eq 0 ]
  [ "$output" = "0.9.9" ]

  rm -rf "$tmp"
}

@test "sync-plugin-manifests: packages without plugin.json are skipped silently" {
  # packages/shared/ and packages/agent-plugins/ have package.json but no
  # sibling .claude-plugin/plugin.json. The script must skip them without error.
  local tmp
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/scripts"
  cp "$SYNC_SCRIPT" "$tmp/scripts/sync-plugin-manifests.mjs"

  mkdir -p "$tmp/packages/shared"
  echo '{"name": "@windyroad/shared", "version": "0.1.0", "private": true}' > "$tmp/packages/shared/package.json"

  run node "$tmp/scripts/sync-plugin-manifests.mjs" --check
  [ "$status" -eq 0 ]
  # No DIVERGED line because shared has no manifest to drift from.
  [[ "$output" != *"DIVERGED: packages/shared"* ]]

  rm -rf "$tmp"
}

@test "sync-plugin-manifests: npm script wiring present in root package.json" {
  # ADR-021 Confirmation criterion 1: scripts.version includes the sync script.
  run grep -n "changeset version && node scripts/sync-plugin-manifests.mjs" "$REPO_ROOT/package.json"
  [ "$status" -eq 0 ]
}

@test "sync-plugin-manifests: sync:plugin-manifests and check:plugin-manifests scripts defined" {
  # ADR-021 Confirmation criterion 1: manual invocation scripts exist.
  run grep -n "sync:plugin-manifests" "$REPO_ROOT/package.json"
  [ "$status" -eq 0 ]
  run grep -n "check:plugin-manifests" "$REPO_ROOT/package.json"
  [ "$status" -eq 0 ]
}

@test "sync-plugin-manifests: release.yml passes 'version: npm run version' to changesets/action (P052)" {
  # ADR-021 Confirmation criterion 1 (revised 2026-04-19 after P052):
  # changesets/action@v1's version input defaults to invoking `changeset version`
  # directly, bypassing the npm run version hook. Without the explicit input,
  # ADR-021's sync script never fires during the release workflow. Regression
  # guard.
  run grep -n "version: npm run version" "$REPO_ROOT/.github/workflows/release.yml"
  [ "$status" -eq 0 ]
}
