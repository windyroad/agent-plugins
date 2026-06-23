#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
  SYNC_SCRIPT="$REPO_ROOT/scripts/sync-codex-plugin-manifests.mjs"
}

@test "sync-codex-plugin-manifests: script exists and loads" {
  [ -f "$SYNC_SCRIPT" ]
  run node "$SYNC_SCRIPT" --check
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK:"* ]]
}

@test "sync-codex-plugin-manifests: flags divergence in temp workspace" {
  local tmp
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/scripts" "$tmp/packages/fakepkg/.codex-plugin"
  cp "$SYNC_SCRIPT" "$tmp/scripts/sync-codex-plugin-manifests.mjs"
  echo '{"name":"@windyroad/fakepkg","version":"0.9.9"}' > "$tmp/packages/fakepkg/package.json"
  echo '{"name":"wr-fakepkg","version":"0.1.0"}' > "$tmp/packages/fakepkg/.codex-plugin/plugin.json"

  run node "$tmp/scripts/sync-codex-plugin-manifests.mjs" --check
  [ "$status" -ne 0 ]
  [[ "$output" == *"DIVERGED"* ]]

  rm -rf "$tmp"
}

@test "sync-codex-plugin-manifests: sync mode updates temp manifest" {
  local tmp
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/scripts" "$tmp/packages/fakepkg/.codex-plugin"
  cp "$SYNC_SCRIPT" "$tmp/scripts/sync-codex-plugin-manifests.mjs"
  echo '{"name":"@windyroad/fakepkg","version":"0.9.9"}' > "$tmp/packages/fakepkg/package.json"
  echo '{"name":"wr-fakepkg","version":"0.1.0"}' > "$tmp/packages/fakepkg/.codex-plugin/plugin.json"

  run node "$tmp/scripts/sync-codex-plugin-manifests.mjs"
  [ "$status" -eq 0 ]
  run node -e "console.log(require('$tmp/packages/fakepkg/.codex-plugin/plugin.json').version)"
  [ "$status" -eq 0 ]
  [ "$output" = "0.9.9" ]

  rm -rf "$tmp"
}

@test "sync-codex-plugin-manifests: npm scripts are wired" {
  run grep -n "sync:codex-plugin-manifests" "$REPO_ROOT/package.json"
  [ "$status" -eq 0 ]
  run grep -n "check:codex-plugin-manifests" "$REPO_ROOT/package.json"
  [ "$status" -eq 0 ]
}

@test "architect Codex plugin manifest is packaged" {
  run grep -n '".codex-plugin/"' "$REPO_ROOT/packages/architect/package.json"
  [ "$status" -eq 0 ]
  [ -f "$REPO_ROOT/packages/architect/.codex-plugin/plugin.json" ]
}
