#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
  INSTALL_UTILS="$REPO_ROOT/packages/shared/install-utils.mjs"
}

@test "install-utils: runtime flag defaults to Claude and accepts Codex" {
  run grep -n 'runtime: "claude"' "$INSTALL_UTILS"
  [ "$status" -eq 0 ]
  run grep -n 'codex plugin marketplace add' "$INSTALL_UTILS"
  [ "$status" -eq 0 ]
  run grep -n 'codex plugin add' "$INSTALL_UTILS"
  [ "$status" -eq 0 ]
}

@test "architect installer: exposes runtime option and passes it through" {
  local installer="$REPO_ROOT/packages/architect/bin/install.mjs"
  run grep -n -- "--runtime" "$installer"
  [ "$status" -eq 0 ]
  run grep -n "runtime: flags.runtime" "$installer"
  [ "$status" -eq 0 ]
}
