#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
  PACKAGE="$REPO_ROOT/packages/risk-scorer"
}

@test "risk-scorer Codex plugin manifest exists and is packaged" {
  [ -f "$PACKAGE/.codex-plugin/plugin.json" ]
  run grep -n '"name": "wr-risk-scorer"' "$PACKAGE/.codex-plugin/plugin.json"
  [ "$status" -eq 0 ]
  run grep -n '".codex-plugin/"' "$PACKAGE/package.json"
  [ "$status" -eq 0 ]
}

@test "risk-scorer repo-local marketplace entry exists" {
  run grep -n '"name": "wr-risk-scorer"' "$REPO_ROOT/.agents/plugins/marketplace.json"
  [ "$status" -eq 0 ]
  run grep -n '"path": "./packages/risk-scorer"' "$REPO_ROOT/.agents/plugins/marketplace.json"
  [ "$status" -eq 0 ]
}

@test "risk-scorer installer exposes runtime option and passes it through" {
  run grep -n -- "--runtime" "$PACKAGE/bin/install.mjs"
  [ "$status" -eq 0 ]
  run grep -n "runtime: flags.runtime" "$PACKAGE/bin/install.mjs"
  [ "$status" -eq 0 ]
}
